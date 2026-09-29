require("config.lsp.clients.clangd")
require("config.lsp.clients.codebook")
require("config.lsp.clients.jdtls")
require("config.lsp.clients.lemminx")
require("config.lsp.clients.lua")
require("config.lsp.clients.rust")
require("config.lsp.clients.typescript")

require("config.lsp.info")
require("config.lsp.log")
require("config.lsp.prune")
require("config.lsp.typehierarchy")

local lsp_code_action = function()
  vim.lsp.buf.code_action({
    filter = function(action) return action.disabled == nil end
  })
end
vim.keymap.set("n", "<leader><space>", lsp_code_action, { desc = "LSP code action" })
vim.keymap.set("v", "<leader><space>", lsp_code_action, { desc = "LSP code action" })
vim.keymap.set("n", "<F2>", vim.lsp.buf.rename)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
