---@module 'snacks'

local M = {}

---@param source string
---@param cb fun(items:opencode.picker.Loc[])
---@param opts? snacks.picker.Config
function M.open(source, cb, opts)
  Snacks.picker.pick(
    source,
    vim.tbl_extend("force", opts or {}, {
      confirm = M.action(cb),
    })
  )
end

---@param cb fun(items:opencode.picker.Loc[])
function M.action(cb)
  ---@type snacks.picker.Action.fn
  return function(picker)
    local ret = {} ---@type opencode.picker.Loc[]
    for _, item in ipairs(picker:selected({ fallback = true })) do
      local pos, end_pos = item.pos, item.end_pos
      ret[#ret + 1] = {
        buf = item.buf,
        cwd = item.cwd,
        path = require("snacks.picker.util").path(item),
        row = pos and pos[1] or nil,
        col = pos and pos[2] or nil,
        end_row = end_pos and end_pos[1] or nil,
        end_col = end_pos and end_pos[2] or nil,
      }
    end
    picker:close()
    cb(ret)
  end
end

---@type snacks.picker.Action.fn
function M.send(picker)
  M.action(require("opencode.cli.picker")._send_cb())(picker)
end

return M
