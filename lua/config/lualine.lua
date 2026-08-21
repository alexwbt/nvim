
local function current_time()
  return os.date("%I:%M:%S %p")
end

local wpm = require("local.wpm")
local function wpm_segment()
  local cur = wpm.wpm()
  if cur <= 0 then
    return ""
  end
  return string.format("%d wpm", cur)
end

require("lualine").setup({
  options = {
    theme = "auto",
    refresh = {
      status_line = 1000,
    },
  },
  sections = {
    lualine_x = { "encoding", "fileformat", "filetype", wpm_segment },
    lualine_y = { "location", "lsp_status" },
    lualine_z = { current_time },
  },
})
