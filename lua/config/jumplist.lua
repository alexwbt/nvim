---Find the nearest jumplist index whose entry is in a different, loaded buffer.
---@param start integer starting index (0-based, into getjumplist()[1])
---@param stop integer ending index (inclusive, 0-based)
---@param step integer -1 to search backward, 1 to search forward
---@return integer|nil target 0-based jumplist index, or nil if none found
local function find_target(start, stop, step)
  local result = vim.fn.getjumplist()
  local jumps = result[1] or {}
  local curbuf = vim.api.nvim_get_current_buf()
  for i = start, stop, step do
    local j = jumps[i + 1]
    if j and j.bufnr ~= curbuf and vim.api.nvim_buf_is_loaded(j.bufnr) then
      return i
    end
  end
end

---Jump `delta` steps in the jumplist via <C-o>/<C-i> feedkeys.
---@param target integer|nil 0-based jumplist index to jump to (nil = notify + abort)
---@param curjump integer current 0-based jumplist position from getjumplist()[2]
local function jump(target, curjump)
  if not target then
    vim.notify("No other file in jumplist", vim.log.levels.INFO)
    return
  end
  local delta = target - curjump
  local key = delta < 0 and "<C-o>" or "<C-i>"
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(math.abs(delta) .. key, true, true, true),
    "n", false)
end

---Jump to the previous different-file entry in the jumplist.
local function previous()
  local result = vim.fn.getjumplist()
  local curjump = result[2] or 0
  jump(find_target(curjump - 1, 0, -1), curjump)
end

---Jump to the next different-file entry in the jumplist.
local function next()
  local result = vim.fn.getjumplist()
  local jumps = result[1] or {}
  local curjump = result[2] or 0
  jump(find_target(curjump + 1, #jumps - 1, 1), curjump)
end

vim.keymap.set("n", "<leader>o", previous, { desc = "Older file in jumplist" })
vim.keymap.set("n", "<leader>i", next, { desc = "Newer file in jumplist" })
