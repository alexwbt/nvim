return {
  {
    "williamboman/mason.nvim",
    lazy = false,
    config = function()
      require("config.mason")
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    lazy = false,
    config = function()
      require("config.mason-tool-installer")
    end,
  },
}
