---@module "chord.picker"

local Logger = require "chord.logger"
local config = require "chord.config"
local deps = require "chord.deps"
local wezterm = require "wezterm" --[[@as Wezterm]]

local M = {}
local warned_ribbon = false

---@return Chord.Logger
local function logger()
  return Logger.new("Chord", config.get().log)
end

---@param cmd Chord.Command
---@return string
local function plain_command_label(cmd)
  local label = cmd.label
  if cmd.lhs and cmd.lhs ~= "" then
    label = cmd.lhs .. "  " .. label
  end
  return label
end

---@param cmd Chord.Command
---@param style table
---@return string|nil
local function badge_text(cmd, style)
  if cmd.table_name and style.include_table ~= false then
    return cmd.table_name
  end
  if style.include_source ~= false then
    return cmd.source
  end
  return nil
end

---@param color any
---@return table|nil
local function normalize_color(color)
  if type(color) ~= "table" then
    return nil
  end

  if color.fg or color.bg then
    return color
  end
  return nil
end

---@param cmd Chord.Command
---@param style table
---@return table|nil
local function mode_color(cmd, style)
  if not cmd.table_name then
    return nil
  end

  local explicit = normalize_color(style.mode_colors and style.mode_colors[cmd.table_name])
  if explicit then
    return explicit
  end

  local meta = cmd.mode_meta
  if type(meta) == "table" and meta.bg then
    return {
      fg = meta.fg or style.mode_fg,
      bg = meta.bg,
    }
  end
  return nil
end

---@param cmd Chord.Command
---@param style table
---@return table|nil
local function source_color(cmd, style)
  return normalize_color(style.source_colors and style.source_colors[cmd.source])
end

---@param cmd Chord.Command
---@param style table
---@return table|nil
local function command_color(cmd, style)
  if style.color_by == "none" then
    return nil
  end
  if style.color_by == "source" then
    return source_color(cmd, style)
  end
  return mode_color(cmd, style) or source_color(cmd, style)
end

---@param badge string|nil
---@param label string
---@return string
local function decorated_text(badge, label)
  if not badge or badge == "" then
    return label
  end
  return "[" .. badge .. "] " .. label
end

---@param badge string|nil
---@param label string
---@param color table|nil
---@return string
local function format_with_wezterm(badge, label, color)
  if type(wezterm.format) ~= "function" then
    return decorated_text(badge, label)
  end

  local items = {}
  if badge and badge ~= "" then
    if color and color.fg then
      items[#items + 1] = { Foreground = { Color = color.fg } }
    end
    if color and color.bg then
      items[#items + 1] = { Background = { Color = color.bg } }
    end
    items[#items + 1] = { Attribute = { Intensity = "Bold" } }
    items[#items + 1] = { Text = "[" .. badge .. "]" }
    items[#items + 1] = { Attribute = { Intensity = "Normal" } }
    items[#items + 1] = { Text = " " }
  end

  items[#items + 1] = { Text = label }
  return wezterm.format(items)
end

---@param badge string|nil
---@param label string
---@param color table|nil
---@return string
local function format_with_ribbon(badge, label, color)
  local ribbon, err = deps.optional "ribbon"
  if not ribbon then
    if not warned_ribbon then
      warned_ribbon = true
      logger():warn(
        "command: ribbon formatter unavailable, falling back to wezterm.format: %s",
        err
      )
    end
    return format_with_wezterm(badge, label, color)
  end

  local ok, rendered = pcall(function()
    local layout = ribbon:new("CommandChoice", true)
    if badge and badge ~= "" then
      layout:append(color and color.bg or "", color and color.fg or "", "[" .. badge .. "]", "Bold")
      layout:append("", "", " ", "Normal")
    end
    layout:append("", "", label, "Normal")
    return layout:format()
  end)

  if ok then
    return rendered
  end

  if not warned_ribbon then
    warned_ribbon = true
    logger():warn("command: ribbon formatter failed, falling back to wezterm.format: %s", rendered)
  end
  return format_with_wezterm(badge, label, color)
end

---@param cmd Chord.Command
---@param options table
---@return string
local function command_choice_label(cmd, options)
  local label = plain_command_label(cmd)
  local style = options.style or {}

  if not style.enabled then
    return label
  end

  local badge = badge_text(cmd, style)
  local color = command_color(cmd, style)
  local formatter = style.formatter or "plain"

  if formatter == "wezterm" then
    return format_with_wezterm(badge, label, color)
  end
  if formatter == "ribbon" then
    return format_with_ribbon(badge, label, color)
  end
  if formatter ~= "plain" then
    logger():warn("command: invalid formatter '%s', using plain labels", tostring(formatter))
  end
  return decorated_text(badge, label)
end

---@param commands Chord.Command[]
---@param options table
---@return table[]
function M.choices(commands, options)
  local choices = {}
  for _, cmd in ipairs(commands) do
    choices[#choices + 1] = {
      id = cmd.id,
      label = command_choice_label(cmd, options),
    }
  end
  return choices
end

return M
