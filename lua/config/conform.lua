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
    -- rustfmt
    rust = { "rustfmt" },
    -- ruff
    python = { "ruff_format", "ruff_organize_imports" },
    -- sql-formatter
    sql = { "sql_formatter" },
  },
  formatters = {
    sql_formatter = {
      prepend_args = function(self, ctx)
        local lines = vim.api.nvim_buf_get_lines(ctx.buf, 0, 5, false)
        for _, line in ipairs(lines) do
          -- Matches "-- dialect: mysql", "-- language: mysql", or "-- sqlfluff:dialect:mysql"
          local dialect = line:match("^%s*%-%-%s*sqlfluff%s*:%s*dialect%s*:%s*([%w_]+)")
              or line:match("^%s*%-%-%s*dialect%s*:%s*([%w_]+)")
              or line:match("^%s*%-%-%s*language%s*:%s*([%w_]+)")
          if dialect then
            return { "-l", dialect:lower() }
          end
        end
        return { "-l", "mysql" } -- default fallback
      end,
    },
  }
})

vim.keymap.set("n", "<leader>F", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format buffer" })
