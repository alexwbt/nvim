
vim.keymap.set("n", "<leader>e", "<Cmd>Neotree toggle<CR>")

local neotree = require("neo-tree")

neotree.setup({
  filesystem = {
    bind_to_cwd = false,
    follow_current_file = {
      enabled = true,
      leave_dirs_open = false,
    },
    filtered_items = {
      visible = true,
    }
  }
})

