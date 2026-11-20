-- Symmetric (passphrase) GPG editor for *.gpg / *.asc / *.pgp.
--
-- Replaces benoror/gpg.nvim, which always re-encrypted with
-- `--default-recipient-self -ae` (asymmetric) and looped forever on
-- "Enter the user ID" when no key existed, freezing Neovim.
--
-- Reading and writing go straight through gpg (BufReadCmd/BufWriteCmd), so the
-- buffer only ever holds plaintext and no plaintext can reach the file, swap,
-- undo or backup files. Every gpg call is --batch with a timeout, so a missing
-- key or a wrong passphrase surfaces as an error instead of a hang.
--
-- Owning a key is not required: a new file is encrypted symmetrically on save
-- (passphrase asked twice). Files that were encrypted to a key are re-encrypted
-- to --default-recipient-self, preserving the old gpg.nvim behaviour.
--
-- Wired up by `lua/config/gpg.lua` (see the GPG section in AGENTS.md).

local M = {}

local defaults = {
  patterns = { "*.gpg", "*.asc", "*.pgp" },
  timeout_ms = 60000,
}

local opts = vim.deepcopy(defaults)

local function notify(msg, level)
  vim.notify("gpg: " .. msg, level or vim.log.levels.INFO)
end

-- Run gpg synchronously. Returns nil on spawn failure/timeout.
local function gpg(args, stdin)
  local ok, obj = pcall(vim.system, args, { stdin = stdin, text = true })
  if not ok then
    return nil, tostring(obj)
  end
  local result = obj:wait(opts.timeout_ms)
  if not result then
    return nil, "timed out"
  end
  if result.code == 124 or result.signal == 9 then
    return nil, "timed out after " .. opts.timeout_ms .. "ms"
  end
  return result
end

local function first_line(text)
  return vim.trim((text or ""):match("^[^\n]*") or "")
end

local function needs_passphrase(stderr)
  local s = (stderr or ""):lower()
  return s:find("can't get input", 1, true)
    or s:find("no passphrase", 1, true)
    or s:find("bad passphrase", 1, true)
    or s:find("bad session key", 1, true)
    or s:find("passphrase", 1, true)
    or s:find("pinentry", 1, true)
end

local function not_openpgp(stderr)
  local s = (stderr or ""):lower()
  return s:find("no valid openpgp data", 1, true)
    or s:find("decrypt_message failed", 1, true)
end

local function ask(prompt)
  local ok, value = pcall(vim.fn.inputsecret, prompt)
  if not ok or value == nil or value == "" then
    return nil
  end
  return value
end

local function encryption_mode(stderr)
  local s = stderr or ""
  if s:find("encrypted with %d+ passphrase") then
    return "symmetric"
  end
  if s:find("encrypted with", 1, true) then
    return "asymmetric"
  end
end

-- Decrypt `path`, asking for the passphrase only when gpg needs one.
-- Returns { text, mode, pass } or { err } / { cancelled }.
local function decrypt(path, cached)
  local result, err = gpg({ "gpg", "--batch", "--yes", "--pinentry-mode", "loopback", "--decrypt", "--", path })
  if not result then
    return { err = err }
  end

  if result.code == 0 then
    return { text = result.stdout or "", mode = encryption_mode(result.stderr) or "symmetric" }
  end

  if not needs_passphrase(result.stderr) then
    return { err = result.stderr }
  end

  -- Reuse the passphrase already typed for this buffer (e.g. after :e!).
  if cached then
    local reuse = gpg({
      "gpg", "--batch", "--yes", "--pinentry-mode", "loopback",
      "--passphrase-fd", "0", "--decrypt", "--", path,
    }, cached .. "\n")
    if reuse and reuse.code == 0 then
      return { text = reuse.stdout or "", mode = encryption_mode(reuse.stderr) or "symmetric", pass = cached }
    end
  end

  for attempt = 1, 3 do
    local pass = ask(attempt == 1 and "GPG passphrase: " or "GPG passphrase (again): ")
    if not pass then
      return { cancelled = true }
    end
    local retry, retry_err = gpg({
      "gpg", "--batch", "--yes", "--pinentry-mode", "loopback",
      "--passphrase-fd", "0", "--decrypt", "--", path,
    }, pass .. "\n")
    if not retry then
      return { err = retry_err }
    end
    if retry.code == 0 then
      return { text = retry.stdout or "", mode = encryption_mode(retry.stderr) or "symmetric", pass = pass }
    end
    if not needs_passphrase(retry.stderr) then
      return { err = retry.stderr }
    end
    notify("bad passphrase", vim.log.levels.WARN)
  end

  return { cancelled = true }
