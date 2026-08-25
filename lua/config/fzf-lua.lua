local fzf = require("fzf-lua")

fzf.setup({
  -- Reuse the same ignore patterns telescope uses
  files = {
    file_ignore_patterns = { "^%.git", "^%.vs", "^%.idea" },
  },
  grep = {
    -- rg is reused/streamed; backspace prunes instead of re-spawning
    file_ignore_patterns = { "^%.git", "^%.vs", "^%.idea" },
    actions = {
      ["ctrl-s"] = function(_, opts)
        local rg_query = opts and opts.search or ""
        require("spectre").open({ search_text = rg_query })
      end,
    },
  },
  winopts = {
    -- almost fullscreen (matches telescope's width=0.99 height=0.99)
    width = 0.99,
    height = 0.99,
    preview = {
      layout = "horizontal",
      -- match telescope's preview_width = 0.4
      horizontal = "right:40%",
    },
  },
})

-- Match the existing <leader>fg binding, but go through fzf-lua's live_grep
-- (stream-reuses rg, no per-keystroke re-spawn, no freeze on backspace).
vim.keymap.set("n", "<leader>fg", fzf.live_grep, { desc = "FzfLua live grep" })
