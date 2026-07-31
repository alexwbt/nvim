
vim.keymap.set("n", "<C-b>", "<cmd>Neotree toggle<cr>")

local neotree = require("neo-tree")

neotree.setup({
  window = {
    mappings = {
      ["Z"] = "expand_all_nodes",
      ["W"] = "close_all_nodes",
    }
  }
})

