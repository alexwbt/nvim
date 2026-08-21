local M = {}

local uv = vim.uv or vim.loop

-- Rolling window of char-count samples. samples[1] is the current (in-progress)
-- sample; older samples shift down toward sample_count.
local samples = { 0 }
local sample_count = 10
local sample_interval_ms = 2000
local percentile = 0.8
local timer = nil

local sparkline_chars = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }
local sparkline_factor = #sparkline_chars - 1

-- Persistence
local data_dir = vim.fn.stdpath("data") .. "/wpm"
local records_file = data_dir .. "/records.json"
local records = nil
local records_dirty = false
local flush_timer = nil

local function ensure_records_loaded()
  if records ~= nil then
    return
  end
  records = { best = 0, sessions = {}, lifetime_chars = 0, lifetime_ms = 0 }
  uv.fs_mkdir(data_dir, 493) -- 0o755
  local fd, err = uv.fs_open(records_file, "r", 438) -- 0o666
  if not fd or err then
    return
  end
  local stat = uv.fs_fstat(fd)
  if stat and stat.size > 0 then
    local data = uv.fs_read(fd, stat.size)
    if data then
      local ok, parsed = pcall(vim.json.decode, data)
      if ok and type(parsed) == "table" then
        records.best = tonumber(parsed.best) or 0
        records.sessions = type(parsed.sessions) == "table" and parsed.sessions or {}
        records.lifetime_chars = tonumber(parsed.lifetime_chars) or 0
        records.lifetime_ms = tonumber(parsed.lifetime_ms) or 0
      end
    end
  end
  uv.fs_close(fd)
end

local function persist_now()
  ensure_records_loaded()
  if not records then
    return
  end
  uv.fs_mkdir(data_dir, 493)
  local fd, err = uv.fs_open(records_file, "w", 438)
  if not fd or err then
    return
  end
  local ok, json = pcall(vim.json.encode, records)
  if ok and json then
    uv.fs_write(fd, json)
  end
  uv.fs_close(fd)
  records_dirty = false
end

local function schedule_persist()
  records_dirty = true
  if not flush_timer then
    flush_timer = uv.new_timer()
  end
  flush_timer:start(5000, 0, function()
    if records_dirty then
      vim.schedule(persist_now)
    end
  end)
end

local function character_press()
  samples[1] = samples[1] + 1
end

local function progress()
  for i = (sample_count + 1), 2, -1 do
    samples[i] = samples[i - 1]
  end
  samples[1] = 0
end

local function make_graph(values)
  local result = {}
  local max = 0
  for _, v in ipairs(values) do
    if v > max then
      max = v
    end
  end
  if max == 0 then
    max = 1
  end
  for _, v in ipairs(values) do
    local ci = 1 + math.floor((v / max) * sparkline_factor)
    if ci < 1 then
      ci = 1
    elseif ci > #sparkline_chars then
      ci = #sparkline_chars
    end
    result[#result + 1] = sparkline_chars[ci]
  end
  return table.concat(result)
end

function M.setup(options)
  options = options or {}
  sample_count = options.sample_count or 10
  sample_interval_ms = options.sample_interval or 2000
  percentile = options.percentile or 0.8

  samples = {}
  for _ = 1, (sample_count + 1) do
    samples[#samples + 1] = 0
  end
  samples[1] = 0

  if timer == nil then
    timer = uv.new_timer()
  end

  ensure_records_loaded()

  local active_tick = false
  local function on_progress()
    progress()
    if not records then
      return
    end
    if samples[2] and samples[2] > 0 then
      records.lifetime_ms = records.lifetime_ms + sample_interval_ms
      active_tick = true
      schedule_persist()
    elseif active_tick then
      records.lifetime_ms = records.lifetime_ms + sample_interval_ms
    end
  end

  local augroup = vim.api.nvim_create_augroup("plugin-wpm", { clear = true })
  vim.api.nvim_create_autocmd("InsertCharPre", {
    callback = function()
      character_press()
      if records then
        records.lifetime_chars = records.lifetime_chars + 1
      end
    end,
    group = augroup,
  })
  vim.api.nvim_create_autocmd("InsertEnter", {
    callback = function()
      active_tick = false
      timer:start(0, sample_interval_ms, vim.schedule_wrap(on_progress))
    end,
    group = augroup,
  })
  vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
      timer:stop()
      if not records then
        return
      end
      local cur = M.wpm()
      if cur > records.best then
        records.best = cur
        schedule_persist()
      end
    end,
    group = augroup,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if flush_timer then
        flush_timer:stop()
      end
      persist_now()
    end,
    group = augroup,
  })
end

function M.wpm_at_sample(index)
  local sample = samples[index] or 0
  local words = sample / 5
  local duration = sample_interval_ms / 60000
  return math.floor(words / duration)
end

function M.samples()
  local values = {}
  for i = 1, sample_count do
    values[#values + 1] = M.wpm_at_sample(i)
  end
  return values
end

function M.sorted_samples()
  local values = M.samples()
  table.sort(values)
  return values
end

function M.wpm()
  local values = M.sorted_samples()
  local idx = math.floor(sample_count * percentile)
  if idx < 1 then
    idx = 1
  end
  return values[idx] or 0
end

function M.sorted_graph()
  return make_graph(M.sorted_samples())
end

function M.historic_graph()
  return make_graph(M.samples())
end

function M.best()
  ensure_records_loaded()
  return (records and records.best) or 0
end

function M.lifetime_wpm()
  ensure_records_loaded()
  if not records or records.lifetime_ms <= 0 then
    return 0
  end
  return math.floor((records.lifetime_chars / 5) / (records.lifetime_ms / 60000))
end

function M.reset_records()
  records = { best = 0, sessions = {}, lifetime_chars = 0, lifetime_ms = 0 }
  persist_now()
end

return M