---@module "chord.overlay"

local command_options = require "chord.command_options"
local wezterm = require "wezterm" --[[@as Wezterm]]

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

---@param core Chord
---@param command table
---@return Chord.OverlayApi
return function(core, command)
  ---@type Chord.OverlayApi
  local overlay = {}

  ---Return a WezTerm action that opens the Chord help overlay.
  ---@param config_table table
  ---@param opts? Chord.OverlayConfig
  ---@return table
  function overlay.action(config_table, opts)
    return wezterm.action_callback(function(window, pane)
      local options = command_options.overlay(opts)
      local commands = command.collect(config_table, options)
      local by_id = {}
      local choices = {}

      for _, cmd in ipairs(commands) do
        by_id[cmd.id] = cmd
        choices[#choices + 1] = {
          id = cmd.id,
          label = overlay_label(cmd),
        }
      end

      window:perform_action(
        wezterm.action.InputSelector {
          title = options.title,
          choices = choices,
          fuzzy = options.fuzzy,
          description = options.description,
          fuzzy_description = options.fuzzy_description,
          alphabet = options.alphabet,
          action = wezterm.action_callback(function(inner_window, inner_pane, id)
            if not id then
              return
            end

            local cmd = by_id[id]
            if cmd then
              inner_window:perform_action(cmd.action, inner_pane or pane)
            end
          end),
        },
        pane
      )
    end)
  end

  ---Add a trigger binding that opens the Chord help overlay.
  ---@param config_table table
  ---@param opts? Chord.OverlayConfig
  ---@return table
  function overlay.apply(config_table, opts)
    local options = command_options.overlay(opts)
    local action = overlay.action(config_table, options)

    config_table.keys = config_table.keys or {}
    local entry = core.key(options.key, action, options.desc)
    if entry then
      entry.__chord_overlay = true
      config_table.keys[#config_table.keys + 1] = entry
    end

    return action
  end

  return overlay
end
