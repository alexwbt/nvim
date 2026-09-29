vim.api.nvim_create_user_command("LspLog", function()
  vim.cmd.tabnew(vim.lsp.get_log_path())
end, {})

vim.api.nvim_create_user_command("LspLogClear", function()
  local path = vim.lsp.get_log_path()
  local f = io.open(path, "w")
  if f then
    f:close()
    vim.notify("Cleared LSP log: " .. path, vim.log.levels.INFO)
  else
    vim.notify("Could not open LSP log for writing: " .. path, vim.log.levels.WARN)
  end
end, {})
