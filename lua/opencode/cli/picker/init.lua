local Config = require("opencode.config")

local M = {}

---@class opencode.picker.Loc
---@field buf? integer
---@field cwd? string
---@field path string
---@field row? integer
---@field col? integer
---@field end_row? integer
---@field end_col? integer

---@class opencode.Picker
local P = {}

---@param source string
---@param cb fun(items:opencode.picker.Loc[])
---@param opts? table
function P.open(source, cb, opts) end

---@param cb fun(items:opencode.picker.Loc[])
---@return fun()
function P.action(cb) end

---@param picker? string
function M.get(picker)
  local pickers = picker and { picker } or { "snacks", "telescope", "fzf-lua" }
  for _, name in ipairs(pickers) do
    ---@type boolean, opencode.Picker
    local ok, mod = pcall(require, "opencode.cli.picker." .. name)
    if not ok then
      vim.notify("Invalid picker: " .. name, vim.log.levels.ERROR)
    else
      -- Check if the required dependency is available
      if name == "snacks" and pcall(require, "snacks") then
        return mod
      elseif name == "telescope" and pcall(require, "telescope") then
        return mod
      elseif name == "fzf-lua" and pcall(require, "fzf-lua") then
        return mod
      elseif name ~= "telescope" and name ~= "fzf-lua" and name ~= "snacks" then
        -- For custom pickers, just return the module if it loads
        return mod
      end
    end
  end
  vim.notify("No valid picker found", vim.log.levels.ERROR)
end

---@param opts? { prompt?: string, submit?: boolean }
function M._send_cb(opts)
  opts = opts or {}
  ---@param items opencode.picker.Loc[]
  return function(items)
    local Context = require("opencode.context")
    local lines = {} ---@type string[]
    for _, item in ipairs(items) do
      local path = item.path
      if item.cwd and item.cwd ~= vim.loop.cwd() then
        path = item.cwd .. "/" .. path
      end
      local location = Context.format({
        path = path,
        start_line = item.row,
        start_col = item.col,
        end_line = item.end_row,
        end_col = item.end_col,
      })
      if location ~= "" then
        table.insert(lines, location)
      end
    end
    if #lines > 0 then
      vim.schedule(function()
        local prompt = (opts.prompt or "") .. " " .. table.concat(lines, " ")
        require("opencode").prompt(prompt, opts)
      end)
    end
  end
end

---@param source string
---@param opts? { prompt?: string, submit?: boolean }
---@param popts? table
function M.open(source, opts, popts)
  local picker = M.get()
  return picker and picker.open(source, M._send_cb(opts), popts)
end

return M