end

-- Ask for the passphrase of an existing file and make sure it actually works
-- before it is used for encryption (a wrong passphrase would silently produce
-- an unreadable file).
local function ask_verified(path)
  for attempt = 1, 3 do
    local pass = ask(attempt == 1 and "GPG passphrase: " or "GPG passphrase (again): ")
    if not pass then
      return nil
    end
    local result = gpg({
      "gpg", "--batch", "--yes", "--pinentry-mode", "loopback",
      "--passphrase-fd", "0", "--decrypt", "--", path,
    }, pass .. "\n")
    if result and result.code == 0 then
      return pass
    end
    notify("bad passphrase", vim.log.levels.WARN)
  end
  return nil
end

-- gpg can only take the passphrase from stdin (`--passphrase-fd 0`, used for
-- decrypt) or from a file; encryption needs stdin for the plaintext, so use a
-- short-lived 0600 file inside the (user-private) nvim cache directory.
local function write_passphrase_file(pass)
  local dir = vim.fs.joinpath(vim.fn.stdpath("cache"), "gpg")
  local ok = pcall(vim.fn.mkdir, dir, "p")
  if not ok then
    return nil, "cannot create " .. dir
  end
  local path = vim.fs.joinpath(dir, string.format("%d-%d.pass", vim.uv.os_getpid(), math.random(1, 1000000000)))
  local fd, err = vim.uv.fs_open(path, "wx", 384) -- 0600
  if not fd then
    return nil, err
  end
  vim.uv.fs_write(fd, pass .. "\n", 0)
  vim.uv.fs_close(fd)
  return path
end

