-- mason.nvim: package manager for LSP/DAP/lint/format servers.
-- Used here specifically to install the java-debug-adapter / java-test bundles
-- that nvim-jdtls needs to register the `java` DAP adapter and run JUnit/TestNG
-- tests. Managed jars land under <data>/mason/share/ and are discovered by
-- `find_debug_bundles()` in lua/config/lsp/jdtls.lua.
--
-- LSP servers here are NOT wired via mason-lspconfig — the repo configures LSPs
-- with `vim.lsp.config` + `vim.lsp.enable` (see lua/config/lsp/*.lua), so
-- mason is only a source of tooling binaries.

require("mason").setup({})
