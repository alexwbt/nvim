# AGENTS.md

Neovim configuration repo (Windows + MSYS2). Managed by [lazy.nvim](https://github.com/folke/lazy.nvim).

## Entry point

`init.lua` is the Neovim entrypoint. It sets options, keymaps, filetypes, then `require`s configs in this fixed order — do not reorder:

1. `config.lazy` (must be first; bootstraps lazy.nvim and auto-imports everything under `lua/plugins/`)
2. `config.telescope` → `config.oil` → `config.neotree` → `config.multicursor` → `config.treesitter` → `config.conform` → `config.cmp` → `config.gitsigns` → `config.spell`
3. LSP configs: `config.lsp.clangd` → `config.lsp.jdtls` → `config.lsp.lua` → `config.lsp.typescript`
4. Colorscheme (conditional, last — depends on `getcwd()` markers, see below)

## Layout

- `lua/config/<name>.lua` — settings, keymaps, plugin `setup()` calls for `<name>`.
- `lua/config/lsp/<name>.lua` — one file per LSP using `vim.lsp.config` + `vim.lsp.enable`. Added/referenced explicitly from `init.lua` (NOT auto-discovered, NOT in plugin specs). To add an LSP: create `lua/config/lsp/<name>.lua` and add a `require("config.lsp.<name>")` line in `init.lua`.
- `lua/plugins/<name>.lua` — lazy.nvim spec for `<name>` (returned as a table). Adding a plugin usually means creating one file in each of `lua/config/` and `lua/plugins/` with the same stem.
- `colors/vscpp.lua` — hand-rolled VS 2022 dark C++ colorscheme (not a plugin).
- `lazy-lock.json` — pinned plugin commits; regenerate via lazy.nvim, do not hand-edit unless intentionally pinning.

## Colorscheme (conditional)

`init.lua` sets `colorscheme kanagawa-dragon` by default, then overrides based on project root markers in `getcwd()`:

- C++ root (`CMakeLists.txt`, `.clangd`, `.clang-format`, `.clang-tidy`) → `colorscheme vscpp` (the hand-rolled `colors/vscpp.lua`).
- JS root (`package.json`, `tsconfig.json`, `jsconfig.json`, `node_modules`, lockfiles, `.nvmrc`) → `colorscheme vscode`.

Because this runs after all plugin configs and reads `getcwd()`, the colorscheme block must stay last. Multiple installed colorschemes are available (vscode, kanagawa, tokyonight, everforest, onedarkpro, monokai-pro, github) — don't assume `<leader>fc` only shows one.

## Platform: Windows + MSYS2

`init.lua` forces the shell to MSYS2 bash when `has("win32")` or `has("win64")`:

```
vim.opt.shell = "bash"
vim.opt.shellcmdflag = "-c"
vim.opt.shellquote = ""
vim.opt.shellxquote = ""
vim.opt.shellslash = true
```

This means `:!cmd`, terminal jobs, conform formatters, and LSP spawns inherit a Unix-like PATH (git, `make`, compilers, node). Do not "fix" this back to `cmd.exe`/`powershell` — `telescope-fzf-native.nvim` (`build = 'make'`) and treesitter parsers rely on it.

## Leader key

`vim.g.mapleader = " "` (space). All `<leader>…` mappings in `lua/config/*.lua` depend on this.

## Post-install (lazy.nvim prompts; if starting fresh)

1. Launch Neovim — lazy clones itself into `stdpath('data')/lazy/lazy.nvim` on first run.
2. `:Lazy` → wait for installs to finish.
3. `:TSUpdate` — builds tree-sitter parsers (`nvim-treesitter` has `build = ":TSUpdate"`, `lazy = false`).
4. `:Lazy build telescope-fzf-native` — runs `make`; requires `gcc` and `make` on PATH (MSYS2 `gcc` package). Note: `telescope-fzf-native` is a dependency but is **not** loaded as a Telescope extension in `config/telescope.lua` — only `zoxide` is (`<leader>cd`).

## LSPs

Configured in `lua/config/lsp/*.lua` via `vim.lsp.config` + `vim.lsp.enable`, required from `init.lua`:

- `clangd` — `c`/`cpp`, `root_markers = {'.git','.clangd'}`.
- `lua_ls` — `lua`, `root_markers = {'.git','.luarc.json'}`, `vim` as a declared global.
- `ts_ls` — JS/TS, `root_markers = {tsconfig.json, jsconfig.json, package.json, .git}`; on Windows the binary is `typescript-language-server.cmd`.
- `jdtls` — `java`, **deferred**: discovery + `vim.lsp.enable` happen on the first `java` FileType via a one-shot autocmd, not at startup. Needs Java >= 21 (`$JAVA_HOME` or `java` on PATH) and a jdtls install (`$JDTLS_HOME`, or `jdtls`/`jdtls.bat` shim on PATH, or common install dirs). Lombok is auto-discovered from Maven/Gradle caches. Per-project workspace cache lives under `stdpath('cache')/jdtls/workspace/<hash>`; `:JdtlsCleanWorkspace` wipes it (run then restart Neovim when indexes go stale). On `language/status` `ServiceReady` it triggers a full `java/buildWorkspace` to clear stale import diagnostics. APT (e.g. MapStruct) runs automatically if declared in the build file.

Global LSP keymaps: `<F2>` = `vim.lsp.buf.rename`; `:LspLog` opens the LSP log.

## Formatting (conform.nvim)

- `<A-F>` in normal mode formats with `lsp_fallback = true`.
- `formatters_by_ft` is actually configured (not empty): `prettier` for js/ts/jsx/tsx/json/jsonc/html/css/scss/yaml/markdown; `shfmt` for sh/bash/zsh. These binaries must be on PATH (node/prettier, shfmt) — rely on the MSYS2 shell PATH above.

## Completion (nvim-cmp)

Sources: `nvim_lsp`, `buffer`, `path`. `lspkind.nvim` renders the menu (`mode = "symbol_text"`). Keys: `<C-Space>` complete, `<CR>` confirm (`select = true`), `<Tab>`/`<S-Tab>` next/prev item, `<C-e>` abort. (No `<C-n>` mapping — don't assume one.)

## Other plugin conventions / quirks

- Tab/indent defaults: `tabstop=2`, `shiftwidth=2`, `expandtab=true`. Match this for filetype-specific overrides.
- `list` is on with custom `listchars` (space `·`, tab `→ `, trail `•`, nbsp `␣`). Don't disable.
- Custom extension map in `init.lua` via `vim.filetype.add`: `.h`/`.hpp` → `cpp`, `.vs`/`.fs` → `glsl`.
- Treesitter highlighting is started via a `FileType` autocmd that `pcall(vim.treesitter.start)`s — not via the legacy `ensure_installed`/`highlight` module config. Adding a parser = `:TSInstall <lang>` (parsers build on `:TSUpdate`).
- Telescope `file_ignore_patterns`: `%.git`, `%.vs`, `%.idea`, `_build`, `_bin`, `_external` — keep this list updated for new large generated dirs. Telescope leader mappings: `<leader>ff` files, `<leader>fo` oldfiles, `<leader>fg` live grep, `<leader>fr` LSP refs, `<leader>fd` LSP defs, `<leader>fi` LSP impls, `<leader>fb` buffers, `<leader>fh` help, `<leader>fc` colorscheme, `<leader>cd` zoxide.
- `<Esc>` in normal mode clears search highlights (`:noh`). Be careful adding other `<Esc>` bindings — they override this.
- `init.lua` motion keymaps: `<C-j>`/`<C-k>` jump 10 lines (normal + visual); `<M-j>`/`<M-k>` move line/block up/down and reindent. Insert-mode `{<CR>` opens a brace block and positions cursor inside; `{;<CR>` does the same with a trailing `;`.
- Multicursor: vim-visual-multi with `VM_default_mappings = 1`, `VM_mouse_mappings = 1`; `<M-LeftMouse>` adds a cursor.
- Oil (file manager) opens on `-`; Neo-tree on `<leader>e`.
- gitsigns: `current_line_blame` on, shown at end-of-line.
- Spell: `spell`/`spelllang=en` on globally. A project-local spellfile at `<projectRoot>/.nvim/spell/en.utf-8.add` is prepended to `spellfile` so `zg` writes there (project root detected via `.git`/`.clangd`/`CMakeLists.txt`/`package.json` walking up). `:SpellAllGood` loops `]szg` to accept all spell suggestions. `.nvim/spell/*.spl` is gitignored (compiled spellfiles); the `.add` text files are tracked.

## No build / test / lint pipeline

There are no tests, formatter, or CI for this repo. Validation = launching Neovim and exercising the affected keymap/feature. If you change `init.lua` load order or remove a `require`, expect startup errors on next launch.