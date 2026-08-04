
vim.opt.wrap = false
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

vim.keymap.set("n", "<C-k>", "10k");
vim.keymap.set("n", "<C-j>", "10j");
vim.keymap.set("v", "<C-k>", "10k");
vim.keymap.set("v", "<C-j>", "10j");
vim.keymap.set("n", "<M-j>", ":m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<M-k>", ":m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("v", "<M-j>", ":m '>+1<CR>gv=gv", { desc = "Move block down" })
vim.keymap.set("v", "<M-k>", ":m '<-2<CR>gv=gv", { desc = "Move block up" })
vim.keymap.set('i', '{<CR>', '{<CR>}<Esc>O')
vim.keymap.set('i', '{;<CR>', '{<CR>};<Esc>O')
vim.keymap.set("n", "<Esc>", ":noh<CR>");


vim.filetype.add({
  extension = {
    h = "cpp",
    hpp = "cpp",
    vs = "glsl",
    fs = "glsl",
  }
})


-- LSP
vim.lsp.config("clangd", {
  cmd = { "clangd" },
  filetypes = { "c", "cpp" },
  root_markers = { '.git', '.clangd' },
})
vim.lsp.enable("clangd")

vim.lsp.config("ts_ls", {
  cmd = { jit.os == "Windows" and "typescript-language-server.cmd" or "typescript-language-server", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
})
vim.lsp.enable("ts_ls")

vim.lsp.config("jdtls", {
  cmd = { "jdtls" },
  filetypes = { "java" },
  root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" },
})
vim.lsp.enable("jdtls")


require("config.lazy")
require("config.telescope")
require("config.oil")
require("config.neotree")
require("config.multicursor")
require("config.treesitter")
require("config.conform")
require("config.cmp")


vim.cmd([[colorscheme kanagawa-dragon]])
vim.cmd([[set fillchars+=vert:\ ]])
