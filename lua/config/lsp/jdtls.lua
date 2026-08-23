local jit = require("jit")

-- nvim-jdtls (Eclipse Java LSP) configuration.
-- Discovers a jdtls install, a Java >= 21 runtime, and the java-debug /
-- java-test bundles without hardcoding machine-specific paths, then delegates
-- startup + DAP to `nvim-jdtls`.
--
-- NOTE: the plain `vim.lsp.config("jdtls")` / `vim.lsp.enable` path is NOT
-- used here — nvim-jdtls owns the client lifecycle and auto-registers the `java`
-- DAP adapter when nvim-dap is available.

-- Pick the first directory from `candidates` that contains `entry`.
local function find_dir(candidates, entry)
  for _, dir in ipairs(candidates) do
    local path = dir .. "/" .. entry
    if vim.uv.fs_stat(path) then return dir end
  end
end

-- Resolve the jdtls install root.
--   1. $JDTLS_HOME
--   2. parent of the `jdtls`/`jdtls.bat` shim on PATH
--   3. common install locations
local function find_jdtls_home()
  local env = os.getenv("JDTLS_HOME")
  if env and env ~= "" and vim.uv.fs_stat(env .. "/plugins") then return env end

  for _, name in ipairs({ "jdtls", "jdtls.bat" }) do
    local exe = vim.fn.exepath(name)
    if exe ~= "" then
      local bin = vim.fs.dirname(exe)
      local home = vim.fs.dirname(bin)
      if vim.uv.fs_stat(home .. "/plugins") then return home end
    end
  end

  local home_dirs = {
    vim.fn.stdpath("data") .. "/jdtls",
    vim.env.HOME .. "/opt/jdtls",
    "/opt/jdtls",
    "C:/msys64/opt/jdtls",
  }
  return find_dir(home_dirs, "plugins")
end

-- Find a Java runtime. Prefers $JAVA_HOME (jdtls needs >= 21), falls back to
-- `java` on PATH.
local function find_java()
  local env = os.getenv("JAVA_HOME")
  if env and env ~= "" then
    local exe = env .. "/bin/java" .. (jit.os == "Windows" and ".exe" or "")
    if vim.fn.executable(exe) == 1 then return exe end
  end
  if vim.fn.executable("java") == 1 then return "java" end
end

-- OS-specific shared config dir under the jdtls install.
local function config_subdir()
  if jit.os == "Windows" then return "config_win" end
  if jit.os == "OSX" then return "config_mac" end
  return "config_linux"
end

-- Parse "x.y.z" into a comparable integer.
local function vnum(v)
  local a, b, c = v:match("(%d+)%.(%d+)%.(%d+)")
  return a and tonumber(a) * 10000 + tonumber(b) * 100 + tonumber(c) or 0
end

