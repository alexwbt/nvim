-- Per-project state under <projectRoot>/.nvim/
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

  -- Project-local config: if <root>/.nvim/init.lua exists, load it. This is
  -- the hook for a specific repo to register DAP configs / keymaps / commands
  -- without touching the global config. Protected so a broken file warns, never
  -- breaks startup.
  local proj_file = nvim_dir .. "/init.lua"
  if vim.uv.fs_stat(proj_file) then
    local ok, err = pcall(dofile, proj_file)
    if not ok then
      vim.notify(
        "project config error in " .. proj_file .. ": " .. tostring(err),
        vim.log.levels.ERROR)
    end
  end
end

vim.api.nvim_create_user_command("SpellAllGood", function()
  vim.cmd("normal! gg")
  for _ = 1, 99 do
    vim.cmd("normal! ]szg")
  end
end, {})

vim.api.nvim_create_user_command("FixSpell", function()
  local sf = vim.opt.spellfile:get()
  local path = sf and sf[1]
  if not path or vim.fn.filereadable(path) ~= 1 then
    vim.notify("FixSpell: no writable spellfile in 'spellfile' option", vim.log.levels.ERROR)
    return
  end
  local lines = vim.fn.readfile(path)
  local seen, dedup = {}, {}
  for _, w in ipairs(lines) do
    local lw = w:lower()
    if not seen[lw] then
      seen[lw] = true
      dedup[#dedup + 1] = lw
    end
  end
  table.sort(dedup)
  vim.fn.writefile(dedup, path)
  vim.cmd("mkspell! " .. vim.fn.fnameescape(path))
  vim.notify("FixSpell: " .. path .. " sorted + deduped (" .. #dedup .. " words)", vim.log.levels.INFO)
end, {})
