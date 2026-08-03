
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.list = true
vim.opt.listchars = {
  space = "·",
  tab = "→ ",
  trail = "•",
  nbsp = "␣",
}

if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
  vim.opt.shell = "bash"
  vim.opt.shellcmdflag = "-c"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
  vim.opt.shellslash = true
end


vim.g.mapleader = " "

vim.keymap.set("n", "<M-j>", ":m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<M-k>", ":m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("v", "<M-j>", ":m '>+1<CR>gv=gv", { desc = "Move block down" })
vim.keymap.set("v", "<M-k>", ":m '<-2<CR>gv=gv", { desc = "Move block up" })
vim.keymap.set('i', '{<CR>', '{<CR>}<Esc>O')
vim.keymap.set('i', '{;<CR>', '{<CR>};<Esc>O')
vim.keymap.set("n", "<Esc>", ":noh<CR>");

-- LSP
vim.lsp.config("clangd", {
  cmd = { "clangd" },
  filetypes = { "c", "cpp", "h", "hpp" },
  root_markers = { '.git', '.clangd' },
})
vim.lsp.enable("clangd")


vim.filetype.add({
  extension = {
    vs = "glsl",
    fs = "glsl",
  }
})


require("config.lazy")
require("config.telescope")
require("config.oil")
require("config.neotree")
require("config.multicursor")
require("config.treesitter")
require("config.conform")
require("config.cmp")


vim.cmd([[colorscheme vscode]])
vim.cmd([[set fillchars+=vert:\ ]])
