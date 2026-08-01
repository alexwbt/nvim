
vim.keymap.set("n", "<leader>e", "<Cmd>Neotree<CR>")

local neotree = require("neo-tree")

neotree.setup({
  window = {
    mappings = {
      ["Z"] = "expand_all_nodes",
      ["W"] = "close_all_nodes",
    }
  }
})

