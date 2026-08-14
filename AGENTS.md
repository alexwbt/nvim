# AGENTS.md

Neovim configuration repo (Windows + MSYS2). Managed by [lazy.nvim](https://github.com/folke/lazy.nvim).

## Entry point

`init.lua` is the Neovim entrypoint. It sets options, keymaps, filetypes, then `require`s configs in this fixed order — do not reorder:

1. `config.lazy` (must be first; bootstraps lazy.nvim and auto-imports everything under `lua/plugins/`)
2. `config.telescope` → `config.oil` → `config.neotree` → `config.lsp_file_operations` → `config.multicursor` → `config.treesitter` → `config.conform` → `config.cmp` → `config.gitsigns` → `config.abolish` → `config.dap` → `config.lualine` → `config.vim`
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

Because this runs after all plugin configs and reads `getcwd()`, the colorscheme block must stay last. Multiple installed colorschemes are available (vscode, kanagawa, tokyonight, everforest, onedarkpro, monokai-pro, github, gruvbox) — don't assume `<leader>fc` only shows one.

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
3. `:TSUpdate` — installs + compiles tree-sitter parsers via the `tree-sitter` CLI (must be on PATH; `nvim-treesitter` has `build = ":TSUpdate"`, `lazy = false`). Parser set is declared explicitly in `lua/config/treesitter.lua` via `ts.install(...)`.
4. `:Lazy build telescope-fzf-native` — runs `make`; requires `gcc` and `make` on PATH (MSYS2 `gcc` package). Note: `telescope-fzf-native` is a dependency but is **not** loaded as a Telescope extension in `config/telescope.lua` — only `zoxide` is (`<leader>cd`).

## LSPs

Configured in `lua/config/lsp/*.lua` via `vim.lsp.config` + `vim.lsp.enable`, required from `init.lua`:

- `clangd` — `c`/`cpp`, `root_markers = {'.git','.clangd'}`.
- `lua_ls` — `lua`, `root_markers = {'.git','.luarc.json'}`, `vim` as a declared global.
- `ts_ls` — JS/TS, `root_markers = {tsconfig.json, jsconfig.json, package.json, .git}`; on Windows the binary is `typescript-language-server.cmd`.
- `jdtls` — `java`, started by the **`nvim-jdtls`** plugin (`lua/plugins/jdtls.lua`, `ft = "java"`), **deferred**: `require("nvim-jdtls").start_or_attach()` runs on the first `java` FileType via a one-shot autocmd, not at startup. The plain `vim.lsp.config`/`vim.lsp.enable` path is NOT used. `lua/config/lsp/jdtls.lua` still owns discovery: Java >= 21 (`$JAVA_HOME` or `java` on PATH) and a jdtls install (`$JDTLS_HOME`, or `jdtls`/`jdtls.bat` shim on PATH, or common install dirs). Lombok is auto-discovered from Maven/Gradle caches. Per-project workspace cache lives under `stdpath('cache')/jdtls/workspace/<hash>`; `:JdtlsCleanWorkspace` wipes it (run then restart Neovim when indexes go stale). nvim-jdtls rebuilds the workspace (`java/buildWorkspace`) after import automatically, clearing stale import diagnostics. APT (e.g. MapStruct) runs automatically if declared in the build file.
  - **Java DAP + tests require the java-debug / vscode-java-test bundles**. These come from **mason.nvim** (`lua/config/mason.lua` → `ensure_installed = { "java-debug-adapter", "java-test" }`, managed installs under `<data>/mason/share`). `find_debug_bundles()` in `lua/config/lsp/jdtls.lua` resolves them. It also scans `<jdtls-home>/java-debug` + `<jdtls-home>/vscode-java-test`, `stdpath('cache')/java-debug` + `.../vscode-java-test`, and `~/.debug-plugins` for manually-placed jars. When found they're passed via `init_options.bundles`; nvim-jdtls then auto-registers the `java` DAP adapter (needs nvim-dap listed as a dependency — it is) and `:DapNew` auto-discovers main classes / JUnit tests. `config/dap.lua` + the datacanva project config only add launch configs when bundles were found. Missing bundles => LSP still works, DAP/tests silently disabled.
- `config.mason` (mason.nvim, `lazy = false`): package manager for the java-debug-adapter / java-test bundles (the jars nvim-jdtls needs). LSP servers are NOT wired through mason-lspconfig — this config uses `vim.lsp.config`/`vim.lsp.enable` — so mason here is only a source of managed tooling, currently just the Java debug/test bundles. `:MasonInstall <pkg>` / `:MasonUpdate` manage them.

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
- Treesitter highlighting is started via a `FileType` autocmd that `pcall(vim.treesitter.start)`s — not via the legacy `ensure_installed`/`highlight` module config. The parser list lives explicitly in `lua/config/treesitter.lua` (`ts.install(...)`) and the plugin spec no longer carries `opts.ensure_installed`. Adding a parser = add to that list and run `:TSUpdate` (which shells out to the `tree-sitter` CLI).
- Telescope `file_ignore_patterns`: `%.git`, `%.vs`, `%.idea` — keep this list updated for new large generated dirs. Telescope leader mappings: `<leader>ff` files, `<leader>fo` oldfiles, `<leader>fg` live grep, `<leader>fr` LSP refs, `<leader>fd` LSP defs, `<leader>fi` LSP impls, `<leader>fb` buffers, `<leader>fh` help, `<leader>fc` colorscheme, `<leader>cd` zoxide.
- `<Esc>` in normal mode clears search highlights (`:noh`). Be careful adding other `<Esc>` bindings — they override this.
- `init.lua` motion keymaps: `<C-j>`/`<C-k>` jump 10 lines (normal + visual); `<M-j>`/`<M-k>` move line/block up/down and reindent. Visual-mode `<Tab>`/`<S-Tab>` indent/dedent the selection (`>gv`/`<gv`). Insert-mode `{<CR>` opens a brace block and positions cursor inside; `{;<CR>` does the same with a trailing `;`.
- Multicursor: vim-visual-multi with `VM_default_mappings = 1`, `VM_mouse_mappings = 1`; `<M-LeftMouse>` adds a cursor.
- Oil (file manager) opens on `-`; Neo-tree on `<leader>e`.
- vim-abolish coercion: `cr<key>` in normal mode (camelCase `c`, MixedCase `m`/`p`, snake_case `s`/`_`, UPPER `u`/`U`, kebab `-`/`k`, dot `.`, space `<space>`, custom Title Case `t`). Visual mode uses `<leader>cr<key>` (not `cr`) to avoid colliding with the `c` change operator. Do **not** set `abolish_no_mappings` — vim-visual-multi special-cases `cr` and replays it across cursors, which needs the default `cr` mapping to exist.
- DAP (nvim-dap, `lazy = false`): **C/C++** via the `gdb` adapter (`--interpreter=dap`); **Java** is driven by nvim-jdtls (auto-registers the `java` adapter when the java-debug bundles are found — see the jdtls section). Keys: `<F5>` continue, `<F6>` step over, `<F7>` step into, `<F8>` step out, `<F9>` toggle breakpoint, `<F10>` restart, `<S-F5>`/`<F17>` terminate, `<leader>dr` REPL, `<leader>du` dap-ui toggle. `dapui` auto-opens on init / auto-closes on terminate|exited. `config/dap.lua` `pcall`s its requires, so a missing plugin warns instead of erroring at startup.
- `nvim-lsp-file-operations` (renames/moves driven by LSP references): `lazy = false`, no opts. `lua/config/lsp_file_operations.lua` calls `require("lsp-file-operations").setup()` with no args.
- `lualine.nvim` (statusline): `event = "VeryLazy"`, dep `nvim-web-devicons`. `lua/config/lualine.lua` calls `setup({ options = { theme = "auto" } })` so it follows the conditional kanagawa / vscpp / vscode colorscheme.
- gitsigns: `current_line_blame` on, shown at end-of-line.
- `config.vim` (per-project state): walks up from cwd for a project root (`.git`/`.clangd`/`CMakeLists.txt`/`package.json`/`.nvim`) and sets up `<projectRoot>/.nvim/` with a `spell/` dir (`en.utf-8.add` prepended to `spellfile` so `zg` writes there), `undofile` + `undodir = <root>/.nvim/undo`, and an auto-generated `.gitignore` (`spell/*.spl`, `undo/*`). `:SpellAllGood` loops `]szg` to accept every misspelling suggestion. `spell`/`spelllang=en` is on globally.

## No build / test / lint pipeline

There are no tests, formatter, or CI for this repo. Validation = launching Neovim and exercising the affected keymap/feature. If you change `init.lua` load order or remove a `require`, expect startup errors on next launch.