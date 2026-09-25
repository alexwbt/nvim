require("config.lsp.clangd")
require("config.lsp.codebook")
require("config.lsp.jdtls")
require("config.lsp.lua")
require("config.lsp.typescript")

vim.keymap.set("n", "<F2>", vim.lsp.buf.rename)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
local lsp_code_action = function()
  vim.lsp.buf.code_action({
    filter = function(action) return action.disabled == nil end
  })
end
vim.keymap.set("n", "<leader><space>", lsp_code_action, { desc = "LSP code action" })
vim.keymap.set("v", "<leader><space>", lsp_code_action, { desc = "LSP code action" })

local function hierarchy_entry(bufnr, client, item, label)
  local col = vim.lsp.util._get_line_byte_from_position(bufnr, item.range.start, client.offset_encoding) or 0
  local text = (item.detail and #item.detail > 0) and (item.name .. " " .. item.detail) or item.name
  if label then
    text = string.format("[%s] %s", label, text)
  end
  return {
    filename = vim.uri_to_fname(item.uri),
    lnum = item.range.start.line + 1,
    col = col + 1,
    text = text,
  }
end

local function open_type_hierarchy_picker(entries)
  if #entries == 0 then
    vim.notify("No type hierarchy items", vim.log.levels.WARN)
    return
  end
  table.sort(entries, function(a, b)
    return a.text < b.text
  end)
  local config = require("telescope.config").values
  require("telescope.pickers").new({}, {
    prompt_title = "LSP type hierarchy",
    finder = require("telescope.finders").new_table({
      results = entries,
      entry_maker = require("telescope.make_entry").gen_from_quickfix({}),
    }),
    sorter = config.generic_sorter({}),
    previewer = config.qflist_previewer({}),
  }):find()
end

local function type_hierarchy()
  local bufnr = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  if not next(vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/prepareTypeHierarchy" })) then
    vim.notify("Type hierarchy is not supported by any server", vim.log.levels.WARN)
    return
  end

  local entries = {}
  local pending = 0
  local opened = false

  local function maybe_open()
    if pending == 0 and not opened then
      opened = true
      vim.schedule(function()
        open_type_hierarchy_picker(entries)
      end)
    end
  end

  vim.lsp.buf_request_all(bufnr, "textDocument/prepareTypeHierarchy", function(client)
    return vim.lsp.util.make_position_params(win, client.offset_encoding)
  end, function(req_results)
    for client_id, res in pairs(req_results) do
      if not res.err and res.result then
        local client = vim.lsp.get_client_by_id(client_id)
        for _, item in ipairs(res.result) do
          for _, dir in ipairs({ "subtypes", "supertypes" }) do
            local method = dir == "subtypes" and "typeHierarchy/subtypes" or "typeHierarchy/supertypes"
            local label = dir == "subtypes" and "sub" or "super"
            pending = pending + 1
            client:request(method, { item = item }, function(_, result)
              if result then
                for _, r in ipairs(result) do
                  entries[#entries + 1] = hierarchy_entry(bufnr, client, r, label)
                end
              end
              pending = pending - 1
              maybe_open()
            end, bufnr)
          end
        end
      end
    end
    maybe_open()
  end)
end
vim.keymap.set("n", "<leader>ft", type_hierarchy, { desc = "LSP type hierarchy (sub + super)" })

vim.api.nvim_create_user_command("LspLog", function()
  vim.cmd.tabnew(vim.lsp.get_log_path())
end, {})

vim.api.nvim_create_user_command("LspLogClear", function()
  local path = vim.lsp.get_log_path()
  local f = io.open(path, "w")
  if f then
    f:close()
    vim.notify("Cleared LSP log: " .. path, vim.log.levels.INFO)
  else
    vim.notify("Could not open LSP log for writing: " .. path, vim.log.levels.WARN)
  end
end, {})

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

  local function get_proc(client)
    local cmd = get_bin(client)
    -- Base search term: basename without a launcher extension (.cmd/.bat)
    local term = cmd:match("([^/\\]+)$"):gsub("%.cmd$", ""):gsub("%.bat$", "")
    local res = { pid = "?", mem = "?" }
    local matched = false

    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
      -- wmic is deprecated/absent on newer Windows (its CSV formatter can also
      -- emit "Invalid XML content" for queries that include CommandLine), so
      -- use PowerShell's Get-CimInstance instead. Output is tab-delimited
      -- (pid\tname\twss\tcmdline); tab is replaced with a space inside
      -- cmdline to keep it a single field.
      local out = vim.fn.systemlist({
        "powershell", "-NoProfile", "-Command",
        'Get-CimInstance Win32_Process -Property Name,ProcessId,WorkingSetSize,CommandLine | ForEach-Object { "{0}`t{1}`t{2}`t{3}" -f $_.ProcessId,$_.Name,$_.WorkingSetSize,($_.CommandLine -replace "`t"," ") }',
      })
      local pid, wss, exact = nil, 0, nil
      local function is_wrapper(name)
        local n = vim.fn.fnamemodify(name, ":t"):lower()
        return n == "cmd.exe" or n == "sh.exe" or n == "shell.exe"
      end
      for _, line in ipairs(out) do
        local parts = vim.split(line, "\t", { plain = true })
        -- parts: [1]=pid [2]=name [3]=wss [4]=cmdline (may be empty/absent)
        local pv = parts[1]
        local name = parts[2]
        local wssv = tonumber(parts[3])
        local cmdline = parts[4] or ""
        if pv and name and wssv then
          local name_match = vim.fn.fnamemodify(name, ":t"):lower() == term:lower()
          local cmd_match = cmdline:lower():find(term:lower(), 1, true) ~= nil
          -- Skip the launcher wrapper (cmd.exe/sh.exe) so we get the real server pid.
          if (name_match or cmd_match) and not is_wrapper(name) then
            if name_match and exact == nil then
              exact = pv
            end
            pid = pid or pv
            wss = math.max(wss, wssv)
          end
        end
      end
      if pid then
        matched = true
        res.pid = exact or pid
        res.mem = fmt_mem(wss)
      end
    else
      -- Prefer largest-RSS matching process so pid and mem describe the same one.
      local best_pid, best_rss
      for _, l in ipairs(vim.fn.systemlist("ps -eo pid=,comm=,rss=")) do
        local pid, comm, rss = l:match("^%s*(%d+)%s+(.+)%s+(%d+)%s*$")
        if comm and vim.fn.fnamemodify(comm, ":t"):lower() == term:lower() then
          local rssv = tonumber(rss)
          if not best_rss or rssv > best_rss then
            best_pid, best_rss = pid, rssv
          end
        end
      end
      if best_pid then
        matched = true
        res.pid = best_pid
        res.mem = fmt_mem(best_rss * 1024)
      end
    end

    return res, matched
  end

  local clients = vim.lsp.get_clients()
  local rows = {}
  for _, client in ipairs(clients) do
    local p = get_proc(client)
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
