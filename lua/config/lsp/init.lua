require("config.lsp.clangd")
require("config.lsp.jdtls")
require("config.lsp.lua")
require("config.lsp.typescript")

vim.keymap.set("n", "<F2>", vim.lsp.buf.rename)
local lsp_code_action = function()
  vim.lsp.buf.code_action({
    filter = function(action) return action.disabled == nil end
  })
end
vim.keymap.set("n", "<leader><space>", lsp_code_action, { desc = "LSP code action" })
vim.keymap.set("v", "<leader><space>", lsp_code_action, { desc = "LSP code action" })

vim.api.nvim_create_user_command("LspLog", function()
  vim.cmd.edit(vim.lsp.get_log_path())
end, {})
