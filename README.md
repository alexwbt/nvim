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

| Binary   | Why                                                          | When              |
|----------|--------------------------------------------------------------|-------------------|
| `bash`   | Forced as `&shell` on Windows; runs `:!`, jobs, conform, LSP  | always            |
| `git`    | lazy.nvim bootstrap + plugin clones                          | install / updates |
| `gcc`    | `telescope-fzf-native` build; treesitter parser compiles     | install only      |
| `make`   | `telescope-fzf-native` build (`build = 'make'`)              | install only      |

`gcc`/`make` are only needed at install time (`:Lazy build telescope-fzf-native`,
`:TSUpdate`) — not for normal editing.

### LSP servers

Configured in `lua/config/lsp/*.lua` via `vim.lsp.config` + `vim.lsp.enable`.

| Binary                            | Languages  | Notes                                                                       |
|-----------------------------------|------------|-----------------------------------------------------------------------------|
| `clangd`                          | C / C++    |                                                                             |
| `lua-language-server`             | Lua       |                                                                             |
| `typescript-language-server[.cmd]`| JS / TS   | `.cmd` suffix on Windows; see `lua/config/lsp/typescript.lua`              |
| `java` (>= 21) or `$JAVA_HOME`    | Java       | jdtls launcher; deferred — only starts on first `.java` file open           |
| jdtls install                      | Java       | `$JDTLS_HOME`, or `jdtls`/`jdtls.bat` shim on PATH, or a probed common dir  |
| Lombok jar (optional)             | Java       | auto-discovered from Maven/Gradle caches                                     |

Missing `clangd`/`lua-language-server`/`typescript-language-server` silently
no-ops that LSP. Missing `jdtls`/`java` only warns on first `.java` open.

### Formatters (conform.nvim)

Configured in `lua/config/conform.lua`. Triggered by `<A-F>` in normal mode.

| Binary     | Filetypes                                                        |
|------------|------------------------------------------------------------------|
| `prettier` | js, ts, jsx, tsx, json, jsonc, html, css, scss, yaml, markdown  |
| `shfmt`    | sh, bash, zsh                                                    |

`prettier` implies `node` on PATH.

### Debugger (nvim-dap)

C / C++ only, via the `gdb` adapter (`--interpreter=dap`). See `lua/config/dap.lua`.

| Binary | When                          |
|--------|-------------------------------|
| `gdb`  | only when launching a DAP session |

### Other

| Binary   | Why                                        |
|----------|--------------------------------------------|
| `node`   | prettier + typescript-language-server      |
| `zoxide` | `<leader>cd` (telescope-zoxide extension)   |

## Post-install

1. Launch Neovim — lazy clones itself into `stdpath('data')/lazy/lazy.nvim`.
2. `:Lazy` → wait for installs to finish.
3. `:TSUpdate` — builds tree-sitter parsers.
4. `:Lazy build telescope-fzf-native` — runs `make` (needs `gcc` + `make`).