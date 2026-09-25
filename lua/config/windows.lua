if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
  vim.g.is_windows = true
  vim.opt.shell = "bash"
  vim.opt.shellcmdflag = "-c"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
  vim.opt.shellslash = true

  -- Upstream gx/vim.ui.open bug: win32 hardcodes cmd.exe, but with 'shellslash'
  -- exepath() yields a forward-slash path uv.spawn can't launch.
  -- https://github.com/neovim/neovim/issues/39524
  vim.ui.open = function(uri)
    return vim.system(
      { "rundll32", "url.dll,FileProtocolHandler", uri },
      { detach = true }
    )
  end
  vim.g.netrw_browsex_viewer = "rundll32 url.dll,FileProtocolHandler"
end
