local function current_time()
  return os.date("%H:%M:%S")
end

require("lualine").setup({
  options = {
    theme = "auto",
    refresh = {
      status_line = 1000,
    },
  },
  sections = {
    lualine_z = { current_time },
    lualine_y = { "location", "lsp_status" },
  }
})
