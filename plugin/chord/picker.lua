---@module "chord.picker"

local M = {}

---@param cmd Chord.Command
---@return string
local function command_label(cmd)
  local label = cmd.label
  if cmd.lhs and cmd.lhs ~= "" then
    label = cmd.lhs .. "  " .. label
  end
  return label
end

---@param commands Chord.Command[]
---@param options table
---@return table[]
function M.choices(commands, options)
  local choices = {}
  for _, cmd in ipairs(commands) do
    choices[#choices + 1] = {
      id = cmd.id,
      label = command_label(cmd),
    }
  end
  return choices
end

return M
