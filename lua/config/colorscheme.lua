-- Per-colorscheme highlight overrides. Keyed by `vim.g.colors_name`, then by
-- highlight group -> `nvim_set_hl` attrs.
local scheme_overrides = {
  jb = {
    TelescopePreviewLine = { link = "Visual" },
    TelescopePreviewMatch = { link = "Search" },
  },
}

local function apply_all()
  local overrides = scheme_overrides[vim.g.colors_name]
  if not overrides then return end
  for group, attrs in pairs(overrides) do
    vim.api.nvim_set_hl(0, group, attrs)
  end
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_all })
