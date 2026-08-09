
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fr", builtin.lsp_references, { desc = "Telescope LSP references" })
vim.keymap.set("n", "<leader>fd", builtin.lsp_definitions, { desc = "Telescope LSP definitions" })
vim.keymap.set("n", "<leader>fi", builtin.lsp_implementations, { desc = "Telescope LSP implementations" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
vim.keymap.set("n", "<leader>fc", builtin.colorscheme)


local telescope = require("telescope")

telescope.setup({
  defaults = {
    file_ignore_patterns = {
      "%.git",
      "%.vs",
      "%.idea",
      "_bin",
      -- "_build",
      -- "_external",
    },
    layout_config = {
      width = 0.99,
      height = 0.99,
      preview_width = 0.4,
    },
    preview = {
      wrap = false,
    },
  },
  pickers = {
    find_files = {
      hidden = true,
    },
    live_grep = {
      hidden = true,
    },
    colorscheme = {
      enable_preview = true,
    },
  },
})

telescope.load_extension("zoxide")
vim.keymap.set("n", "<leader>cd", telescope.extensions.zoxide.list, { desc = "Zoxide" })
