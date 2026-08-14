-- Per-project state under <projectRoot>/.nvim/.
--   spell/        spellfile additions (zg writes here)
--   undo/         persistent undo history
--   .gitignore    auto-generated; ignores compiled spell + undo
--
-- Only active when a project root is found (walking up from cwd).

local function find_project_root()
  local dir = vim.fn.getcwd()
  local markers = { ".git", ".nvim" }
  for _ = 1, 20 do
    for _, marker in ipairs(markers) do
      if vim.fn.isdirectory(dir .. "/" .. marker) == 1
          or vim.fn.filereadable(dir .. "/" .. marker) == 1
      then
        return dir
      end
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then break end
    dir = parent
  end
  return nil
end

local root = find_project_root()
if root then
  local nvim_dir = root .. "/.nvim"
  vim.fn.mkdir(nvim_dir, "p")

  local gitignore = nvim_dir .. "/.gitignore"
  if vim.fn.filereadable(gitignore) ~= 1 then
    vim.fn.writefile({
      "spell/*.spl",
      "undo/*",
    }, gitignore)
  end

  -- Spell
  local spell_dir = nvim_dir .. "/spell"
  vim.fn.mkdir(spell_dir, "p")
  vim.opt.spellfile:prepend(spell_dir .. "/en.utf-8.add")

  -- Undo
  local undodir = nvim_dir .. "/undo"
  vim.opt.undodir = undodir
  vim.fn.mkdir(undodir, "p")
end

vim.api.nvim_create_user_command("SpellAllGood", function()
  vim.cmd('normal! gg')
  for _ = 1, 99 do
    vim.cmd('normal! ]szg')
  end
end, {})
