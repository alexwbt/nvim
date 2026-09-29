local function prune_lsp_clients()
  local cwd = vim.fn.getcwd()
  for _, client in ipairs(vim.lsp.get_clients()) do
    local root = client.config.root_dir
    if root then
      root = vim.fn.fnamemodify(root, ":p"):gsub("[/\\]$", "")
      local inside_root = string.find(cwd, root, 1, true) == 1
      local root_inside = string.find(root, cwd, 1, true) == 1
      if not inside_root and not root_inside then
        client.stop()
      end
    end
  end
end

local function prune_buffers()
  local cwd = vim.fn.getcwd()
  for _, buffer_number in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buffer_number) then
      local buffer_name = vim.fn.bufname(buffer_number)
      if buffer_name ~= "" and buffer_name:sub(1, 1) ~= "[" then
        local full = vim.fn.fnamemodify(buffer_name, ":p")
        if not string.find(full, cwd, 1, true) and not vim.bo[buffer_number].modified then
          vim.api.nvim_buf_delete(buffer_number, { force = true })
        end
      end
    end
  end
end

vim.api.nvim_create_user_command("Prune", function()
  prune_buffers()
  prune_lsp_clients()
end, { desc = "Prune buffers and lsp clients" })
