local root_markers      = {
  ".git",
  ".nvim"
}
local cpp_root_makers   = {
  "CMakeLists.txt",
  ".clangd",
  ".clang-format",
  ".clang-tidy"
}
local js_root_markers   = {
  "package.json",
  "tsconfig.json",
  "jsconfig.json",
  "node_modules",
  "yarn.lock",
  "pnpm-lock.yaml",
  "package-lock.json",
  "bun.lockb",
  ".nvmrc",
}
local java_root_markers = {
  "pom.xml",
  "mvnw",
  "mvnw.cmd",
}

local function find_project_root()
  local dir     = vim.fn.getcwd()
  local markers = {
    root_markers,
    cpp_root_makers,
    js_root_markers,
    java_root_markers
  }
  markers       = vim.iter(markers):flatten():totable()
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

-- Project-local config hook: when a project root is found (walking up from cwd),
-- <projectRoot>/.nvim/init.lua is loaded if present.
local function load_project_config()
  local root = find_project_root()
  if not root then return end

  -- Project-local config: if <root>/.nvim/init.lua exists, load it. This is
  -- the hook for a specific repo to register DAP configs / keymaps / commands
  -- without touching the global config. Protected so a broken file warns, never
  -- breaks startup.
  local nvim_dir = root .. "/.nvim"
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

local function set_project_colorscheme()
  local root = find_project_root()
  if not root then
    vim.cmd("colorscheme kanagawa-dragon")
    return
  end

  local function has_root_markers(markers)
    for _, marker in ipairs(markers) do
      if vim.fn.filereadable(root .. "/" .. marker) == 1 then
        return true
      end
    end
    return false
  end

  if has_root_markers(cpp_root_makers) then
    vim.cmd("colorscheme vscpp")
  elseif has_root_markers(js_root_markers) or has_root_markers(java_root_markers) then
    vim.cmd("colorscheme vscode")
  else
    vim.cmd("colorscheme kanagawa-dragon")
  end
  vim.opt.bg = "dark"
end

vim.api.nvim_create_autocmd("DirChanged", {
  callback = function()
    vim.defer_fn(function()
      load_project_config()
      set_project_colorscheme()
      local ok, lualine = pcall(require, "config.lualine")
      if ok and lualine.apply_state then
        lualine.apply_state()
      end
    end, 50)
  end,
})

return {
  set_project_colorscheme = set_project_colorscheme
}
