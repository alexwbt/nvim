vim.keymap.set("n", "<leader>e", "<Cmd>Neotree toggle<CR>")

local neotree = require("neo-tree")

neotree.setup({
  filesystem = {
    bind_to_cwd = false,
    group_empty_dirs = true,
    scan_mode = "deep",
    follow_current_file = {
      enabled = true,
      leave_dirs_open = false,
    },
    filtered_items = {
      visible = true,
    },
  },
})

vim.keymap.set("n", "<leader>ge", function()
  local manager = require("neo-tree.sources.manager")
  local states = manager._get_all_states()
  local changed = false
  for _, state in ipairs(states) do
    if state.name == "filesystem" then
      state.group_empty_dirs = not state.group_empty_dirs
      changed = true
    end
  end
  if changed then
    manager.refresh("filesystem")
  end
end)
