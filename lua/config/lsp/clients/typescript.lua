local jit = require("jit")

vim.lsp.config("ts_ls", {
  cmd = { jit.os == "Windows" and "typescript-language-server.cmd" or "typescript-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
})
vim.lsp.enable("ts_ls")
