local wpm = require("local.wpm")

wpm.setup({
  sample_count = 10,
  sample_interval = 2000,
  percentile = 0.8,
})

vim.api.nvim_create_user_command("WpmStats", function()
  local lines = {
    "WPM (current 80th pct): " .. wpm.wpm(),
    "Best:                   " .. wpm.best(),
    "Lifetime WPM (avg):     " .. wpm.lifetime_wpm(),
    "Historic graph:          " .. wpm.historic_graph(),
    "Sorted graph:           " .. wpm.sorted_graph(),
  }
  vim.api.nvim_echo(
    vim.tbl_map(function(l) return { l .. "\n", "Normal" } end, lines),
    true,
    {}
  )
end, { desc = "Show WPM stats" })

vim.api.nvim_create_user_command("WpmReset", function()
  wpm.reset_records()
  vim.api.nvim_echo({ { "WPM records reset.", "WarningMsg" } }, true, {})
end, { desc = "Reset WPM records" })

return wpm