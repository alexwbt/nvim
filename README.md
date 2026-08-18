# Neovim config

Neovim configuration managed by [lazy.nvim](https://github.com/folke/lazy.nvim).
See `AGENTS.md` for the full architecture / conventions write-up.

## Windows note

On Windows, `init.lua` forces `&shell = "bash"` with Unix-style flags, so every
external program (`:!`, conform, LSPs) is resolved against the bash PATH, not
`cmd.exe`/PowerShell. On Linux this is a no-op — the native shell/PATH apply.

## External dependencies

These must be findable on the PATH at runtime.

### Shell & build toolchain

| Binary        | Why                                                                       | When              |
|---------------|---------------------------------------------------------------------------|-------------------|
| `bash`        | Forced as `&shell` on Windows; runs `:!`, jobs, conform, LSP              | always            |
| `git`         | lazy.nvim bootstrap + plugin clones                                       | install / updates |
| `gcc`         | compiler used by `tree-sitter` and `make` builds                          | install only      |
| `make`        | `telescope-fzf-native` build (`build = 'make'`)                           | install only      |
| `tree-sitter` | required by `nvim-treesitter`'s `ts.install(...)` to fetch and compile parsers | install only   |

`gcc`/`make`/`tree-sitter` are only needed at install time — not for normal editing.

### LSP servers

Configured in `lua/config/lsp/*.lua`. `clangd`, `lua_ls`, `ts_ls` use
`vim.lsp.config` + `vim.lsp.enable`; `jdtls` is started by the **`nvim-jdtls`**
plugin (`lua/plugins/jdtls.lua`).

| Binary                            | Languages  | Notes                                                                       |
|-----------------------------------|------------|-----------------------------------------------------------------------------|
| `clangd`                          | C / C++    | mason-managed (`ensure_installed`)                                          |
| `lua-language-server`             | Lua        | mason-managed (`ensure_installed`)                                          |
| `typescript-language-server[.cmd]`| JS / TS   | mason-managed; `.cmd` suffix on Windows; see `lua/config/lsp/typescript.lua` |
| `java` (>= 21) or `$JAVA_HOME`    | Java       | jdtls launcher (via nvim-jdtls); deferred — only starts on first `.java` file open |
| jdtls install                      | Java       | `$JDTLS_HOME`, or `jdtls`/`jdtls.bat` shim on PATH, or a probed common dir  |
| Lombok jar (optional)             | Java       | auto-discovered from Maven/Gradle caches                                     |
| java-debug `/` java-test bundles | Java | installed via **mason.nvim** (`java-debug-adapter`, `java-test` → `<data>/mason/share`), or manually at `<jdtls-home>/java-debug` + `<jdtls-home>/vscode-java-test`, `stdpath('cache')/java-debug`, or `~/.debug-plugins` — enables Java DAP + JUnit test running |

mason auto-installs `clangd`/`lua-language-server`/`typescript-language-server`
on first launch (via `ensure_installed`); they're then available to nvim only
(see the mason note below). Missing `jdtls`/`java` only warns on first `.java`
open. Without the java-debug/vscode-java-test bundles the Java LSP still works,
but Java DAP and test running are silently disabled.

### Formatters (conform.nvim)

Configured in `lua/config/conform.lua`. Triggered by `<A-F>` in normal mode.

| Binary     | Filetypes                                                        |
|------------|------------------------------------------------------------------|
| `prettier` | js, ts, jsx, tsx, json, jsonc, html, css, scss, yaml, markdown  |
| `shfmt`    | sh, bash, zsh                                                    |

`prettier` and `shfmt` are mason-managed (`ensure_installed`). `prettier` implies
`node` on PATH.

### Debugger (nvim-dap)

C / C++ via the `gdb` adapter (`--interpreter=dap`). Java via nvim-jdtls's
auto-registered `java` adapter (requires the java-debug `/` vscode-java-test
bundles — see the LSP table above); `:DapNew` discovers main classes and JUnit
tests. See `lua/config/dap.lua`.

| Binary | When                          |
|--------|-------------------------------|
| `gdb`  | only when launching a C/C++ DAP session |

### Other

| Binary   | Why                                        |
|----------|--------------------------------------------|
| `node`   | prettier + typescript-language-server      |
| `zoxide` | `<leader>cd` (telescope-zoxide extension)   |

### mason.nvim

`clangd`, `lua-language-server`, `typescript-language-server`, `prettier`,
`shfmt`, and the `java-debug-adapter` / `java-test` bundles are installed via
**mason.nvim** (`ensure_installed` in `lua/config/mason.lua`) into
`<data>/mason/`. mason prepends `<data>/mason/bin/` to `PATH` only inside
Neovim-spawned jobs (LSPs, conform, `:!`), so these binaries are available to
nvim but **not** to a plain bash shell or other editors. To use them outside
nvim, install the system package (e.g. `pacman -S mingw-w64-x86_64-clangd`)
instead and remove the entry from `ensure_installed`. `:Mason` lists installed
packages; `:MasonInstall <pkg>` / `:MasonUpdate` manage them.

## Post-install

1. Launch Neovim — lazy clones itself into `stdpath('data')/lazy/lazy.nvim`.
2. `:Lazy` → wait for installs to finish.
3. `:TSUpdate` — installs + compiles tree-sitter parsers (requires the `tree-sitter` CLI on PATH).
4. `:Lazy build telescope-fzf-native` — runs `make` (needs `gcc` + `make`).

## Keymaps & commands

Leader is space. The full reference lives in `lua/config/*.lua` and `init.lua`.

- `-` — Oil (open parent dir as buffer). `<leader>e` — Neo-tree toggle.
- `<leader>ff` `<leader>fg` `<leader>fr` `<leader>fd` `<leader>fi` `<leader>fb` `<leader>fh` `<leader>fc` — Telescope (files, live grep, LSP refs/defs/impls, buffers, help, colorscheme). `<leader>cd` — zoxide.
- `<C-j>` / `<C-k>` — jump 10 lines (normal + visual). `<M-j>` / `<M-k>` — move line/block up/down with reindent.
- `<A-F>` — format buffer (conform, `lsp_fallback = true`). `<F2>` — LSP rename.
- `<F5>`/`<F6>`/`<F7>`/`<F8>`/`<F9>`/`<F10>` — DAP continue / step over / step into / step out / toggle breakpoint / restart. `<S-F5>` or `<F17>` — terminate. `<leader>dr` REPL, `<leader>du` dap-ui toggle.
- `:LspLog` — open the LSP log. `:LspLogClear` — truncate the LSP log file. `:LspInfo` — show attached LSP clients as a table (name, pid, memory, buffers, root; resolved from the OS). `:JdtlsCleanWorkspace` (then restart) — wipe jdtls's per-project cache when Java indexes go stale. `:DapNew` (Java) — auto-discover main classes / JUnit tests and debug them. `:SpellAllGood` — accept every misspelling suggestion.