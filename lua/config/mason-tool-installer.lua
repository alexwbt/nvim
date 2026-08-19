-- mason-tool-installer.nvim: auto-installs/updates the tooling binaries listed
-- below on startup. mason.nvim's own setup() does NOT honor `ensure_installed`
-- (that's a mason-lspconfig / mason-null-ls / mason-tool-installer concept), so
-- without this the packages listed in config/mason.lua's `ensure_installed`
-- were silently never installed.
--
-- The LSP servers here are sources of tooling binaries only — the actual LSP
-- wiring uses vim.lsp.config + vim.lsp.enable (see lua/config/lsp/*.lua), NOT
-- mason-lspconfig. So this plugin only ensures binaries are on disk under
-- <data>/mason/bin/ (prepended to PATH for nvim-spawned jobs only).

require("mason-tool-installer").setup({
  ensure_installed = {
    "java-debug-adapter",
    "java-test",
    "clangd",
    "lua-language-server",
    "typescript-language-server",
    "prettier",
    "shfmt",
  },
  auto_update = false,
  run_on_start = true,
  start_delay = 3000,
})