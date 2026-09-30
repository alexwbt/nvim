return {
  {
    "mofiqul/vscode.nvim",
    opts = {
      group_overrides = {
        ["SpecialChar"] = { link = "Special" },
        ["@attribute"] = { fg = "#4EC9B0" },
        ["@annotation"] = { fg = "#4EC9B0" },
        ["@type.builtin"] = { fg = "#4EC9B0" },
        ["@tag.class.css"] = { fg = "#D7BA7D" },
        ["@lsp.type.class.css"] = { fg = "#D7BA7D" },
        ["cssClassName"] = { fg = "#D7BA7D" },
        ["cssClassNameDot"] = { fg = "#D7BA7D" },
        ["@type.css"] = { fg = "#D7BA7D" },
        ["@type.styled"] = { fg = "#D7BA7D" },
        ["@type.builtin.java"] = { link = "@keyword" },
        ["@keyword.import.java"] = { link = "@keyword" },
        ["@keyword.exception.java"] = { link = "@keyword" },
        ["@keyword.conditional.ternary.java"] = { link = "@lsp" },
        ["SnacksDashboardDesc"] = { fg = "#4DAAFC" },
        ["SnacksDashboardIcon"] = { fg = "#4DAAFC" },
        ["SnacksDashboardFile"] = { fg = "#DDDDDD" },
        ["SnacksDashboardKey"] = { fg = "#DDDDDD" },
        ["SnacksDashboardHeader"] = { fg = "#DDDDDD" },
        ["NeoTreeIndentMarker"] = { fg = "#333333" },
      }
    }
  },
  {
    "pmouraguedes/neodarcula.nvim",
    opts = {
      transparent = true,
      dim = true,
    }
  },
  {
    "neanias/everforest-nvim",
    config = function()
      require("everforest").setup({
        background = "hard",
        ui_contrast = "high",
      })
    end
  },
  { "folke/tokyonight.nvim" },
  { "loctvl842/monokai-pro.nvim" },
  { "morhetz/gruvbox" },
  { "nickkadutskyi/jb.nvim" },
  { "olimorris/onedarkpro.nvim" },
  { "projekt0n/github-nvim-theme" },
  { "rebelot/kanagawa.nvim" },
}
