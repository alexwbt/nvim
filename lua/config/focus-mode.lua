local lualine = require("config.lualine")

local function set_hidden(on)
  vim.g.focus_mode = on

  vim.g.lualine_hidden = on
  lualine.apply_state()

  vim.opt.number = not on
  vim.opt.relativenumber = not on

  local ok, gitsigns = pcall(require, "gitsigns")
  if ok then
    gitsigns.toggle_signs(not on)
    gitsigns.toggle_current_line_blame(not on)
  end
end

local function toggle()
  set_hidden(not (vim.g.focus_mode or false))
end

vim.api.nvim_create_user_command("Focus", toggle, { desc = "Toggle focus mode" })
