
vim.lsp.config("clangd", {
  cmd = { "clangd" },
  filetypes = { "c", "cpp" },
  root_markers = { '.git', '.clangd' },
})
vim.lsp.enable("clangd")
