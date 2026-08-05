-- Load a project-local spellfile from <projectRoot>/.nvim/spell/en.utf-8.add
-- Falls back to the user spellfile if no project root is found.

local function find_project_root()
  local dir = vim.fn.getcwd()
  local markers = { ".git", ".clangd", "CMakeLists.txt", "package.json" }
  for _ = 1, 20 do
    for _, marker in ipairs(markers) do
      if vim.fn.isdirectory(dir .. "/" .. marker) == 1
        or vim.fn.filereadable(dir .. "/" .. marker) == 1
      then
        return dir
      end
    end
    local parent = vim.fn.fnamodify(dir, ":h")
    if parent == dir then break end
    dir = parent
  end
  return nil
end

local root = find_project_root()
if root then
  local spell_dir = root .. "/.nvim/spell"
  vim.fn.mkdir(spell_dir, "p")
  local project_spell = spell_dir .. "/en.utf-8.add"
  -- prepend so `zg` writes to the project spellfile
  vim.opt.spellfile:prepend(project_spell)
end