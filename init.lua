vim.opt.spell = true
vim.opt.spelllang = "en"
vim.opt.spelloptions = "camel,noplainbuffer"
vim.opt.spellcapcheck = ""
vim.opt.undofile = true
vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 10
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
vim.opt.cmdheight = 0
vim.opt.foldmethod = "expr"
vim.opt.foldlevel = 99
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.cmd([[set fillchars+=vert:\ ]])

if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
  vim.g.is_windows = true
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
vim.keymap.set("n", "<A-z>", "<Cmd>set wrap!<CR>", { desc = "Toggle line wrap" })
vim.keymap.set("n", "<leader><Tab>", "gt", { desc = "Next tab" })
vim.keymap.set("n", "<leader>`", function()
  vim.cmd.tabnew()
  vim.cmd.term()
  vim.cmd.file("term" .. "-" .. string.format("%x", math.random() * 255))
end, { desc = "Open terminal in new tab" })
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Escape terminal mode" })


vim.filetype.add({
  extension = {
    h = "cpp",
    hpp = "cpp",
    vs = "glsl",
    fs = "glsl",
  }
})


require("config.jumplist")
require("config.project")
require("config.lsp")
-- plugins
require("config.lazy")
require("config.telescope")
require("config.oil")
require("config.neotree")
require("config.lsp_file_operations")
require("config.multicursor")
require("config.treesitter")
require("config.conform")
require("config.autotag")
require("config.cmp")
require("config.gitsigns")
require("config.abolish")
require("config.dap")
require("config.wpm")
require("config.lualine")


--
-- Project Type Based Defaults
--
local function has_root_markers(root_markers)
  local cwd = vim.fn.getcwd()
  for _, marker in ipairs(root_markers) do
    if vim.fn.filereadable(cwd .. "/" .. marker) == 1 then
      return true
    end
  end
  return false
end

local cpp_root_makers   = {
  "CMakeLists.txt",
  ".clangd",
  ".clang-format",
  ".clang-tidy"
}
local js_root_markers   = {
  "package.json",
  "tsconfig.json",
  "jsconfig.json",
  "node_modules",
  "yarn.lock",
  "pnpm-lock.yaml",
  "package-lock.json",
  "bun.lockb",
  ".nvmrc",
}
local java_root_markers = {
  "pom.xml",
  "mvnw",
  "mvnw.cmd",
}
if has_root_markers(cpp_root_makers) then
  vim.cmd("colorscheme vscpp")
elseif has_root_markers(js_root_markers) then
  vim.cmd("colorscheme vscode")
elseif has_root_markers(java_root_markers) then
  vim.cmd("colorscheme jb")
else
  vim.cmd("colorscheme kanagawa-dragon")
end
