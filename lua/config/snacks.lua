local Snacks = require("snacks")

Snacks.setup({
  input = { enabled = true },
  picker = { enabled = true },
  dashboard = {
    preset = {
      header = { "Neovim", align = "left" },
      keys = {
        { icon = " ", key = "f", desc = "Find File", action = ":Telescope find_files" },
        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
        { icon = " ", key = "g", desc = "Find Text", action = ":Telescope live_grep" },
        { icon = " ", key = "o", desc = "Recent Files", action = ":Telescope oldfiles" },
        { icon = " ", key = "c", desc = "Jump Dir (zoxide)", action = ":Telescope zoxide list" },
        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
    sections = {
      { section = "header" },
      {
        pane = 1, section = "keys", gap = 1, padding = 2,
      },
      { pane = 2, padding = 1, icon = " ", title = "Recent Files", section = "recent_files", indent = 2 },
      { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
      { section = "startup" },
    },
  },
})

vim.keymap.set("n", "<leader>;", Snacks.dashboard.open, { desc = "Open dashboard" })
