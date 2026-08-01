
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
-- vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
-- vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })


local telescope = require("telescope")

telescope.setup({
  defaults = {
    file_ignore_patterns = {
      "%.git",
      "%.vs",
      "%.idea",
      "_build",
      "_bin",
      "_external",
    },
  }
})

telescope.load_extension("zoxide")
vim.keymap.set("n", "<leader>cd", telescope.extensions.zoxide.list, { desc = "Zoxide" })
