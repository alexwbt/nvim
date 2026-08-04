# AGENTS.md

Neovim configuration repo (Windows + MSYS2). Managed by [lazy.nvim](https://github.com/folke/lazy.nvim).

## Entry point

- `init.lua` is the Neovim entrypoint. It sets options, keymaps, filetypes, LSP, then `require`s configs in this fixed order:
  - `config.lazy` → `config.telescope` → `config.oil` → `config.neotree` → `config.multicursor` → `config.treesitter` → `config.conform` → `config.cmp` → `config.jdtls`
  - Finally: `colorscheme vscode` (`mofiqul/vscode.nvim`).
- Do not change the order. `lazy` must run first; it bootstraps the plugin manager and auto-imports everything under `lua/plugins/`.

## Layout

- `lua/config/<name>.lua` — settings, keymaps, plugin `setup()` calls for `<name>`.
- `lua/plugins/<name>.lua` — lazy.nvim spec for `<name>` (returned as a table). Adding a plugin usually means creating one file in each of these two directories with the same stem.
- `lazy-lock.json` — pinned plugin commits; regenerate via lazy.nvim, do not hand-edit unless intentionally pinning.

## Platform: Windows + MSYS2

`init.lua` forces the shell to MSYS2 bash when running on Windows:

```
vim.opt.shell      = "bash"
vim.opt.shellcmdflag = "-c"
vim.opt.shellquote = ""
vim.opt.shellxquote = ""
vim.opt.shellslash = true
```

This means `:!cmd`, terminal jobs, and any external formatter spawned via conform/lsp inherit a Unix-like PATH (git, `make`, compilers). Do not "fix" this back to `cmd.exe`/`powershell` — plugins like `telescope-fzf-native.nvim` (`build = 'make'`) and treesitter parsers rely on it.

## Leader key

`vim.g.mapleader = " "` (space). All `<leader>…` mappings in `lua/config/*.lua` depend on this.

## Post-install steps (lazy.nvim will prompt; if starting fresh)

1. Launch Neovim — lazy clones itself into `stdpath('data')/lazy/lazy.nvim` on first run.
2. `:Lazy` → wait for installs to finish.
3. `:TSUpdate` — builds tree-sitter parsers (`nvim-treesitter` has `build = ":TSUpdate"`).
4. `:Lazy build telescope-fzf-native` — runs `make`; requires a C compiler and `make` on PATH (MSYS2 `gcc` package).

## Conventions / quirks

- Tab/indent defaults: `tabstop=2`, `shiftwidth=2`, `expandtab=true`. Match this when adding filetype-specific overrides.
- `list` is on with custom `listchars` (space `·`, tab `→ `, trail `•`, nbsp `␣`). Don't disable.
- Custom extension map in `init.lua` via `vim.filetype.add`: `.h`/`.hpp` → `cpp`, `.vs`/`.fs` → `glsl` (shader files).
- LSPs are configured in `init.lua` via `vim.lsp.config` + `vim.lsp.enable` (NOT in plugin specs):
  - `clangd` — `c`/`cpp`, `root_markers = {'.git','.clangd'}`
  - `ts_ls` — JS/TS, `root_markers = {tsconfig.json, jsconfig.json, package.json, .git}`; on Windows the binary is `typescript-language-server.cmd`
  - `jdtls` — `java`, `root_markers = {'.git','mvnw','gradlew','pom.xml','build.gradle'}`
  - Add new LSPs the same way.
- Telescope `file_ignore_patterns`: `%.git`, `%.vs`, `%.idea`, `_build`, `_bin`, `_external` — keep this list updated if you add other large generated dirs.
- The `<Esc>` mapping in normal mode clears search highlights (`:noh`). Be careful adding other `<Esc>` bindings — they will override this one.
- Formatting: conform.nvim, triggered by `<A-F>` in normal mode (`lsp_fallback = true`). No formatters are configured in the spec (`opts = {}`), so it relies on LSP fallback.
- Completion: nvim-cmp with `nvim_lsp`/`buffer`/`path` sources; `<C-Space>`/`<C-n>` complete, `<CR>` confirms, `<Tab>`/`<S-Tab>` navigate.
- Multicursor: vim-visual-multi with default mappings; `<M-LeftMouse>` adds a cursor.
- Oil (file manager) opens on `-`; Neo-tree on `<leader>e`.

## No build / test / lint pipeline

There are no tests, formatter, or CI for this repo. Validation = launching Neovim and exercising the affected keymap/feature. If you change `init.lua` load order or remove a `require`, expect startup errors on next launch.
