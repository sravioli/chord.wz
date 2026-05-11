---@module "chord.deps"

local wezterm = require "wezterm"

local M = {
  _cache = {},
}

---@class Chord.Dependency
---@field module string
---@field url string

---@type table<string, Chord.Dependency>
M.plugins = {
  log = {
    module = "log.api",
    url = "https://github.com/sravioli/log.wz",
  },
  memo = {
    module = "memo.api",
    url = "https://github.com/sravioli/memo.wz",
  },
  ribbon = {
    module = "ribbon.api",
    url = "https://github.com/sravioli/ribbon.wz",
  },
}

---@param name string
---@return table|nil
---@return any error
function M.optional(name)
  local spec = M.plugins[name]
  if not spec then
    return nil, ("unknown dependency: %s"):format(tostring(name))
  end

  if M._cache[name] then
    return M._cache[name], nil
  end

  local ok, plugin = pcall(require, spec.module)
  if ok and plugin then
    M._cache[name] = plugin
    return plugin, nil
  end

  ok, plugin = pcall(wezterm.plugin.require, spec.url)
  if ok and plugin then
    M._cache[name] = plugin
    return plugin, nil
  end

  return nil, plugin
end

---@param name string
---@return table
local function require_dependency(name)
  local plugin, err = M.optional(name)
  if plugin then
    return plugin
  end

  local spec = M.plugins[name]
  local label = spec and spec.url or tostring(name)
  error(("[chord] unable to load dependency %s: %s"):format(label, tostring(err)))
end

---@return table
function M.memo()
  return require_dependency "memo"
end

---@return table
function M.log()
  return require_dependency "log"
end

---@return table
function M.ribbon()
  return require_dependency "ribbon"
end

return M
