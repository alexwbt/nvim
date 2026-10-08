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
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  for _, client in ipairs(clients) do
    if client.name ~= "codebook" or #clients == 1 then
      table.insert(names, client.name)
    end
  end
  if #names == 0 then
    return ""
  end
  return table.concat(names, ", ")
end

local function macro_recording()
  local reg = vim.fn.reg_recording()
  if reg == "" then return "" end
  return "Recording @" .. reg
end

require("lualine").setup({
  options = {
    theme = "auto",
    refresh = {
      status_line = 1000,
    },
  },
  sections = {
    lualine_c = { macro_recording, { "filename", path = 1 } },
    lualine_x = { "encoding", "fileformat", "filetype", wpm_segment },
    lualine_y = { "location", lsp_clients },
    lualine_z = { current_time },
  },
})

local function apply_state()
  if vim.g.lualine_hidden then
    vim.opt.laststatus = 0
  else
    vim.opt.laststatus = 2
    require("lualine").refresh()
  end
end

return { apply_state = apply_state }
