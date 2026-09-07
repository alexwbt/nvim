
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

local function lsp_clients()
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if client.name ~= "codebook" then
      table.insert(names, client.name)
    end
  end
  if #names == 0 then
    return ""
  end
  return table.concat(names, ", ")
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
    lualine_y = { "location", lsp_clients },
    lualine_z = { current_time },
  },
})
