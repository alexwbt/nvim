
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.list = true
vim.opt.listchars = {
  space = '·',
  tab = '→ ',
  trail = '•',
  nbsp = '␣'
}

if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
  vim.opt.shell = "bash"
  vim.opt.shellcmdflag = "-c"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
  vim.opt.shellslash = true
end


vim.g.mapleader = " "


require("config.lazy")
require("config.telescope")


vim.cmd([[colorscheme codedark]])

