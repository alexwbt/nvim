local function hierarchy_entry(bufnr, client, item, label)
  local col = vim.lsp.util._get_line_byte_from_position(bufnr, item.range.start, client.offset_encoding) or 0
  local text = (item.detail and #item.detail > 0) and (item.name .. " " .. item.detail) or item.name
  if label then
    text = string.format("[%s] %s", label, text)
  end
  return {
    filename = vim.uri_to_fname(item.uri),
    lnum = item.range.start.line + 1,
    col = col + 1,
    text = text,
  }
end

local function open_type_hierarchy_picker(entries)
  if #entries == 0 then
    vim.notify("No type hierarchy items", vim.log.levels.WARN)
    return
  end
  table.sort(entries, function(a, b)
    return a.text < b.text
  end)
  local config = require("telescope.config").values
  require("telescope.pickers").new({}, {
    prompt_title = "LSP type hierarchy",
    finder = require("telescope.finders").new_table({
      results = entries,
      entry_maker = require("telescope.make_entry").gen_from_quickfix({}),
    }),
    sorter = config.generic_sorter({}),
    previewer = config.qflist_previewer({}),
  }):find()
end

local function type_hierarchy()
  local bufnr = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  if not next(vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/prepareTypeHierarchy" })) then
    vim.notify("Type hierarchy is not supported by any server", vim.log.levels.WARN)
    return
  end

  local entries = {}
  local pending = 0
  local opened = false

  local function maybe_open()
    if pending == 0 and not opened then
      opened = true
      vim.schedule(function()
        open_type_hierarchy_picker(entries)
      end)
    end
  end

  vim.lsp.buf_request_all(bufnr, "textDocument/prepareTypeHierarchy", function(client)
    return vim.lsp.util.make_position_params(win, client.offset_encoding)
  end, function(req_results)
    for client_id, res in pairs(req_results) do
      if not res.err and res.result then
        local client = vim.lsp.get_client_by_id(client_id)
        for _, item in ipairs(res.result) do
          for _, dir in ipairs({ "subtypes", "supertypes" }) do
            local method = dir == "subtypes" and "typeHierarchy/subtypes" or "typeHierarchy/supertypes"
            local label = dir == "subtypes" and "sub" or "super"
            pending = pending + 1
            client:request(method, { item = item }, function(_, result)
              if result then
                for _, r in ipairs(result) do
                  entries[#entries + 1] = hierarchy_entry(bufnr, client, r, label)
                end
              end
              pending = pending - 1
              maybe_open()
            end, bufnr)
          end
        end
      end
    end
    maybe_open()
  end)
end

vim.keymap.set("n", "<leader>ft", type_hierarchy, { desc = "LSP type hierarchy (sub + super)" })
