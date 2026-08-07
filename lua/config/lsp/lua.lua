
vim.lsp.config("lua_ls", {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.git', '.luarc.json' },
  settings = {
    Lua = {
      diagnostics = { globals = { 'vim' } }
    }
  }
})
vim.lsp.enable("lua_ls")
