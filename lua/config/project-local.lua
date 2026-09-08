-- Project-local config hook: when a project root is found (walking up from cwd),
-- <projectRoot>/.nvim/init.lua is loaded if present.

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

  -- Project-local config: if <root>/.nvim/init.lua exists, load it. This is
  -- the hook for a specific repo to register DAP configs / keymaps / commands
  -- without touching the global config. Protected so a broken file warns, never
  -- breaks startup.
  local project_file = nvim_dir .. "/init.lua"
  if vim.uv.fs_stat(project_file) then
    local ok, err = pcall(dofile, project_file)
    if not ok then
      vim.notify(
        "project config error in " .. project_file .. ": " .. tostring(err),
        vim.log.levels.ERROR)
    end
  end
end
