local ok_dap, dap = pcall(require, "dap")
if not ok_dap then
  vim.notify("nvim-dap not installed — run :Lazy", vim.log.levels.WARN)
  return
end

local ok_dapui, dapui = pcall(require, "dapui")
if not ok_dapui then
  vim.notify("nvim-dap-ui not installed — run :Lazy", vim.log.levels.WARN)
  return
end

dapui.setup()
local ok_vt = pcall(require, "dap-virtual-text")
if ok_vt then require("dap-virtual-text").setup() end

local widgets = require("dap.ui.widgets")
local sessions_sidebar = widgets.sidebar(widgets.sessions)

vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "ErrorMsg", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "WarningMsg", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "▶", texthl = "Search", linehl = "Search", numhl = "Search" })

vim.keymap.set("n", "<F5>", dap.continue, { desc = "DAP continue" })
vim.keymap.set("n", "<F6>", dap.step_over, { desc = "DAP step over" })
vim.keymap.set("n", "<F7>", dap.step_into, { desc = "DAP step into" })
vim.keymap.set("n", "<F8>", dap.step_out, { desc = "DAP step out" })
vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "DAP toggle breakpoint" })
vim.keymap.set("n", "<F10>", dap.restart, { desc = "DAP restart" })
vim.keymap.set("n", "<S-F5>", dap.terminate, { desc = "DAP terminate" })
vim.keymap.set("n", "<F17>", dap.terminate, { desc = "DAP terminate" })
vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "DAP REPL" })
vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "DAP UI" })
vim.keymap.set("n", "<leader>ds", sessions_sidebar.toggle, { desc = "DAP sessions sidebar" })
vim.api.nvim_create_user_command("ClearBreakpoints", dap.clear_breakpoints, { desc = "DAP clear breakpoints" })

dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end

dap.adapters.gdb = {
  type = "executable",
  command = "gdb",
  args = { "--interpreter=dap" },
}

local gdb_config = setmetatable({}, {
  __call = function()
    local path = vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    if path == "" then return { program = require("dap").ABORT } end
    local dir = vim.fn.fnamemodify(path, ":h")
    local cwd = vim.fn.isdirectory(dir) and dir or vim.fn.getcwd()
    local args = vim.split(vim.fn.input("Arguments: "), " +")
    return {
      name = "Launch (gdb)",
      type = "gdb",
      request = "launch",
      program = path,
      cwd = cwd,
      args = args,
      stopAtBeginningOfMainSubprogram = false,
    }
  end,
})

dap.configurations.c = { gdb_config }
dap.configurations.cpp = dap.configurations.c
