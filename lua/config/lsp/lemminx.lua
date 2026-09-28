local jit = require("jit")

-- Maven-aware `pom.xml` support (go-to-definition on <parent>/GAV/properties).
--
-- The `lemminx` binary mason ships is GraalVM-native and CANNOT load the
-- `lemminx-maven` extension, so this launches the JVM lemminx bundle with the
-- extension already on the classpath (`lemminx-maven-<ver>-zip-with-dependencies.zip`
-- from the Eclipse repo, unzipped flat). Scoped to `pom.xml` only via `root_dir`,
-- so other XML files are unaffected. Additive to jdtls.

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

local home = find_home()
local java = find_java()
if home and java then
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
    -- Activate only for pom.xml; `on_dir` is deliberately not called otherwise.
    root_dir = function(bufnr, on_dir)
      if vim.api.nvim_buf_get_name(bufnr):match("[/\\]pom%.xml$") then
        on_dir(vim.fs.root(bufnr, { "pom.xml", ".git" }) or vim.fn.getcwd())
      end
    end,
  })
  vim.lsp.enable("lemminx-maven")
end
