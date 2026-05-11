---@module "chord.deps"

local wezterm = require "wezterm"

local M = {
  _cache = {},
}

local urls = {
  memo = "https://github.com/sravioli/memo.wz",
  ribbon = "https://github.com/sravioli/ribbon.wz",
}

---@param name string
---@return table|nil
---@return any error
function M.optional(name)
  if M._cache[name] then
    return M._cache[name], nil
  end

  local ok, plugin = pcall(require, name .. ".api")
  if ok and plugin then
    M._cache[name] = plugin
    return plugin, nil
  end

  ok, plugin = pcall(wezterm.plugin.require, urls[name])
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

  error(("[chord] unable to load dependency %s: %s"):format(urls[name], tostring(err)))
end

---@return table
function M.memo()
  return require_dependency "memo"
end

---@return table
function M.ribbon()
  return require_dependency "ribbon"
end

return M
