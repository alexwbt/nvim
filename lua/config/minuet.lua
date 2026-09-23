local data_dir = vim.fn.stdpath("data")
local json_path = data_dir .. "/minuet.json"

local STARTER_LINES = {
  "{",
  "  \"provider\": \"openai_compatible\",",
  "  \"request_timeout\": 30,",
  "  \"provider_options\": {",
  "    \"openai_compatible\": {",
  "      \"api_key\": \"sk-your-key-here\",",
  "      \"end_point\": \"https://api.openai.com/v1/chat/completions\",",
  "      \"model\": \"gpt-4o-mini\",",
  "      \"name\": \"OpenAI\",",
  "      \"optional\": {",
  "        \"reasoning_effort\": \"none\"",
  "      }",
  "    }",
  "  }",
  "}",
}

local function wrap_api_keys(config)
  if type(config) ~= "table" then
    return config
  end
  if config.api_key_env and type(config.api_key_env) == "string" and config.api_key == nil then
    local var = config.api_key_env
    config.api_key = function()
      return os.getenv(var) or ""
    end
    config.api_key_env = nil
  end
  for k, v in pairs(config) do
    if k == "api_key" and type(v) == "string" then
      local literal = v
      config.api_key = function()
        return literal
      end
    elseif type(v) == "table" then
      wrap_api_keys(v)
    end
  end
end

local function read_json()
  vim.fn.mkdir(data_dir, "p")
  if vim.fn.filereadable(json_path) ~= 1 then
    return nil
  end
  local raw = table.concat(vim.fn.readfile(json_path), "\n")
  local ok, parsed = pcall(vim.fn.json_decode, raw)
  if not ok then
    vim.notify("minuet.json: " .. tostring(parsed), vim.log.levels.ERROR)
    return nil
  end
  return parsed
end

local config = read_json()
if config then
  wrap_api_keys(config)
  local ok, err = pcall(require("minuet").setup, config)
  if not ok then
    vim.notify("minuet setup failed: " .. tostring(err), vim.log.levels.ERROR)
  end
end

vim.keymap.set("i", "<C-g>", function()
  local cmp = require("cmp")
  cmp.complete({
    config = {
      sources = cmp.config.sources({ { name = "minuet" } }),
    },
  })
end, { desc = "Minuet completion" })

vim.api.nvim_create_user_command("MinuetConfig", function()
  vim.fn.mkdir(data_dir, "p")
  if vim.fn.filereadable(json_path) ~= 1 then
    vim.fn.writefile(STARTER_LINES, json_path)
  end
  vim.cmd("edit " .. vim.fn.fnameescape(json_path))
end, { desc = "Edit minuet.json (creates starter if missing)" })
