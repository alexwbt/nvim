return {
  {
    "nvim-pack/nvim-spectre",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Spectre",
    keys = {
      { "<leader>sr", "<cmd>Spectre<cr>", desc = "Spectre (search & replace)" },
    },
    opts = {
      open_cmd = "tabnew",
    },
  },
}