vim.opt.spell = true
vim.opt.spelllang = "en"
vim.opt.spelloptions = "camel,noplainbuffer"
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
vim.keymap.set("n", "<Esc>", ":noh<CR>")
vim.keymap.set("v", "<Tab>", ">gv")
vim.keymap.set("v", "<S-Tab>", "<gv")


vim.filetype.add({
  extension = {
    h = "cpp",
    hpp = "cpp",
    vs = "glsl",
    fs = "glsl",
  }
})


require("config.lazy")
require("config.telescope")
require("config.oil")
require("config.neotree")
require("config.lsp_file_operations")
require("config.multicursor")
require("config.treesitter")
require("config.conform")
require("config.cmp")
require("config.gitsigns")
require("config.abolish")
require("config.dap")
require("config.spell")


--
-- LSP
--

require("config.lsp.clangd")
require("config.lsp.jdtls")
require("config.lsp.lua")
require("config.lsp.typescript")
vim.keymap.set("n", "<F2>", vim.lsp.buf.rename)
vim.api.nvim_create_user_command("LspLog", function() vim.cmd.edit(vim.lsp.get_log_path()) end, {})


vim.cmd([[colorscheme kanagawa-dragon]])
vim.cmd([[set fillchars+=vert:\ ]])


--
-- Project Type Based Defaults
--

local function has_cpp_root()
  local cwd = vim.fn.getcwd()
  for _, marker in ipairs({ "CMakeLists.txt", ".clangd", ".clang-format", ".clang-tidy" }) do
    if vim.fn.filereadable(cwd .. "/" .. marker) == 1 then
      return true
    end
  end
  return false
end

local function has_js_root()
  local cwd = vim.fn.getcwd()
  for _, marker in ipairs({ "package.json", "tsconfig.json", "jsconfig.json", "node_modules", "yarn.lock", "pnpm-lock.yaml", "package-lock.json", "bun.lockb", ".nvmrc" }) do
    if vim.fn.filereadable(cwd .. "/" .. marker) == 1 or vim.fn.isdirectory(cwd .. "/" .. marker) == 1 then
      return true
    end
  end
  return false
end

if has_cpp_root() then
  vim.cmd("colorscheme vscpp")
elseif has_js_root() then
  vim.cmd("colorscheme vscode")
end
