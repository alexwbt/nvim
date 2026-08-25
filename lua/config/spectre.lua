local spectre = require("spectre")

spectre.setup({
  live_update = false,
  is_insert_mode = false,
  open_cmd = "tabnew",
})

vim.keymap.set("n", "<leader>S",
  function() spectre.toggle() end,
  { desc = "Spectre toggle" });

vim.keymap.set("n", "<leader>sw",
  function() spectre.open_visual({ select_word = true }) end,
  { desc = "Spectre search current word" });

vim.keymap.set("n", "<leader>sf",
  function() spectre.open_file_search({ select_word = true }) end,
  { desc = "Spectre search on current file" });
