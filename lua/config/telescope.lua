local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fr", builtin.lsp_references, { desc = "Telescope LSP references" })
vim.keymap.set("n", "<leader>fd", builtin.lsp_definitions, { desc = "Telescope LSP definitions" })
vim.keymap.set("n", "<leader>fi", builtin.lsp_implementations, { desc = "Telescope LSP implementations" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
vim.keymap.set("n", "<leader>fc", builtin.colorscheme)


local telescope = require("telescope")
local utils = require("telescope.utils")

-- Workaround for https://github.com/nvim-telescope/telescope.nvim/issues/3157
-- On Windows, `filename_first` splits only on backslash, but many pickers
-- (buffers, git_*, lsp_*) feed forward-slash paths. Normalize before
-- transforming so the split works. Patched here so it survives plugin
-- updates (vs. editing make_entry.lua in the plugin tree).
local _orig_transform_path = utils.transform_path
utils.transform_path = function(opts, path)
  if path ~= nil and vim.g.is_windows then
    path = path:gsub("/", "\\")
  end
  return _orig_transform_path(opts, path)
end

telescope.setup({
  defaults = {
    file_ignore_patterns = {
      "^%.git",
      "^%.vs",
      "^%.idea",
    },
    path_display = {
      "filename_first",
    },
    layout_config = {
      width = 0.99,
      height = 0.99,
      preview_width = 0.4,
    },
    preview = {
      wrap = false,
    },
  },
  pickers = {
    find_files = {
      hidden = true,
    },
    live_grep = {
      hidden = true,
    },
    colorscheme = {
      enable_preview = true,
    },
  },
})

telescope.load_extension("fzf")
telescope.load_extension("zoxide")
vim.keymap.set("n", "<leader>cd", telescope.extensions.zoxide.list, { desc = "Zoxide" })
