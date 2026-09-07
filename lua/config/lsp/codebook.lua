local jit = require("jit")

vim.lsp.config("codebook", {
  cmd = { jit.os == "Windows" and "codebook-lsp.cmd" or "codebook-lsp", "serve" },
  root_markers = { '.git', 'codebook.toml', '.codebook.toml' },
})
vim.lsp.enable("codebook")