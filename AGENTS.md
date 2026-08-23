# AGENTS.md

Neovim configuration repo (Windows + MSYS2). Managed by [lazy.nvim](https://github.com/folke/lazy.nvim). No build/test/lint/CI — validation = launching Neovim and exercising the affected keymap/feature.

## Entry point & load order

`init.lua` sets options, keymaps, filetypes, then `require`s configs in this fixed order — do not reorder (changing it or removing a `require` causes startup errors):

1. `config.jumplist` → `config.project` → `config.lsp` (pre-lazy; these only use built-in APIs and define keymaps, no plugin requires — safe before lazy.nvim is bootstrapped). `config.lsp` is the module at `lua/config/lsp/init.lua`; it requires per-server configs internally (clangd → jdtls → lua → typescript), which call `vim.lsp.config` + `vim.lsp.enable` (these only register FileType autocmds; servers spawn on buffer open, after lazy+mason have loaded, so mason's PATH prepend is in effect by then). `config.jumplist` (`<leader>o`/`<leader>i` — walk the jumplist skipping same-buffer entries) and `config.project` (per-project `spell/`+`undodir` state, `.nvim/init.lua` hook) must load before the colorscheme since project init can set `vim.g.jdtls_formatter`/`vim.g.jdtls_settings`.
2. `config.lazy` (bootstraps lazy.nvim, auto-imports everything under `lua/plugins/`).
3. `config.telescope` → `config.oil` → `config.neotree` → `config.lsp_file_operations` → `config.multicursor` → `config.treesitter` → `config.conform` → `config.autotag` → `config.cmp` → `config.gitsigns` → `config.abolish` → `config.dap` → `config.wpm` → `config.lualine`
4. `config.snacks` is NOT required from `init.lua` — it runs in the `config =` callback of the snacks plugin spec (`lua/plugins/snacks.lua`, `lazy = false`, `priority = 1000`).
5. Colorscheme (conditional, last — reads `getcwd()` markers, see below).

## Layout

- `lua/config/<name>.lua` — settings, keymaps, plugin `setup()` for `<name>`.
- `lua/config/lsp/<name>.lua` — one file per LSP via `vim.lsp.config` + `vim.lsp.enable`. NOT auto-discovered, NOT in plugin specs. To add an LSP: create the file and add a `require("config.lsp.<name>")` line in `lua/config/lsp/init.lua`.
- `lua/plugins/<name>.lua` — lazy.nvim spec (returned as a table). Adding a plugin usually means one file in each of `lua/config/` and `lua/plugins/` with the same stem. Exception: `lua/plugins/mason.lua` returns TWO specs (mason.nvim + mason-tool-installer.nvim).
- `colors/vscpp.lua` — hand-rolled VS 2022 dark C++ colorscheme (not a plugin).
- `lazy-lock.json` — pinned commits; regenerate via lazy.nvim, don't hand-edit. May contain stale entries for removed plugins (e.g. `everforest` has no plugin spec anymore).

## Colorscheme (conditional, must stay last)

`init.lua` picks a colorscheme based on `getcwd()` markers (falling back to `kanagawa-dragon` when none match):

- C++ root (`CMakeLists.txt`, `.clangd`, `.clang-format`, `.clang-tidy`) → `colorscheme vscpp` (the hand-rolled `colors/vscpp.lua`).
- JS root (`package.json`, `tsconfig.json`, `jsconfig.json`, `node_modules`, `yarn.lock`, `pnpm-lock.yaml`, `package-lock.json`, `bun.lockb`, `.nvmrc`) → `colorscheme vscode`.
- Java root (`pom.xml`, `mvnw`, `mvnw.cmd`) → `colorscheme jb` (`jb.nvim`, in `lua/plugins/colorscheme.lua`).
- No match → `colorscheme kanagawa-dragon`.

Installed colorschemes (from `lua/plugins/colorscheme.lua`): vscode, onedarkpro, github, kanagawa, gruvbox, tokyonight, monokai-pro, jb. `<leader>fc` previews all of them.

## Platform: Windows + MSYS2

`init.lua` forces the shell to MSYS2 bash when `has("win32")`/`has("win64")`:

```
vim.g.is_windows = true
vim.opt.shell = "bash"
vim.opt.shellcmdflag = "-c"
vim.opt.shellquote = ""
vim.opt.shellxquote = ""
vim.opt.shellslash = true
```

`vim.g.is_windows` is the global flag for "current env is Windows" — prefer checking `vim.g.is_windows` over repeated `vim.fn.has("win32")` calls (e.g. `lua/config/telescope.lua` uses it for the `filename_first` backslash-normalization workaround).

So `:!cmd`, terminal jobs, conform formatters, and LSP spawns inherit a Unix-like PATH (git, `make`, compilers, node). Do NOT "fix" this back to `cmd.exe`/powershell — `telescope-fzf-native.nvim` (`build = 'make'`) and treesitter parsers rely on it.

## Leader key

`vim.g.mapleader = " "` (space). All `<leader>…` mappings depend on this.

## Post-install (starting fresh)

1. Launch Neovim — lazy clones itself into `stdpath('data')/lazy/lazy.nvim`.
2. `:Lazy` → wait for installs.
3. `:TSUpdate` — installs + compiles tree-sitter parsers via the `tree-sitter` CLI (must be on PATH; `nvim-treesitter` has `build = ":TSUpdate"`, `lazy = false`). Parser set is declared explicitly in `lua/config/treesitter.lua` via `ts.install(...)`.
4. `:Lazy build telescope-fzf-native` — runs `make`; needs `gcc` + `make` on PATH (MSYS2 `gcc`). Auto-build can silently no-op on Windows (MSYS2 build PATH isn't inherited into lazy's build job), so if `find_files`/`live_grep` feel slow, check `<data>/lazy/telescope-fzf-native.nvim/build/libfzf.dll` exists and run `make` by hand if not. `fzf` + `zoxide` are loaded as Telescope extensions.

## LSPs

Configured in `lua/config/lsp/*.lua` via `vim.lsp.config` + `vim.lsp.enable`, required from `config/lsp/init.lua`:

- `clangd` — `c`/`cpp`, `root_markers = {'.git','.clangd'}`.
- `lua_ls` — `lua`, `root_markers = {'.git','.luarc.json'}`, `vim` declared as a global.
- `ts_ls` — JS/TS, `root_markers = {tsconfig.json, jsconfig.json, package.json, .git}`; on Windows the binary is `typescript-language-server.cmd`.
- `jdtls` — `java`, started by the **`nvim-jdtls`** plugin (`lua/plugins/jdtls.lua`, `ft = "java"`), **deferred**: `require("nvim-jdtls").start_or_attach()` runs on the first `java` FileType via a one-shot autocmd, not at startup. The plain `vim.lsp.config`/`vim.lsp.enable` path is NOT used. `lua/config/lsp/jdtls.lua` owns discovery: Java >= 21 (`$JAVA_HOME` or `java` on PATH) and a jdtls install (`$JDTLS_HOME`, or `jdtls`/`jdtls.bat` shim on PATH, or probed common dirs incl. `C:/msys64/opt/jdtls`). Lombok is auto-discovered from Maven/Gradle caches. Per-project workspace cache lives under `stdpath('cache')/jdtls/workspace/<sha256-hash>`; `:JdtlsCleanWorkspace` wipes it (run then restart Neovim when indexes go stale). Per-project Eclipse formatter XML resolved in priority order: `vim.g.jdtls_formatter` → `$JDTLS_FORMATTER` → `<root>/jdt-formatter.xml`. Per-project JDT compiler `.prefs` via: `vim.g.jdtls_settings` → `$JDTLS_SETTINGS` → `<root>/.jdt-settings/org.eclipse.jdt.core.prefs`. `autobuild.enabled = false` — build with `./mvnw` yourself (jdtls's embedded JDT compiler can emit a classfile version the Java-21 runtime can't load).
  - **Java DAP + tests require the java-debug / vscode-java-test bundles**. `find_debug_bundles()` in `lua/config/lsp/jdtls.lua` resolves them, searching in order: `<jdtls-home>/java-debug` (+ `<jdtls-home>/vscode-java-test`), `stdpath('cache')/java-debug` (+ `.../vscode-java-test`), `~/.debug-plugins`, then mason-managed `<data>/mason/share/java-debug-adapter` (+ `.../java-test`). When found they're passed via `init_options.bundles`; nvim-jdtls then auto-registers the `java` DAP adapter (needs nvim-dap as a dependency — declared on the jdtls plugin spec) and `:DapNew` auto-discovers main classes / JUnit tests. `vim.g.jdtls_debug_bundles` exposes whether they were found. Missing bundles => LSP still works, DAP/tests silently disabled.

### mason.nvim + mason-tool-installer.nvim

Two separate plugins, both `lazy = false`, both in `lua/plugins/mason.lua`:
- `config.mason` only calls `require("mason").setup({})` — it does NOT hold `ensure_installed`.
- `config.mason-tool-installer` calls `require("mason-tool-installer").setup({ ensure_installed = {...}, run_on_start = true, start_delay = 3000 })` — this is the actual auto-installer. `ensure_installed`: `java-debug-adapter`, `java-test`, `clangd`, `lua-language-server`, `typescript-language-server`, `prettier`, `shfmt`.

mason prepends `<data>/mason/bin/` to `PATH` only within Neovim-spawned jobs (LSPs, conform, `:!`), so mason-managed binaries are invisible to a plain bash shell — available only to nvim. LSP servers are NOT wired through mason-lspconfig (config uses `vim.lsp.config`/`vim.lsp.enable`), so mason is only a source of tooling binaries. `:MasonInstall <pkg>` / `:MasonUpdate` manage them.

### Global LSP keymaps & commands

`<F2>` = `vim.lsp.buf.rename`, `[d`/`]d` = prev/next diagnostic, `<leader><space>` = LSP code action (normal + visual, filters out `disabled` actions). `:LspLog` opens the log in a new tab; `:LspLogClear` truncates it (restart Neovim if the client holds the file open). `:LspInfo` prints an aligned table of attached clients (`Client | PID | Memory | Buffers | Root`). PID + memory are resolved from the OS (nvim 0.12's LSP client doesn't expose server pid) by matching each server's binary name: Windows uses `wmic ... /format:csv` and **parses CSV from the trailing end** (CommandLine may contain commas/inconsistent quoting); wrapper shells (`cmd.exe`/`sh.exe`/`shell.exe`) are skipped so the reported pid is the real server, not the `.cmd` launcher. Linux/macOS use `ps -eo pid=,comm=,rss=` (largest-RSS match). Memory shows MB + a % of total RAM. Limitations: `wmic` is deprecated on newer Windows and may be absent (then the % drops and PID shows `?`); matching is by binary name, so multiple same-named servers aggregate to the largest match.

## Formatting (conform.nvim)

- `<A-F>` (normal) formats with `lsp_fallback = true`, `async = true`.
- `formatters_by_ft` (in `lua/config/conform.lua`): `prettier` for js/ts/jsx/tsx/json/jsonc/html/css/scss/yaml/markdown; `shfmt` for sh/bash/zsh; `clang-format` for c/cpp. Binaries must be on PATH (node/prettier, shfmt, clang-format) via the MSYS2 shell PATH. For C/C++, `<A-F>` shells out to the `clang-format` binary (same as the CLI), not clangd's built-in LSP formatter; `lsp_fallback` only fires if `clang-format` fails.

## Completion (nvim-cmp)

Sources: `nvim_lsp`, `buffer`, `path`. `lspkind.nvim` renders the menu (`mode = "symbol_text"`, `maxwidth = 50`). Keys: `<C-Space>` complete, `<CR>` confirm (`select = true`), `<Tab>`/`<S-Tab>` next/prev item, `<C-e>` abort. No `<C-n>` mapping — don't assume one.

## Other plugin conventions / quirks

- Tab/indent defaults: `tabstop=2`, `shiftwidth=2`, `expandtab=true`. Match this for filetype-specific overrides.
- `list` is on with custom `listchars` (space `·`, tab `→ `, trail `•`, nbsp `␣`). Don't disable.
- `spell`/`spelllang=en` on globally; `spelloptions = "camel,noplainbuffer"`, `spellcapcheck = ""`.
- Custom extension map in `init.lua` via `vim.filetype.add`: `.h`/`.hpp` → `cpp`, `.vs`/`.fs` → `glsl`.
- Treesitter highlighting is started via a `FileType` autocmd that `pcall(vim.treesitter.start)`s — NOT via the legacy `ensure_installed`/`highlight` module config. The parser list lives explicitly in `lua/config/treesitter.lua` (`ts.install(...)`); the plugin spec carries only `build = ":TSUpdate"`. Adding a parser = add to that list and run `:TSUpdate` (shells out to the `tree-sitter` CLI).
- Telescope `file_ignore_patterns`: `%.git`, `%.vs`, `%.idea` — keep updated for new large generated dirs. `path_display = "filename_first"`. `find_files`/`live_grep` have `hidden = true`. Leader mappings: `<leader>ff` files, `<leader>fo` oldfiles, `<leader>fg` live grep, `<leader>fr` LSP refs, `<leader>fd` LSP defs, `<leader>fi` LSP impls, `<leader>fb` buffers, `<leader>fh` help, `<leader>fc` colorscheme (preview enabled), `<leader>cd` zoxide. `utils.transform_path` is monkey-patched in `lua/config/telescope.lua` to normalize `/` → `\` on Windows before `filename_first` splits (workaround for [telescope#3157](https://github.com/nvim-telescope/telescope.nvim/issues/3157); done in config so it survives plugin updates).
- `<Esc>` in normal mode clears search highlights (`:noh`); in terminal mode it escapes (`<C-\><C-n>`). Be careful adding other `<Esc>` bindings — they override this.
- `init.lua` keymaps: `<C-j>`/`<C-k>` jump 10 lines (normal + visual); `<M-j>`/`<M-k>` move line/block up/down and reindent; `<A-z>` toggles `wrap`; `<leader>o`/`<leader>i` = prev/next different file in the jumplist (walks `getjumplist()` skipping same-buffer entries); `<leader><Tab>` next tab; `<leader>\`` opens a terminal in a new tab. Visual-mode `<Tab>`/`<S-Tab>` indent/dedent the selection (`>gv`/`<gv`). Insert-mode `{<CR>` opens a brace block and positions cursor inside; `{;<CR>` does the same with a trailing `;`.
- Snacks.nvim (`lazy = false`, `priority = 1000`): `dashboard` + `input` + `picker` are enabled in `lua/config/snacks.lua` (not only dashboard). Dashboard opened via `<leader>;`. Its `config =` callback is where `config.snacks` gets required (see the load-order note above).
- Multicursor: vim-visual-multi with `VM_default_mappings = 1`, `VM_mouse_mappings = 1`; `<M-LeftMouse>` adds a cursor (`VM_maps["Mouse Cursor"]`).
- Oil (file manager) opens on `-` (shows icon/permissions/size/mtime, hidden files visible). Neo-tree on `<leader>e` (`bind_to_cwd = false`, `follow_current_file` on, `filtered_items.visible = true`).
- vim-abolish coercion: `cr<key>` in normal mode (camelCase `c`, PascalCase `m`/`p`, snake_case `s`/`_`, UPPER `u`/`U`, kebab `-`/`k`, dot `.`, space `<space>`, custom Title Case `t` — snake→space→Title, registered via `g:Abolish.Coercions.t`). Visual mode uses `<leader>cr<key>` (not `cr`) to avoid colliding with the `c` change operator. Do **not** set `abolish_no_mappings` — vim-visual-multi special-cases `cr` and replays it across cursors, which needs the default `cr` mapping to exist.
- DAP (nvim-dap, `lazy = false`): **C/C++** via the `gdb` adapter (`--interpreter=dap`); launch config prompts for executable path + args. **Java** driven by nvim-jdtls (auto-registers the `java` adapter when bundles found — see jdtls section). Keys: `<F5>` continue, `<F6>` step over, `<F7>` step into, `<F8>` step out, `<F9>` toggle breakpoint, `<F10>` restart, `<S-F5>`/`<F17>` terminate, `<leader>dr` REPL, `<leader>du` dap-ui toggle, `<leader>ds` sessions sidebar. `:ClearBreakpoints` clears all. `dapui` auto-opens on `event_initialized`; `dap-virtual-text` set up if present. `config/dap.lua` `pcall`s its requires, so a missing plugin warns instead of erroring at startup.
- `nvim-lsp-file-operations` (renames/moves driven by LSP references): `lazy = false`, no opts. `lua/config/lsp_file_operations.lua` calls `require("lsp-file-operations").setup()`.
- `lualine.nvim` (statusline, `event = "VeryLazy"`): `theme = "auto"` (follows the conditional colorscheme), `lualine_z` = current time, `lualine_y` = `{ "location", "lsp_status" }`. Dep `nvim-web-devicons`.
- gitsigns: `current_line_blame` on, `virt_text_pos = "eol"`, `delay = 500`.
- fidget.nvim: `event = "LspAttach"`, `opts = {}` (LSP progress notifications).
- `config.project` (per-project state): walks up from cwd for a project root (only `.git` or `.nvim`) and sets up `<projectRoot>/.nvim/` with a `spell/` dir (`en.utf-8.add` prepended to `spellfile` so `zg` writes there), `undodir = <root>/.nvim/undo`, and an auto-generated `.gitignore` (`spell/*.spl`, `undo/*`). `:SpellAllGood` loops `]szg` to accept every misspelling suggestion. If `<projectRoot>/.nvim/init.lua` exists it is `dofile`d at the end (protected — a broken file warns, never breaks startup); this is the hook for a repo to register its own DAP configs / keymaps / commands / set `vim.g.jdtls_formatter` / `vim.g.jdtls_settings` without touching the global config.