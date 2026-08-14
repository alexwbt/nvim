local ts = require("nvim-treesitter")

ts.install({
  "c", "cpp", "lua", "javascript", "typescript", "tsx",
  "json", "jsonc", "html", "css", "scss", "yaml",
  "markdown", "markdown_inline", "bash", "vim", "vimdoc",
  "regex", "glsl",
})

vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})
