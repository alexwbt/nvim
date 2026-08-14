require("lualine").setup({
  options = {
    theme = "auto",
  },
  sections = {
    lualine_y = { "progress", "lsp_status" },
  },
})