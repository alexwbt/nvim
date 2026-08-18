require("config.lsp.clangd")
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
      local line = vim.fn.systemlist({
        "wmic", "ComputerSystem", "get", "TotalPhysicalMemory", "/format:csv",
      })[3] or ""
      total_mem_bytes = tonumber((line:match(",([%d]+)"))) or 0
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
      -- wmic /format:csv output is alphabetized: Node,CommandLine,Name,
      -- ProcessId,WorkingSetSize. CommandLine may contain commas (and is
      -- inconsistently quoted), so parse from the trailing end where Name,
      -- ProcessId, WorkingSetSize are always clean, comma-free tokens.
      local out = vim.fn.systemlist({
        "wmic", "process", "get",
        "ProcessId,Name,WorkingSetSize,CommandLine",
        "/format:csv",
      })
      local pid, wss, exact = nil, 0, nil
      local function is_wrapper(name)
        local n = vim.fn.fnamemodify(name, ":t"):lower()
        return n == "cmd.exe" or n == "sh.exe" or n == "shell.exe"
      end
      local function csv_fields(line)
        return vim.split(line, ",", { plain = true })
      end
      for _, line in ipairs(out) do
        local parts = csv_fields(line)
        local wssv = tonumber(parts[#parts])
        local pv = parts[#parts - 1]
        local name = parts[#parts - 2]
        local cmdline = table.concat(parts, ",", 2, #parts - 2)
        if name and pv and wssv then
          local name_match = vim.fn.fnamemodify(name, ":t"):lower() == term:lower()
          local cmd_match = cmdline and cmdline:lower():find(term:lower(), 1, true) ~= nil
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
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end, {})
