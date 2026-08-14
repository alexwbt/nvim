return {
  {
    "williamboman/mason.nvim",
    lazy = false,
    config = function()
      require("config.mason")
    end,
  },
}
