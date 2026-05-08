---@module "chord.logger"

local wezterm = require "wezterm" --[[@as Wezterm]]

-- selene: allow(incorrect_standard_library_use)
local unpack = unpack or table.unpack

---@class Chord.Logger
---@field tag string
---@field enabled boolean
---@field threshold integer
local M = {}
M.__index = M

local levels = {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
}

---@param value any
---@return integer
local function resolve_threshold(value)
  if type(value) == "number" then
    return value
  end
  return levels[tostring(value or "WARN"):upper()] or levels.WARN
end

---@param value any
---@return string
local function stringify(value)
  if type(value) == "string" then
    return value
  end

  if wezterm and type(wezterm.to_string) == "function" then
    local ok, rendered = pcall(wezterm.to_string, value)
    if ok then
      return rendered
    end
  end

  return tostring(value)
end

---@param message any
---@param ... any
---@return string
local function format_message(message, ...)
  local count = select("#", ...)
  if count == 0 then
    return stringify(message)
  end

  local args = {}
  for i = 1, count do
    args[i] = stringify(select(i, ...))
  end

  local ok, formatted = pcall(string.format, stringify(message), unpack(args))
  return ok and formatted or stringify(message)
end

---@param level integer
---@param tag string
---@param message string
local function emit(level, tag, message)
  local line = string.format("[%s] %s", tag, message)
  local sink

  if level >= levels.ERROR and type(wezterm.log_error) == "function" then
    sink = wezterm.log_error
  elseif level >= levels.WARN and type(wezterm.log_warn) == "function" then
    sink = wezterm.log_warn
  elseif type(wezterm.log_info) == "function" then
    sink = wezterm.log_info
  end

  if sink then
    sink(line)
  end
end

---@param tag string
---@param cfg Chord.LogConfig
---@return Chord.Logger
function M.new(tag, cfg)
  cfg = cfg or {}
  return setmetatable({
    tag = tag,
    enabled = cfg.enabled ~= false,
    threshold = resolve_threshold(cfg.threshold),
  }, M)
end

---@param level integer
---@param message any
---@param ... any
---@return nil
function M:write(level, message, ...)
  if not self.enabled or level < self.threshold then
    return nil
  end

  emit(level, self.tag, format_message(message, ...))
  return nil
end

---@param message any
---@param ... any
---@return nil
function M:debug(message, ...)
  return self:write(levels.DEBUG, message, ...)
end

---@param message any
---@param ... any
---@return nil
function M:info(message, ...)
  return self:write(levels.INFO, message, ...)
end

---@param message any
---@param ... any
---@return nil
function M:warn(message, ...)
  return self:write(levels.WARN, message, ...)
end

---@param message any
---@param ... any
---@return nil
function M:error(message, ...)
  return self:write(levels.ERROR, message, ...)
end

return M
