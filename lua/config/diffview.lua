require("diffview").setup({
  enhanced_diff_hl = true,
  view = {
    default = {
      layout = "diff2_horizontal",
    },
  },
})

vim.api.nvim_create_user_command("GD", function(opts)
  vim.cmd("DiffviewOpen " .. opts.args)
end, { nargs = "*", desc = "Diffview open (with optional args)" })

vim.api.nvim_create_user_command("GDF", function()
  vim.cmd("DiffviewFileHistory %")
end, { desc = "Diffview current file history" })

vim.api.nvim_create_user_command("GDH", function()
  vim.cmd("DiffviewFileHistory")
end, { desc = "Diffview full repo history" })
