
local function current_time()
  return os.date("%I:%M:%S %p")
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
