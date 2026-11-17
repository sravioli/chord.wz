---@module "chord.logger"

local deps = require "chord.deps"
local wezterm = require "wezterm" --[[@as Wezterm]]

---@class Chord.Logger
---@field tag string
---@field enabled boolean
---@field threshold integer
---@field _external table|nil log.wz logger, when installed.
local M = {}
M.__index = M

local levels = { DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3 }
local level_names = { [0] = "debug", [1] = "info", [2] = "warn", [3] = "error" }

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
  local ok, rendered = pcall(wezterm.to_string, value) ---@diagnostic disable-line: undefined-field
  return ok and type(rendered) == "string" and rendered or tostring(value)
end

---log.wz when it is installed; nil otherwise.
---@param tag string
---@param cfg Chord.LogConfig
---@return table|nil
local function external_logger(tag, cfg)
  local log = deps.optional "log"
  if not log or type(log.new) ~= "function" then
    return nil
  end
  -- Never call log.setup here: its config is shared by every plugin.
  local ok, logger = pcall(log.new, tag, cfg.enabled ~= false)
  if ok and logger and type(logger.log) == "function" then
    -- chord filters in M:write; log.wz must not filter again at its own level.
    logger.threshold = resolve_threshold(cfg.threshold)
    return logger
  end
  return nil
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
    _external = external_logger(tag, cfg),
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
  local text = stringify(message)
  local n = select("#", ...)
  if n > 0 then
    local args = { ... }
    for i = 1, n do
      args[i] = stringify(args[i])
    end
    local ok, formatted = pcall(string.format, text, table.unpack(args, 1, n))
    text = ok and formatted or text
  end
  if self._external then
    -- As an argument, so a `%` in the text is never read as a format.
    self._external:log(level_names[level] or level, "%s", text)
    return nil
  end
  -- WezTerm has no debug log; debug goes to info.
  local sink = level >= levels.ERROR and "log_error"
    or level >= levels.WARN and "log_warn"
    or "log_info"
  if type(wezterm[sink]) == "function" then
    wezterm[sink](("[%s] %s"):format(self.tag, text))
  end
  return nil
end

for name, level in pairs(levels) do
  M[name:lower()] = function(self, message, ...)
    return self:write(level, message, ...)
  end
end

return M
