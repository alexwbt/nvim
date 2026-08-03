
local cmp = require("cmp")
local lspkind = require("lspkind")

cmp.setup({
  window = {
    completion = {
      border = 'rounded',
      winhighlight = 'Normal:CmpMenuNormal,FloatBorder:CmpMenuBorder',
    },
    documentation = {
      border = 'rounded',
      winhighlight = 'Normal:CmpMenuNormal,FloatBorder:CmpMenuBorder',
    },
  },
  sources = {
    { name = "nvim_lsp" },
    { name = "buffer" },
    { name = "path" },
  },
  formatting = {
    format = lspkind.cmp_format({
      mode = "symbol_text",
      maxwidth = 50,
      ellipsis_char = "...",
    }),
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-n>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping.select_next_item(),
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
    ["<C-e>"] = cmp.mapping.abort(),
  }),
})
