---@module "chord.overlay"

local config = require "chord.config"
local wezterm = require "wezterm" --[[@as Wezterm]]

---@param value any
---@return any
local function clone(value)
  if type(value) ~= "table" then
    return value
  end

  local out = {}
  for k, v in pairs(value) do
    out[k] = clone(v)
  end
  return out
end

---@param base table
---@param override table|nil
---@return table
local function merge(base, override)
  local out = clone(base or {})
  if type(override) ~= "table" then
    return out
  end

  for k, v in pairs(override) do
    if type(v) == "table" and type(out[k]) == "table" then
      out[k] = merge(out[k], v)
    else
      out[k] = clone(v)
    end
  end

  return out
end

---@param opts? table
---@return table
local function overlay_options(opts)
  return merge(config.get().overlay or {}, opts)
end

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
---@return table
return function(core, command)
  local overlay = {}

  ---Return a WezTerm action that opens the Chord help overlay.
  ---@param config_table table
  ---@param opts? table
  ---@return table
  function overlay.action(config_table, opts)
    return wezterm.action_callback(function(window, pane)
      local options = overlay_options(opts)
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

  ---Inject a trigger binding that opens the Chord help overlay.
  ---@param config_table table
  ---@param opts? table
  ---@return table
  function overlay.apply(config_table, opts)
    local options = overlay_options(opts)
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
