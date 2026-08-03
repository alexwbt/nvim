
vim.keymap.set("n", "<A-F>", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format buffer" })
