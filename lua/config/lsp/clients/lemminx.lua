local jit = require("jit")

-- Maven-aware `pom.xml` support (go-to-definition on <parent>/GAV/properties).
--
-- The `lemminx` binary mason ships is GraalVM-native and CANNOT load the
-- `lemminx-maven` extension, so this launches the JVM lemminx bundle with the
-- extension already on the classpath (`lemminx-maven-<ver>-vscode-uber-jars.zip`
-- from the Eclipse repo, unzipped flat). Scoped via `root_dir` to files whose
-- name lemminx-maven accepts as a POM (`pom*.xml`/`*pom.xml`/`*.pom`), so other
-- XML files are unaffected. Additive to jdtls.

-- Resolve the unzipped bundle dir: $LEMMINX_MAVEN_HOME, then common locations.
local function find_home()
  local env = os.getenv("LEMMINX_MAVEN_HOME")
  if env and env ~= "" and vim.uv.fs_stat(env) then return env end
  for _, dir in ipairs({
    vim.fn.stdpath("data") .. "/lemminx-maven",
    vim.env.HOME .. "/lemminx-maven",
  }) do
    if vim.uv.fs_stat(dir) then return dir end
  end
end

-- Reuse the same Java runtime discovery as jdtls ($JAVA_HOME, then PATH).
local function find_java()
  local env = os.getenv("JAVA_HOME")
  if env and env ~= "" then
    local exe = env .. "/bin/java" .. (jit.os == "Windows" and ".exe" or "")
    if vim.fn.executable(exe) == 1 then return exe end
  end
  if vim.fn.executable("java") == 1 then return "java" end
end

-- Attach only to the files lemminx-maven itself treats as POMs. These rules
-- mirror `MavenLemminxExtension.match` (hardcoded — `pom*.xml`, `*pom.xml`, or
-- `*.pom`); anything else (e.g. `.pom/checkstyle.xml`) is left alone.
local function is_pom(bufnr)
  local base = vim.fs.basename(vim.api.nvim_buf_get_name(bufnr))
  return base:match("^pom.*%.xml$") ~= nil or base:match("pom%.xml$") ~= nil or base:match("%.pom$") ~= nil
end

local home = find_home()
local java = find_java()
if home and java then
  -- The `zip-with-dependencies` bundle omits guava, which makes lemminx throw
  -- NoClassDefFoundError: com/google/common/cache/CacheBuilder (breaking Maven
  -- resolution). The `vscode-uber-jars` bundle includes it.
  if #vim.fn.glob(home .. "/guava-*.jar", false, true) == 0 then
    vim.notify(
      "lemminx-maven: no guava-*.jar in " .. home
        .. " — go-to-definition on pom.xml will fail (incomplete bundle). See README section 5.",
      vim.log.levels.WARN)
  end
  vim.lsp.config("lemminx-maven", {
    -- `dir/*` is expanded by the JVM itself (no shell needed, works on Windows).
    cmd = { java, "-cp", home .. "/*", "org.eclipse.lemminx.XMLServerLauncher" },
    filetypes = { "xml" },
    init_options = {
      settings = {
        xml = {
          -- .m2-only: skip the Maven Central index (fast/offline). Remove this
          -- block to enable remote GAV completion.
          maven = { central = { skip = true } },
        },
      },
    },
    -- Activate only for POM-named files; `on_dir` is deliberately not called
    -- otherwise. Root markers mirror jdtls (`.git`/wrapper before `pom.xml`) and
    -- order matters: `vim.fs.root` returns the root for the FIRST marker that
    -- matches anywhere upward. Listing `pom.xml` first would resolve a nested
    -- `<reactor>/<module>/pom.xml` to `<module>`, spawning one lemminx server per
    -- module; `.git` first collapses every module onto the reactor/repo root so
    -- cross-module + parent resolution shares a single workspace.
    root_dir = function(bufnr, on_dir)
      if is_pom(bufnr) then
        on_dir(vim.fs.root(bufnr, { ".git", "mvnw", "mvnw.cmd", ".mvn", "pom.xml" }) or vim.fn.getcwd())
      end
    end,
  })
  vim.lsp.enable("lemminx-maven")
end
