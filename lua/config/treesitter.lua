local ts = require("nvim-treesitter")

ts.install({
  "bash",
  "c",
  "cpp",
  "css",
  "glsl",
  "html",
  "java",
  "javascript",
  "json",
  "jsx",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "regex",
  "rust",
  "scss",
  "styled",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
})

vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})
