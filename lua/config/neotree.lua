
vim.keymap.set("n", "<leader>e", "<Cmd>Neotree<CR>")

local neotree = require("neo-tree")

neotree.setup({
  filesystem = {
    filtered_items = {
      visible = true,
    }
  }
})

