require("fidget").setup({
  notification = {
    poll = 200,
    history = {
      enabled = true,
    },
  },
})

vim.notify = require("fidget").notify
