---@module "chord.overlay"

local command_options = require "chord.command_options"

---@class Chord.OverlayApi
---@field action fun(config_table: table, opts?: Chord.OverlayConfig): table
---@field apply fun(config_table: table, opts?: Chord.OverlayConfig): table

---@param cmd Chord.Command
---@return string
local function overlay_label(cmd)
  local group = cmd.table_name or cmd.source
  if group == "keys" then
    group = "global"
  end

  local label = cmd.label
  if cmd.lhs and cmd.lhs ~= "" then
    label = cmd.lhs .. "  " .. label
  end
  return "[" .. group .. "] " .. label
end

---@param _ Chord
---@param command table
---@return Chord.OverlayApi
return function(_, command)
  ---@type Chord.OverlayApi
  local overlay = {}

  ---Return a WezTerm action that opens the Chord help overlay.
  ---@param config_table table
  ---@param opts? Chord.OverlayConfig
  ---@return table
  function overlay.action(config_table, opts)
    return command.__picker(config_table, opts, command_options.overlay, function(commands)
      local choices = {}
      for _, cmd in ipairs(commands) do
        choices[#choices + 1] = { id = cmd.id, label = overlay_label(cmd) }
      end
      return choices
    end)
  end

  ---Add a trigger binding that opens the Chord help overlay.
  ---@param config_table table
  ---@param opts? Chord.OverlayConfig
  ---@return table
  function overlay.apply(config_table, opts)
    local options = command_options.overlay(opts)
    return command.__bind(
      config_table,
      options,
      overlay.action(config_table, options),
      "__chord_overlay"
    )
  end

  return overlay
end
