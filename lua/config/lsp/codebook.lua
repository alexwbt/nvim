local jit = require("jit")

vim.lsp.config("codebook", {
  cmd = { jit.os == "Windows" and "codebook-lsp.cmd" or "codebook-lsp", "serve" },
  root_markers = { ".git", "codebook.toml", ".codebook.toml" },
  exit_timeout = 2000,
})
vim.lsp.enable("codebook")
