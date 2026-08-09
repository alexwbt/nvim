
return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "c", "cpp", "lua", "javascript", "typescript", "tsx",
        "json", "jsonc", "html", "css", "scss", "yaml",
        "markdown", "markdown_inline", "bash", "vim", "vimdoc",
        "regex", "glsl",
      },
    },
  }
}
