-- Dynamic jdtls (Eclipse Java LSP) configuration.
-- Discovers the jdtls install, a Java >= 21 runtime, and the Lombok agent
-- without hardcoding any machine-specific paths.

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

  -- Resolve via the PATH shim (works for both `jdtls` and `jdtls.bat`).
  for _, name in ipairs({ "jdtls", "jdtls.bat" }) do
    local exe = vim.fn.exepath(name)
    if exe ~= "" then
      -- shim lives in <home>/bin, install root is <home>
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

local jdtls_home = find_jdtls_home()
local java = find_java()

-- Build the jdtls launch command. Runs the first time a `.java` file opens,
-- not at startup — keeps `require("config.jdtls")` cheap when no Java is used.
local configured = false
local function setup()
  if configured then return end
  if not jdtls_home or not java then
    vim.notify(
      "jdtls: not configured — "
        .. (not jdtls_home and "jdtls install not found (set $JDTLS_HOME)" or "")
        .. (not jdtls_home and not java and "; " or "")
        .. (not java and "java runtime not found (set $JAVA_HOME)" or ""),
      vim.log.levels.WARN)
    configured = true
    return
  end

  local plugins = jdtls_home .. "/plugins"
  local launcher = vim.fn.glob(plugins .. "/org.eclipse.equinox.launcher_*.jar", false, true)[1]
    or (plugins .. "/org.eclipse.equinox.launcher.jar")
  local config_dir = jdtls_home .. "/" .. config_subdir()
  local lombok = find_lombok()

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

  -- jdtls bundles APT support (org.eclipse.jdt.apt.core, org.eclipse.m2e.apt.core)
  -- so MapStruct's annotation processor runs automatically once the project's
  -- pom.xml/build.gradle declares the annotationProcessorPath.
  vim.lsp.config("jdtls", {
    cmd = cmd,
    filetypes = { "java" },
    root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", "settings.gradle" },
    settings = {
      java = {
        configuration = {
          maven = { notCoveredPluginExecutionSeverity = "ignore" },
        },
      },
    },
  })
  vim.lsp.enable("jdtls")
  configured = true
end

-- Defer discovery + enable to the first time a Java buffer is opened. One-shot
-- autocmd — fires on the first matching FileType, then removes itself.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  once = true,
  callback = setup,
})