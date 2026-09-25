local Snacks = require("snacks")

Snacks.setup({
  input = { enabled = true },
  picker = { enabled = true },
  dashboard = {
    preset = {
      keys = {
        { icon = " ", key = "f", desc = "Find File", action = ":Telescope find_files" },
        { icon = " ", key = "g", desc = "Find Text", action = ":FzfLua live_grep" },
        { icon = " ", key = "o", desc = "Recent Files", action = ":Telescope oldfiles" },
        {
          icon = " ",
          key = "e",
          desc = "Explore Files",
          action = function()
            vim.cmd(":Neotree")
            vim.cmd.only()
          end
        },
        { icon = " ", key = "c", desc = "Change Dir", action = ":Telescope zoxide list" },
        { icon = " ", title = "Recent Files", section = "recent_files", pane = 2, padding = 2 },
        { icon = " ", title = "Projects", section = "projects", pane = 2, padding = 2, pick = false },
        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
    sections = {
      { section = "header" },
      { pane = 1, section = "keys", padding = 2 },
    },
  },
})

vim.keymap.set("n", "<leader>;", Snacks.dashboard.open, { desc = "Open dashboard" })
