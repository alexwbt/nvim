return {
  { "mofiqul/vscode.nvim" },
  { "olimorris/onedarkpro.nvim" },
  {
    "sainnhe/everforest",
    init = function()
      vim.g.everforest_background = "hard"
      vim.g.everforest_better_performance = 1
      vim.g.everforest_enable_diagnostic = 1
      vim.g.everforest_transparent_background = 0
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "everforest",
        callback = function()
          vim.api.nvim_set_hl(0, "Normal", { bg = "#1c1c1c" })
          vim.api.nvim_set_hl(0, "NormalNC", { bg = "#1c1c1c" })
        end,
      })
    end,
  },
  { "projekt0n/github-nvim-theme" },
  { "rebelot/kanagawa.nvim" },
  { "morhetz/gruvbox" },
  { "folke/tokyonight.nvim" },
  { "loctvl842/monokai-pro.nvim" },
}
