vim.api.nvim_create_user_command("LspInfo", function()
  local function get_bin(client)
    local cmd = client.config and client.config.cmd
    local bin = type(cmd) == "table" and cmd[1] or nil
    return bin or client.name
  end

  local total_mem_bytes = nil
  local function get_total_mem()
    if total_mem_bytes then
      return total_mem_bytes
    end
    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
      -- wmic is deprecated/absent on newer Windows; use PowerShell CIM instead.
      local out = vim.fn.systemlist({
        "powershell", "-NoProfile", "-Command",
        "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory)",
      })
      total_mem_bytes = tonumber((out[1] or ""):match("%d+")) or 0
    elseif vim.fn.has("mac") == 1 then
      total_mem_bytes = tonumber((vim.fn.systemlist("sysctl -n hw.memsize")[1] or ""):match("%d+")) or 0
    else
      local line = vim.fn.systemlist("grep MemTotal /proc/meminfo")[1] or ""
      total_mem_bytes = (tonumber((line:match("MemTotal:%s*(%d+)")) or 0) or 0) * 1024
    end
    return total_mem_bytes or 0
  end

  local function fmt_mem(wss_bytes)
    local total = get_total_mem()
    if total > 0 and wss_bytes > 0 then
      return string.format("%.1f MB (%.1f%%)", wss_bytes / 1024 / 1024, wss_bytes / total * 100)
    end
    return string.format("%.1f MB", wss_bytes / 1024 / 1024)
  end

  local is_win = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

  local function is_wrapper(name)
    local n = vim.fn.fnamemodify(name, ":t"):lower()
    return n == "cmd.exe" or n == "sh.exe" or n == "shell.exe"
  end

  -- Signature for a client: the cmd args after the binary. Unique per instance
  -- for servers that embed their workspace (e.g. jdtls's `-data <hash>`), which
  -- is what lets us tell two same-named servers on different roots apart.
  local function client_sig(client)
    local cmd = client.config and client.config.cmd
    if type(cmd) == "table" and #cmd > 1 then
      local a = {}
      for i = 2, #cmd do
        a[#a + 1] = cmd[i]
      end
      return table.concat(a, " ")
    end
    return ""
  end

  -- Fetch the OS process table once (pid, name, wss, cmdline).
  local proc_cache = nil
  local function get_procs()
    if proc_cache then
      return proc_cache
    end
    local list = {}
    if is_win then
      -- wmic is deprecated/absent on newer Windows (its CSV formatter can also
      -- emit "Invalid XML content" for queries that include CommandLine), so
      -- use PowerShell's Get-CimInstance instead. Output is tab-delimited
      -- (pid\tname\twss\tcmdline); tab is replaced with a space inside
      -- cmdline to keep it a single field.
      local out = vim.fn.systemlist({
        "powershell", "-NoProfile", "-Command",
        'Get-CimInstance Win32_Process -Property Name,ProcessId,WorkingSetSize,CommandLine | ForEach-Object { "{0}`t{1}`t{2}`t{3}" -f $_.ProcessId,$_.Name,$_.WorkingSetSize,($_.CommandLine -replace "`t"," ") }',
      })
      for _, line in ipairs(out) do
        local parts = vim.split(line, "\t", { plain = true })
        local pv, name, wssv = parts[1], parts[2], tonumber(parts[3])
        if pv and name and wssv then
          list[#list + 1] = { pid = pv, name = name, wss = wssv, cmdline = parts[4] or "" }
        end
      end
    else
      -- args last so spaces inside it don't break the fixed leading fields.
      for _, l in ipairs(vim.fn.systemlist("ps -eo pid=,comm=,rss=,args=")) do
        local pid, comm, rss, args = l:match("^%s*(%d+)%s+(%S+)%s+(%d+)%s*(.*)$")
        if pid and comm and rss then
          list[#list + 1] = { pid = pid, name = comm, wss = tonumber(rss) * 1024, cmdline = args or "" }
        end
      end
    end
    proc_cache = list
    return list
  end

  local function get_proc(client, used)
    local cmd = get_bin(client)
    -- Base search term: basename without a launcher extension (.cmd/.bat)
    local term = cmd:match("([^/\\]+)$"):gsub("%.cmd$", ""):gsub("%.bat$", ""):lower()
    local sig = client_sig(client):lower():gsub("\\", "/")

    local best, best_score
    for _, p in ipairs(get_procs()) do
      -- Skip processes already claimed by another client so two instances of the
      -- same server get distinct pids instead of both reporting the first match.
      if not used[p.pid] and not is_wrapper(p.name) then
        local name_match = vim.fn.fnamemodify(p.name, ":t"):lower() == term
        -- Normalize separators so a client cmd's `/` matches the OS cmdline's `\`.
        local cmdline = p.cmdline:lower():gsub("\\", "/")
        local cmd_match = cmdline:find(term, 1, true) ~= nil
        if name_match or cmd_match then
          local score = 0
          if name_match then score = score + 1 end
          -- Prefer the process whose cmdline carries this client's unique args.
          if sig ~= "" and cmdline:find(sig, 1, true) then score = score + 2 end
          if not best or score > best_score or (score == best_score and p.wss > best.wss) then
            best, best_score = p, score
          end
        end
      end
    end

    if best then
      used[best.pid] = true
      return { pid = best.pid, mem = fmt_mem(best.wss) }, true
    end
    return { pid = "?", mem = "?" }, false
  end

  local clients = vim.lsp.get_clients()
  -- Most-specific clients first (those with distinguishing args) so a generic
  -- same-name client can't claim a process a specific one needs.
  table.sort(clients, function(a, b)
    return #client_sig(a) > #client_sig(b)
  end)
  local used = {}
  local rows = {}
  for _, client in ipairs(clients) do
    local p = get_proc(client, used)
    table.insert(rows, {
      client.name,
      p.pid,
      p.mem,
      tostring(#vim.tbl_keys(client.attached_buffers)),
      client.root_dir or "None",
    })
  end

  local headers = { "Client", "PID", "Memory", "Buffers", "Root" }
  local widths = {}
  for i, h in ipairs(headers) do
    widths[i] = #h
  end
  for _, row in ipairs(rows) do
    for i, cell in ipairs(row) do
      widths[i] = math.max(widths[i], #cell)
    end
  end

  local sep = {}
  for i = 1, #headers do
    sep[i] = string.rep("-", widths[i])
  end
  local fmt_row = function(cells)
    local parts = {}
    for i, cell in ipairs(cells) do
      parts[i] = string.format("%-" .. widths[i] .. "s", cell)
    end
    return table.concat(parts, "  ")
  end

  local lines = {
    fmt_row(sep),
    fmt_row(headers),
    fmt_row(sep),
  }
  for _, row in ipairs(rows) do
    table.insert(lines, fmt_row(row))
  end

  vim.cmd("bot new")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  vim.api.nvim_win_set_height(0, math.min(#lines, math.floor(vim.o.lines / 2)))
end, {})
