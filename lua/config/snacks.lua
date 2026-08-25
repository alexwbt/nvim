local Snacks = require("snacks")

Snacks.setup({
  input = { enabled = true },
  picker = { enabled = true },
  dashboard = {
    preset = {
      header = { vim.fn.getcwd(), align = "left" },
      keys = {
        { icon = " ", key = "f", desc = "Find File", action = ":Telescope find_files" },
        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
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
        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
    sections = {
      { section = "header" },
      {
        pane = 1, section = "keys", gap = 1, padding = 2,
      },
      { section = "startup" },
    },
  },
})

vim.keymap.set("n", "<leader>;", Snacks.dashboard.open, { desc = "Open dashboard" })