-- Find the newest Lombok jar across common local caches (Maven, Gradle).
local function find_lombok()
  local home = os.getenv("HOME") or vim.env.HOME or ""
  local userprofile = os.getenv("USERPROFILE") or ""
  local gradle_home = os.getenv("GRADLE_USER_HOME") or (home .. "/.gradle")
  local roots = {
    (os.getenv("M2_HOME") or "") .. "/repository/org/projectlombok/lombok",
    home .. "/.m2/repository/org/projectlombok/lombok",
    userprofile ~= "" and userprofile .. "/.m2/repository/org/projectlombok/lombok" or "",
    gradle_home .. "/caches/modules-2/files-2.1/org.projectlombok/lombok",
  }
  local jars = {}
  for _, root in ipairs(roots) do
    if root ~= "" and vim.uv.fs_stat(root) then
      for _, jar in ipairs(vim.fn.glob(root .. "/*/lombok-*.jar", false, true)) do
        if not jar:match("-sources%.jar$") then jars[#jars + 1] = jar end
      end
    end
  end
  table.sort(jars, function(a, b)
    local va = a:match("lombok/(%d+%.%d+%.%d+)") or ""
    local vb = b:match("lombok/(%d+%.%d+%.%d+)") or ""
    return vnum(va) < vnum(vb)
  end)
  return jars[#jars]
end

-- Per-project workspace data dir so multiple projects don't clobber each other.
local function data_dir()
  local cwd = vim.fn.getcwd()
  local hash = vim.fn.sha256(vim.fs.basename(cwd) .. cwd)
  return vim.fn.stdpath("cache") .. "/jdtls/workspace/" .. hash
end

-- Roots used to define a Java project (matching the previous `root_markers`).
local ROOT_MARKERS = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", "settings.gradle" }

-- Find the java-debug bundle jar, optionally alongside the java-test bundles.
-- Returns `nil` when the debug server isn't installed (debugging + test running
-- then stay disabled). Searched:
--   1. <jdtls-home>/java-debug (and <jdtls-home>/vscode-java-test)
--   2. stdpath('cache')/java-debug (and .../vscode-java-test)
--   3. ~/.debug-plugins
--   4. mason-managed: <data>/mason/share/java-debug-adapter (and .../java-test)
local function find_debug_bundles()
  local jdtls_home = find_jdtls_home()
  local home = os.getenv("HOME") or vim.env.HOME or ""
  local mason = vim.env.MASON or (vim.fn.stdpath("data") .. "/mason")
  local bases = {
    jdtls_home and (jdtls_home .. "/java-debug") or nil,
    jdtls_home and (jdtls_home .. "/vscode-java-test") or nil,
    vim.fn.stdpath("cache") .. "/java-debug",
    vim.fn.stdpath("cache") .. "/vscode-java-test",
    home .. "/.debug-plugins",
    mason .. "/share/java-debug-adapter",
    mason .. "/share/java-test",
  }
  local bundles = {}
  local seen = {}
  local add_dir = function(dir)
    if not dir or not vim.uv.fs_stat(dir) then return end
    for _, jar in ipairs(vim.fn.glob(dir .. "/com.microsoft.java.debug.plugin-*.jar", false, true)) do
      if not seen[jar] then
        bundles[#bundles + 1] = jar
        seen[jar] = true
      end
    end
    -- java-test: several jars under `server/` (manual layout) or literally in the
    -- dir (mason `share/java-test`), excluding the non-bundle test-runner +
    -- jacoco agent.
    local excluded = {
      ["com.microsoft.java.test.runner-jar-with-dependencies.jar"] = true,
      ["com.microsoft.java.test.runner.jar"] = true,
      ["jacocoagent.jar"] = true,
    }
    local server = dir .. "/server"
    if vim.uv.fs_stat(server) then
      for _, jar in ipairs(vim.fn.glob(server .. "/*.jar", false, true)) do
        local fname = vim.fn.fnamemodify(jar, ":t")
        if not excluded[fname] and not seen[jar] then
          bundles[#bundles + 1] = jar
          seen[jar] = true
        end
      end
    end
    for _, jar in ipairs(vim.fn.glob(dir .. "/*.jar", false, true)) do
      local fname = vim.fn.fnamemodify(jar, ":t")
      if not excluded[fname] and not seen[jar] then
        bundles[#bundles + 1] = jar
        seen[jar] = true
      end
    end
  end
  for _, base in ipairs(bases) do add_dir(base) end
  if #bundles == 0 then return nil end
  return bundles
end

-- Wipe jdtls's per-project workspace cache when it goes stale.
vim.api.nvim_create_user_command("JdtlsCleanWorkspace", function()
  local dir = data_dir()
  if vim.uv.fs_stat(dir) then
    vim.fn.delete(dir, "rf")
    vim.notify("jdtls: removed workspace cache " .. dir, vim.log.levels.INFO)
  else
    vim.notify("jdtls: no workspace cache at " .. dir, vim.log.levels.INFO)
  end
end, { desc = "Delete jdtls per-project workspace cache" })

-- Deferred start: only boot jdtls (and require nvim-jdtls) once a Java buffer
-- opens. Fires on every `FileType java`; nvim-jdtls's start_or_attach is
-- idempotent per buffer (skips already-attached buffers, and starts a separate
-- server when the module/root_dir differs), keeping startup cheap for non-Java work.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    local ok, jdtls = pcall(require, "jdtls")
    if not ok then
      vim.notify("jdtls: nvim-jdtls not installed — run :Lazy", vim.log.levels.WARN)
      return
    end

    local jdtls_home = find_jdtls_home()
    local java = find_java()
    if not jdtls_home or not java then
      vim.notify(
        "jdtls: not configured — "
          .. (not jdtls_home and "jdtls install not found (set $JDTLS_HOME)" or "")
          .. (not jdtls_home and not java and "; " or "")
          .. (not java and "java runtime not found (set $JAVA_HOME)" or ""),
        vim.log.levels.WARN)
      return
    end

    local plugins = jdtls_home .. "/plugins"
    local launcher = vim.fn.glob(plugins .. "/org.eclipse.equinox.launcher_*.jar", false, true)[1]
      or (plugins .. "/org.eclipse.equinox.launcher.jar")
    local config_dir = jdtls_home .. "/" .. config_subdir()
    local lombok = find_lombok()
    -- java-debug (+ java-test) bundles; nil => DAP/test disabled.
    local bundles = find_debug_bundles()

    local cmd = {
      java,
      "-Declipse.application=org.eclipse.jdt.ls.core.id1",
      "-Dosgi.bundles.defaultStartLevel=4",
      "-Declipse.product=org.eclipse.jdt.ls.core.product",
      "-Dosgi.checkConfiguration=true",
      "-Dosgi.sharedConfiguration.area=" .. config_dir,
      "-Dosgi.sharedConfiguration.area.readOnly=true",
      "-Dosgi.configuration.cascaded=true",
      "-Xms1G",
      "--add-modules=ALL-SYSTEM",
      "--add-opens", "java.base/java.util=ALL-UNNAMED",
      "--add-opens", "java.base/java.lang=ALL-UNNAMED",
    }
    if lombok then
      table.insert(cmd, 2, "-javaagent:" .. lombok)
    end
    vim.list_extend(cmd, { "-jar", launcher, "-data", data_dir() })

    local root = vim.fs.root(0, ROOT_MARKERS) or vim.fn.getcwd()

    -- Formatter settings file (Eclipse XML). Resolved per project, in priority
    -- order:
    --   1. vim.g.jdtls_formatter  — set from a repo's .nvim/init.lua (project override)
    --   2. $JDTLS_FORMATTER env var
    --   3. <root>/jdt-formatter.xml next to the project root
    -- Falls back to jdtls defaults (url = vim.NIL).
    local formatter_uri = (function()
      local function to_uri(p)
        if p:match("^file:") then return p end
        return "file:///" .. p:gsub("\\", "/"):gsub("^/", "")
      end
      local g = vim.g.jdtls_formatter
      if g and g ~= "" then return to_uri(g) end
      local env = os.getenv("JDTLS_FORMATTER")
      if env and env ~= "" then return to_uri(env) end
      local p = root .. "/jdt-formatter.xml"
      if vim.uv.fs_stat(p) then return to_uri(p) end
    end)()

    -- JDT compiler preferences file (Eclipse .prefs). Resolved per project, in
    -- priority order:
    --   1. vim.g.jdtls_settings  -- set from a repo's .nvim/init.lua (project override)
    --   2. $JDTLS_SETTINGS env var
    --   3. <root>/.jdt-settings/org.eclipse.jdt.core.prefs next to the project root
    -- Falls back to jdtls defaults (url = vim.NIL). A subset of the JDT
    -- compiler preferences can be set here, e.g.
    --   org.eclipse.jdt.core.compiler.problem.unusedPrivateMember=warning
    local settings_uri = (function()
      local function to_uri(p)
        if p:match("^file:") then return p end
        return "file:///" .. p:gsub("\\", "/"):gsub("^/", "")
      end
      local g = vim.g.jdtls_settings
      if g and g ~= "" then return to_uri(g) end
      local env = os.getenv("JDTLS_SETTINGS")
      if env and env ~= "" then return to_uri(env) end
      local p = root .. "/.jdt-settings/org.eclipse.jdt.core.prefs"
      if vim.uv.fs_stat(p) then return to_uri(p) end
    end)()

    -- Expose whether the java-debug bundle was found.
    vim.g.jdtls_debug_bundles = bundles ~= nil
    -- A minimal F5-able java launch config. nvim-jdtls auto-registers the
    -- `java` adapter and `:DapNew` discovers main classes / JUnit tests, so
    -- only the fallback config is added here.
    if bundles then
      local ok_dap, dap = pcall(require, "dap")
      if ok_dap and not dap.configurations.java then
        dap.configurations.java = {
          {
            type = "java",
            request = "launch",
            name = "Debug (Attach) - Current File",
            mainClass = "${workspaceFolder}/unknown",
            projectName = vim.fs.basename(root),
          },
        }
      end
    end

    local config = {
      cmd = cmd,
      -- java-debug / java-test bundles loaded by jdtls; enables DAP + tests.
      init_options = {
        bundles = bundles or vim.empty_dict(),
      },
      settings = {
        java = {
          -- Compiler preferences (Eclipse .prefs file, `java.settings.url`).
          settings = {
            url = settings_uri or vim.NIL,
          },
          configuration = {
            maven = { notCoveredPluginExecutionSeverity = "ignore" },
          },
          compile = {
            nullAnalysis = {
              mode = "automatic",
            },
          },
          format = {
            settings = {
              -- Use a per-project Eclipse XML formatter if present, otherwise
              -- fall back to jdtls defaults. `url` accepts a `file:` URI and is
              -- the standard jdtls key used by VS Code.
              url = formatter_uri or vim.NIL,
            },
          },
          -- Build with ./mvnw (which honours the pom's maven.compiler.release,
          -- here Java 21) instead of jdtls's embedded JDT compiler, which can
          -- compile to a different (newer) class file version and then fail to load
          -- on the Java-21 runtime jdtls launches with. Run :Mvn* / ./mvnw yourself.
          autobuild = { enabled = false },
          debug = {
            settings = {
              forceBuildBeforeLaunch = false,
            },
          },
        },
      },
      root_dir = root,
      project_name = vim.fs.basename(root),
    }

    -- Always register the extra `:Jdt*` commands. nvim-jdtls auto-registers
    -- the `java` DAP adapter when nvim-dap is present, so only the launch
    -- config (in config/dap.lua) is missing.
    if bundles then pcall(jdtls.setup.add_commands) end

    jdtls.start_or_attach(config)

    -- Extend <A-F> for java buffers: run jdtls's custom `java/organizeImports`
    -- request, then format (conform with lsp_fallback) in the callback so the
    -- format sees the already-reorganized imports. jdtls exposes import
    -- optimization as a custom request (not the standard `source.organizeImports`
    -- code action) — see `java_action_organize_imports` in nvim-jdtls.
    vim.keymap.set("n", "<A-F>", function()
      local clients = vim.lsp.get_clients({ bufnr = 0, name = "jdtls" })
      local client = clients[1]
      if not client then
        require("conform").format({ async = true, lsp_fallback = true })
        return
      end
      local params = vim.lsp.util.make_range_params()
      params.context = { diagnostics = {} }
      client:request("java/organizeImports", params, function(err, resp)
        if not err and resp then
          vim.lsp.util.apply_workspace_edit(resp, client.offset_encoding or "utf-8")
        end
        require("conform").format({ async = true, lsp_fallback = true })
      end)
    end, { buffer = 0, desc = "Format buffer (organize imports + format)" })
  end,
})
