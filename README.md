# Neovim config

Neovim configuration managed by [lazy.nvim](https://github.com/folke/lazy.nvim).
See `AGENTS.md` for the full architecture / conventions write-up.

## Platform note

The config is platform-conditional, not platform-locked: everything below
describes external dependencies that must be findable on the PATH at runtime
(install them with your normal package manager). On Windows, `init.lua` forces
`&shell = "bash"` with Unix-style flags, so every external program (`:!`,
conform, LSPs) is resolved against the bash PATH; on Linux/macOS this is a
no-op — the native shell/PATH apply. `vim.g.is_windows` is set in that same
block and is the global flag for "current env is Windows"; prefer it over
repeated `vim.fn.has("win32")` calls.

## Manual setup (not automated)

Most tooling (clangd, lua-language-server, typescript-language-server, codebook,
prettier, shfmt, java-debug/java-test bundles) is auto-installed by
**mason-tool-installer** on first launch, and plugins/treesitter install via
`:Lazy`/`:TSUpdate`. The following must be set up by hand:

### 1. Nerd Font (terminal font)

Icons (nvim-web-devicons, lualine, snacks, telescope, gitsigns, etc.) are Nerd
Font glyphs, rendered by the **terminal emulator**, not by nvim. This config
does not install or select a font, so you must install a patched Nerd Font
(e.g. from [nerdfonts.com](https://www.nerdfonts.com)) and set it as your
terminal's font. Without it, icons show as blank boxes / question marks.

### 2. System packages (your OS package manager, not nvim/mason)

These are binaries that must be findable on the PATH. mason only ships
LSP/formatter/linter/DAP tools, so these are not auto-installed:

- `bash` — on Windows only (`&shell` is forced to bash)
- `gcc`, `make`, `tree-sitter` — build toolchain, needed only at install time
- `node` + `prettier` — prettier; `node` also runs typescript-language-server
- `shfmt` — shell formatter
- `clang-format` — C/C++ formatter
- `rg` — telescope/fzf-lua live grep
- `fzf` — fzf-lua live grep (`<leader>fg`)
- `zoxide` — `<leader>cd` (telescope-zoxide)
- `gdb` — C/C++ DAP
- `curl` — minuet LLM HTTP requests

### 3. minuet LLM API key

`minuet` (AI completion) reads its config from `stdpath('data')/minuet.json`
(`:MinuetConfig` writes a starter template on first run). You must add the
`api_key` (literal key) or `api_key_env` (env var name). This is the one secret
that must come from you — it cannot be auto-installed.

### 4. Java (only if you work with Java)

- **Java >= 21 runtime** — via `$JAVA_HOME` or `java` on PATH.
- **jdtls install** — place at `$JDTLS_HOME`, or a `jdtls`/`jdtls.bat` shim
  on PATH, or a probed common dir. Not auto-installed by mason.
- **Lombok** (optional) — auto-discovered from Maven/Gradle caches; nothing to do.

The java-debug/java-test bundles for DAP + test running **are** auto-installed by
mason; without them the Java LSP still works but debugging/tests are disabled.

### 5. First-launch steps in nvim

1. `:Lazy` → wait for installs to finish.
2. `:TSUpdate` → install + compile treesitter parsers.
3. If `find_files`/`live_grep` feel slow on Windows, verify
   `<data>/lazy/telescope-fzf-native.nvim/build/libfzf.dll` exists, else run
   `:Lazy build telescope-fzf-native` (or `make` by hand in that directory).

## External dependencies

These must be findable on the PATH at runtime.

### Shell & build toolchain

| Binary        | Why                                                                            | When              |
| ------------- | ------------------------------------------------------------------------------ | ----------------- |
| `bash`        | Forced as `&shell` on Windows; runs `:!`, jobs, conform, LSP                   | always            |
| `git`         | lazy.nvim bootstrap + plugin clones                                            | install / updates |
| `gcc`         | compiler used by `tree-sitter` and `make` builds                               | install only      |
| `make`        | `telescope-fzf-native` build (`build = 'make'`)                                | install only      |
| `tree-sitter` | required by `nvim-treesitter`'s `ts.install(...)` to fetch and compile parsers | install only      |

`gcc`/`make`/`tree-sitter` are only needed at install time — not for normal editing.

### LSP servers

Configured in `lua/config/lsp/*.lua`. `clangd`, `lua_ls`, `ts_ls` use
`vim.lsp.config` + `vim.lsp.enable`; `jdtls` is started by the **`nvim-jdtls`**
plugin (`lua/plugins/jdtls.lua`).

| Binary                             | Languages | Notes                                                                                                                                                                                                                                                                       |
| ---------------------------------- | --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `clangd`                           | C / C++   | mason-managed (`ensure_installed`)                                                                                                                                                                                                                                          |
| `lua-language-server`              | Lua       | mason-managed (`ensure_installed`)                                                                                                                                                                                                                                          |
| `typescript-language-server[.cmd]` | JS / TS   | mason-managed; `.cmd` suffix on Windows; see `lua/config/lsp/typescript.lua`                                                                                                                                                                                                |
| `codebook-lsp[.cmd]`               | all       | spell checker for code; mason-managed (`codebook`); `.cmd` suffix on Windows; see `lua/config/lsp/codebook.lua`                                                                                                                                                              |
| `java` (>= 21) or `$JAVA_HOME`     | Java      | jdtls launcher (via nvim-jdtls); deferred — only starts on first `.java` file open                                                                                                                                                                                          |
| jdtls install                      | Java      | `$JDTLS_HOME`, or `jdtls`/`jdtls.bat` shim on PATH, or a probed common dir                                                                                                                                                                                                  |
| Lombok jar (optional)              | Java      | auto-discovered from Maven/Gradle caches                                                                                                                                                                                                                                    |
| java-debug `/` java-test bundles   | Java      | installed via **mason-tool-installer** (`java-debug-adapter`, `java-test` → `<data>/mason/share`), or manually at `<jdtls-home>/java-debug` + `<jdtls-home>/vscode-java-test`, `stdpath('cache')/java-debug`, or `~/.debug-plugins` — enables Java DAP + JUnit test running |

mason-tool-installer auto-installs `clangd`/`lua-language-server`/`typescript-language-server`/`codebook`
on first launch (see the mason note below); they're then available to nvim only.
Missing `jdtls`/`java` only warns on first `.java` open. Without the
java-debug/vscode-java-test bundles the Java LSP still works, but Java DAP and
test running are silently disabled.

### Formatters (conform.nvim)

Configured in `lua/config/conform.lua`. Triggered by `<leader>F` in normal mode.

| Binary         | Filetypes                                                      |
| -------------- | -------------------------------------------------------------- |
| `prettier`     | js, ts, jsx, tsx, json, jsonc, html, css, scss, yaml, markdown |
| `shfmt`        | sh, bash, zsh                                                  |
| `clang-format` | c, cpp, glsl                                                   |

`prettier` and `shfmt` are mason-tool-installer-managed (`ensure_installed`).
`prettier` implies `node` on PATH. `clang-format` is **not** mason-managed — it
must be on the PATH (from the clang toolchain); for C/C++ `<leader>F` shells out to
the `clang-format` binary rather than clangd's built-in formatter.

### Debugger (nvim-dap)

C / C++ via the `gdb` adapter (`--interpreter=dap`). Java via nvim-jdtls's
auto-registered `java` adapter (requires the java-debug `/` vscode-java-test
bundles — see the LSP table above); `:DapNew` discovers main classes and JUnit
tests. See `lua/config/dap.lua`.

| Binary | When                                    |
| ------ | --------------------------------------- |
| `gdb`  | only when launching a C/C++ DAP session |

### Other

| Binary   | Why                                       |
| -------- | ----------------------------------------- |
| `node`   | prettier + typescript-language-server     |
| `rg`     | telescope `live_grep`/`grep_string` + fzf-lua `live_grep` (reused, not re-spawned by fzf-lua) |
| `fzf`    | fzf-lua `live_grep` (`<leader>fg`); NOT a mason package — install it with your system package manager |
| `zoxide` | `<leader>cd` (telescope-zoxide extension) |

### mason.nvim + mason-tool-installer.nvim

`mason.nvim` (`lua/config/mason.lua`) only calls `setup({})` — it does NOT hold
`ensure_installed`. The auto-install list lives in
**mason-tool-installer.nvim** (`lua/config/mason-tool-installer.lua`, separate
`lazy = false` plugin), which installs `clangd`, `lua-language-server`,
`typescript-language-server`, `codebook`, `prettier`, `shfmt`, and the
`java-debug-adapter` / `java-test` bundles into `<data>/mason/` on startup
(`run_on_start = true`, `start_delay = 3000`). mason prepends
`<data>/mason/bin/` to `PATH` only inside Neovim-spawned jobs (LSPs, conform,
`:!`), so these binaries are available to nvim but **not** to a plain
shell or other editors. To use them outside nvim, install the system package
yourself and remove the entry from `ensure_installed`. `:Mason` lists installed
packages; `:MasonInstall <pkg>` / `:MasonUpdate` manage them. `fzf` is **not** a
mason package (mason only ships LSP/formatter/linter/DAP tools) — install it
with your system package manager.

## Post-install

1. Launch Neovim — lazy clones itself into `stdpath('data')/lazy/lazy.nvim`.
2. `:Lazy` → wait for installs to finish.
3. `:TSUpdate` — installs + compiles tree-sitter parsers (requires the `tree-sitter` CLI on PATH).
4. `:Lazy build telescope-fzf-native` — runs `make` (needs `gcc` + `make`). If find_files/live_grep feel slow and `<data>/lazy/telescope-fzf-native.nvim/build/libfzf.dll` is missing (the Windows build can silently no-op), run `make` by hand inside that plugin directory. Both `fzf` and `zoxide` are loaded as Telescope extensions.

## Keymaps & commands

Leader is space. The full reference lives in `lua/config/*.lua` and `init.lua`.

- `-` — Oil (open parent dir as buffer). `<leader>e` — Neo-tree toggle.
- `:GD [args]` `:GDF` `:GDH` — Diffview (open with args, current-file history, full repo history).
- `<leader>ff` `<leader>fo` `<leader>fg` `<leader>fr` `<leader>fd` `<leader>fi` `<leader>fb` `<leader>fh` `<leader>fc` — Telescope (files, oldfiles, live grep, LSP refs/defs/impls, buffers, help, colorscheme). `<leader>fg` (live grep) is routed to **fzf-lua** instead of telescope — it streams `rg` once and prunes on backspace instead of re-spawning per keystroke (avoids the telescope `live_grep` freeze on Windows). Requires the `fzf` binary on PATH (install with your system package manager). `<leader>cd` — zoxide.
- `<C-j>` / `<C-k>` — jump 10 lines (normal + visual). `<M-j>` / `<M-k>` — move line/block up/down with reindent. `<A-z>` — toggle word wrap. `<leader>o` / `<leader>i` — prev / next file in the jumplist. `<leader>;` — Snacks dashboard.
- `<leader>F` — format buffer (conform, `lsp_fallback = true`). `<F2>` — LSP rename. `[d` / `]d` — prev / next diagnostic. `<leader><space>` — LSP code action.
- `<F5>`/`<F6>`/`<F7>`/`<F8>`/`<F9>`/`<F10>` — DAP continue / step over / step into / step out / toggle breakpoint / restart. `<S-F5>` or `<F17>` — terminate. `<leader>dr` REPL, `<leader>du` dap-ui toggle, `<leader>ds` sessions sidebar. `:ClearBreakpoints`.
- `:LspLog` — open the LSP log. `:LspLogClear` — truncate the LSP log file. `:LspInfo` — show attached LSP clients as a table (name, pid, memory, buffers, root; resolved from the OS) in a scratch-buffer split. `:JdtlsCleanWorkspace` (then restart) — wipe jdtls's per-project cache when Java indexes go stale. `:DapNew` (Java) — auto-discover main classes / JUnit tests and debug them.

