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

vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "ErrorMsg", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "WarningMsg", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "▶", texthl = "Search", linehl = "Search", numhl = "Search" })

vim.keymap.set("n", "<F5>", dap.continue, { desc = "DAP continue" })
vim.keymap.set("n", "<F6>", dap.step_over, { desc = "DAP step over" })
vim.keymap.set("n", "<F7>", dap.step_into, { desc = "DAP step into" })
vim.keymap.set("n", "<F8>", dap.step_out, { desc = "DAP step out" })
vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "DAP toggle breakpoint" })
vim.keymap.set("n", "<F10>", dap.list_breakpoints, { desc = "DAP list breakpoints" })
vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "DAP REPL" })
vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "DAP UI" })

dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end
dap.listeners.before.event_terminated["dapui"] = function() dapui.close() end
dap.listeners.before.event_exited["dapui"] = function() dapui.close() end

dap.adapters.gdb = {
  type = "executable",
  command = "gdb",
  args = { "--interpreter=dap" },
}

dap.configurations.c = {
  {
    name = "Launch (gdb)",
    type = "gdb",
    request = "launch",
    program = function()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopAtBeginningOfMainSubprogram = false,
  },
}

dap.configurations.cpp = dap.configurations.c