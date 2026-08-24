return {
  {
    "brianhuster/live-preview.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "ibhagwan/fzf-lua",
      "folke/snacks.nvim",
    },
    cmd = "LivePreview",
    ft = { "markdown", "html", "asciidoc", "svg" },
    config = function()
      require("config.live-preview")
    end,
  },
}