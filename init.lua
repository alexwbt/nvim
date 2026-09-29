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

vim.g.mapleader = " "

vim.keymap.set("n", "<C-k>", "10k")
vim.keymap.set("n", "<C-j>", "10j")
vim.keymap.set("v", "<C-k>", "10k")
vim.keymap.set("v", "<C-j>", "10j")
vim.keymap.set("i", "{<CR>", "{<CR>}<Esc>O")
vim.keymap.set("i", "{;<CR>", "{<CR>};<Esc>O")
vim.keymap.set("n", "<Esc>", ":noh<CR>")
vim.keymap.set("v", "<Tab>", ">gv")
vim.keymap.set("v", "<S-Tab>", "<gv")
vim.keymap.set("v", "<C-c>", "\"+y")
vim.keymap.set("n", "<A-z>", "<Cmd>set wrap!<CR>", { desc = "Toggle line wrap" })
vim.keymap.set("n", "<leader>rn", ":set rnu!<CR>", { desc = "Toggle relative line numbers" })
vim.keymap.set("n", "<leader><Tab>", "gt", { desc = "Next tab" })
vim.keymap.set("n", "{", "}")
vim.keymap.set("n", "}", "{")
vim.keymap.set("v", "{", "}")
vim.keymap.set("v", "}", "{")

vim.keymap.set("n", "<leader>`", function()
  vim.cmd.tabnew()
  vim.cmd.term()
  vim.cmd.file("term" .. "-" .. string.format("%x", math.random() * 255))
end, { desc = "Open terminal in new tab" })

vim.keymap.set("n", "<leader>bd", function()
  local visible_buffers = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    visible_buffers[buf] = true
  end
  local loaded_buffers = vim.api.nvim_list_bufs()
  local deleted_count = 0
  for _, buf in ipairs(loaded_buffers) do
    if vim.api.nvim_buf_is_loaded(buf) and not visible_buffers[buf] then
      local success, _ = pcall(vim.api.nvim_buf_delete, buf, { force = false })
      if success then
        deleted_count = deleted_count + 1
      end
    end
  end
  vim.notify(string.format("Deleted %d hidden buffer(s)", deleted_count))
end, { desc = "Close all invisible buffers" })

vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Escape terminal mode" })


vim.filetype.add({
  extension = {
    h = "cpp",
    hpp = "cpp",
    vs = "glsl",
    fs = "glsl",
  }
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  command = "wincmd T",
})


local project = require("config.project-local")
require("config.jumplist")
require("config.lsp")
require("config.prune")
require("config.windows")

-- plugins
require("config.lazy")
require("config.abolish")
require("config.autotag")
require("config.cmp")
require("config.conform")
require("config.dap")
require("config.diffview")
require("config.fidget")
require("config.fzf-lua")
require("config.gitsigns")
require("config.lsp-file-operations")
require("config.lualine")
require("config.minuet")
require("config.multicursor")
require("config.neotree")
require("config.oil")
require("config.spectre")
require("config.telescope")
require("config.treesitter")
require("config.wpm")

project.set_project_colorscheme()
