local jit = require("jit")

vim.lsp.config("codebook", {
  cmd = { jit.os == "Windows" and "codebook-lsp.cmd" or "codebook-lsp", "serve" },
  root_markers = { ".git", "codebook.toml", ".codebook.toml" },
  exit_timeout = 100,
})
vim.lsp.enable("codebook")

local function add_word(word, client)
  client:request("workspace/executeCommand", {
    command = "codebook.addWord",
    arguments = { word },
  })
end

local function current_words(bufnr)
  local words = {}
  local client = vim.lsp.get_clients({ name = "codebook", bufnr = bufnr })[1]
  if not client then
    return words
  end
  local ns = vim.lsp.diagnostic.get_namespace(client.id)
  for _, diag in ipairs(vim.diagnostic.get(bufnr, { namespace = ns })) do
    local word = table.concat(
      vim.api.nvim_buf_get_text(bufnr, diag.lnum, diag.col, diag.end_lnum, diag.end_col, {})
    )
    if word ~= "" then
      words[word] = true
    end
  end
  return vim.tbl_keys(words)
end

vim.api.nvim_create_user_command("CodebookAddAll", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local client = vim.lsp.get_clients({ name = "codebook", bufnr = bufnr })[1]
  if not client then
    vim.notify("codebook LSP not attached", vim.log.levels.WARN)
    return
  end
  local words = current_words(bufnr)
  if #words == 0 then
    vim.notify("No misspelled words in current buffer", vim.log.levels.INFO)
    return
  end
  for _, word in ipairs(words) do
    add_word(word, client)
  end
  vim.notify(("Added %d word(s) to the local dictionary"):format(#words), vim.log.levels.INFO)
end, { desc = "Add all misspelled words in the current buffer to the local codebook dictionary" })