local function read(buf, path)
  vim.bo[buf].swapfile = false
  vim.bo[buf].undofile = false

  local b = vim.b[buf]
  local cached = b.gpg_passphrase
  b.gpg_state = nil
  b.gpg_new = nil
  vim.bo[buf].modifiable = true

  local stat = vim.uv.fs_stat(path)
  if not stat or stat.size == 0 then
    b.gpg_state = "symmetric"
    b.gpg_new = true
    vim.bo[buf].filetype = "gpg"
    return
  end

  local res = decrypt(path, cached)

  if res.err and not_openpgp(res.err) then
    -- Not an OpenPGP file (plain text, truncated, ...). Show it as-is and write
    -- it back untouched so nothing is lost by merely opening it.
    local ok, raw = pcall(vim.fn.readfile, path, "b")
    if ok then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, raw)
      vim.bo[buf].modified = false
      b.gpg_state = "plain"
      b.gpg_passphrase = nil
      notify("not an OpenPGP file, saving writes it back unencrypted", vim.log.levels.WARN)
    else
      b.gpg_state = "locked"
      b.gpg_passphrase = nil
      vim.bo[buf].modifiable = false
      notify("cannot read file: " .. tostring(raw), vim.log.levels.ERROR)
    end
  elseif res.err or res.cancelled then
    -- Never leave an empty, writable buffer behind: saving it would destroy
    -- the encrypted file.
    b.gpg_state = "locked"
    b.gpg_passphrase = nil
    vim.bo[buf].modifiable = false
    if res.err then
      notify("decryption failed: " .. first_line(res.err), vim.log.levels.ERROR)
    else
      notify("decryption cancelled, buffer is read-only (:e! to retry)", vim.log.levels.WARN)
    end
  else
    local lines = vim.split(res.text or "", "\n", { plain = true })
    if lines[#lines] == "" then
      table.remove(lines)
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modified = false
    b.gpg_state = res.mode or "symmetric"
    b.gpg_passphrase = res.pass or cached
    b.gpg_new = false
  end

  vim.bo[buf].filetype = "gpg"
end

local function write(buf, path)
  local b = vim.b[buf]
  local state = b.gpg_state or "symmetric"

  if state == "locked" then
    notify("cannot write: file was not decrypted (:e! to retry)", vim.log.levels.ERROR)
    return false
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if #lines == 1 and lines[1] == "" then
    lines = {}
  end

  if state == "plain" then
    local ok, err = pcall(vim.fn.writefile, lines, path, "b")
    if not ok then
      notify("write failed: " .. tostring(err), vim.log.levels.ERROR)
      return false
    end
    return true
  end

  local stat = vim.uv.fs_stat(path)
  local new = b.gpg_new or stat == nil or stat.size == 0
  local text = #lines == 0 and "" or table.concat(lines, "\n") .. "\n"
  local result, err

  if state == "asymmetric" then
    notify("file is key-encrypted, re-encrypting to your default key", vim.log.levels.WARN)
    result, err = gpg({
      "gpg", "--batch", "--yes", "--pinentry-mode", "loopback",
      "--output", path, "--encrypt", "--armor", "--default-recipient-self",
    }, text)
    if not result or result.code ~= 0 then
      notify("encrypt failed: " .. first_line((result and result.stderr) or err), vim.log.levels.ERROR)
      return false
    end
    return true
  end

  local pass = b.gpg_passphrase
  if not pass then
    if new then
      pass = ask("New GPG passphrase: ")
      if not pass then
        notify("write cancelled (no passphrase)", vim.log.levels.WARN)
        return false
      end
      if ask("Confirm GPG passphrase: ") ~= pass then
        notify("passphrases do not match, not written", vim.log.levels.ERROR)
        return false
      end
    else
      pass = ask_verified(path)
      if not pass then
        notify("write cancelled (no valid passphrase)", vim.log.levels.WARN)
        return false
      end
    end
    b.gpg_passphrase = pass
  end

  local passfile, perr = write_passphrase_file(pass)
  if not passfile then
    notify("cannot create passphrase file: " .. tostring(perr), vim.log.levels.ERROR)
    return false
  end

  local args = {
    "gpg", "--batch", "--yes", "--pinentry-mode", "loopback",
    "--passphrase-file", passfile, "--output", path, "--symmetric",
  }
  if path:lower():match("%.asc$") then
    args[#args + 1] = "--armor"
  end
  result, err = gpg(args, text)
  vim.uv.fs_unlink(passfile)

  if not result or result.code ~= 0 then
    notify("encrypt failed: " .. first_line((result and result.stderr) or err), vim.log.levels.ERROR)
    return false
  end
  b.gpg_new = false
  return true
end

function M.setup(user_opts)
  opts = vim.tbl_deep_extend("force", vim.deepcopy(defaults), user_opts or {})

  local group = vim.api.nvim_create_augroup("config_gpg", { clear = true })

  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = group,
    pattern = opts.patterns,
    callback = function(args)
      read(args.buf, vim.api.nvim_buf_get_name(args.buf))
    end,
  })

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    group = group,
    pattern = opts.patterns,
    callback = function(args)
      local buf = args.buf
      local path = vim.fn.fnamemodify(args.match, ":p")
      if not write(buf, path) then
        return
      end
      vim.bo[buf].modified = false
      local stat = vim.uv.fs_stat(path)
      vim.api.nvim_echo({
        {
          string.format(
            '"%s" %dL, %dB written',
            vim.fn.fnamemodify(path, ":~:."),
            vim.api.nvim_buf_line_count(buf),
            stat and stat.size or 0
          ),
          "Normal",
        },
      }, true, {})
    end,
  })

  -- Catch buffers that never went through BufReadCmd (:enew + :file, sessions...).
  vim.api.nvim_create_autocmd({ "BufNew", "BufEnter" }, {
    group = group,
    pattern = opts.patterns,
    callback = function(args)
      vim.bo[args.buf].swapfile = false
      vim.bo[args.buf].undofile = false
    end,
  })
end

return M
