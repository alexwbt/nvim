
require("conform").setup({
  formatters_by_ft = {
    -- prettier
    javascript = { "prettier" },
    typescript = { "prettier" },
    javascriptreact = { "prettier" },
    typescriptreact = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    html = { "prettier" },
    css = { "prettier" },
    scss = { "prettier" },
    yaml = { "prettier" },
    markdown = { "prettier" },
    -- shfmt
    sh = { "shfmt" },
    bash = { "shfmt" },
    zsh = { "shfmt" },
  },
})

vim.keymap.set("n", "<A-F>", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format buffer" })
