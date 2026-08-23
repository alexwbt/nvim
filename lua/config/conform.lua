
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
    -- clang-format
    c = { "clang-format" },
    cpp = { "clang-format" },
    glsl = { "clang-format" },
  },
})

vim.keymap.set("n", "<leader>F", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format buffer" })
