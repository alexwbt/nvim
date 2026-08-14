return {
  {
    "mfussenegger/nvim-jdtls",
    -- jdtls is only required for Java, started lazily on the first Java buffer
    ft = "java",
    -- nvim-jdtls auto-registers the `java` DAP adapter only when nvim-dap is
    -- available; declare the DAP stack as dependencies so the ordering is right.
    dependencies = {
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
      "nvim-lua/plenary.nvim",
    },
  },
}
