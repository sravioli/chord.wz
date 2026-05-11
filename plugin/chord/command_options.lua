---@module "chord.command_options"

local Logger = require "chord.logger"
local config = require "chord.config"

local M = {}

local source_aliases = {
  global = "keys",
  tables = "key_table",
  key_tables = "key_table",
  defaults = "default",
}

local valid_sources = {
  registered = true,
  keys = true,
  key_table = true,
  default = true,
}

---@return Chord.Logger
local function logger()
  return Logger.new("Chord", config.get().log)
end

---@param value any
---@return any
function M.clone(value)
  if type(value) ~= "table" then
    return value
  end

  local out = {}
  for k, v in pairs(value) do
    out[k] = M.clone(v)
  end
  return out
end

---@param base table
---@param override table|nil
---@return table
function M.merge(base, override)
  local out = M.clone(base or {})
  if type(override) ~= "table" then
    return out
  end

  for k, v in pairs(override) do
    if type(v) == "table" and type(out[k]) == "table" then
      out[k] = M.merge(out[k], v)
    else
      out[k] = M.clone(v)
    end
  end

  return out
end

---@param value any
---@return table
function M.shallow_copy(value)
  local out = {}
  if type(value) ~= "table" then
    return out
  end

  for k, v in pairs(value) do
    out[k] = v
  end
  return out
end

---@param opts? table
---@return Chord.CommandConfig
function M.command(opts)
  return M.merge(config.get().command or {}, opts)
end

---@param opts? table
---@return Chord.OverlayConfig
function M.overlay(opts)
  return M.merge(config.get().overlay or {}, opts)
end

---@param input table<string, boolean>
---@return string[]
function M.sorted_names(input)
  local names = {}
  for name in pairs(input or {}) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

---@param name any
---@return string|nil
function M.normalize_source_name(name)
  local source = source_aliases[tostring(name)] or tostring(name)
  if valid_sources[source] then
    return source
  end

  logger():warn("command: invalid source '%s' ignored", tostring(name))
  return nil
end

---@param value any
---@param normalize? fun(item:any): string|nil
---@return table<string, boolean>|nil
function M.option_set(value, normalize)
  if value == nil then
    return nil
  end

  local out = {}
  local function add(item)
    local normalized = normalize and normalize(item) or tostring(item)
    if normalized and normalized ~= "" then
      out[normalized] = true
    end
  end

  if type(value) == "string" then
    add(value)
    return out
  end
  if type(value) ~= "table" then
    return out
  end

  for key, item in pairs(value) do
    if type(key) == "number" then
      add(item)
    elseif item then
      add(key)
    end
  end

  return out
end

---@param source string
---@param opts Chord.CommandConfig
---@return boolean
function M.source_enabled(source, opts)
  local sources = M.option_set(opts.sources, M.normalize_source_name)
  if sources then
    return sources[source] == true
  end

  if source == "registered" then
    return opts.include_registered ~= false
  end
  if source == "keys" then
    return opts.include_keys ~= false
  end
  if source == "key_table" then
    return opts.include_key_tables ~= false
  end
  if source == "default" then
    return opts.include_defaults == true
  end
  return false
end

---@param table_name string|nil
---@param opts Chord.CommandConfig
---@return boolean
function M.table_allowed(table_name, opts)
  if not table_name then
    return true
  end

  local only = M.option_set(opts.tables)
  local excluded = M.option_set(opts.exclude_tables)
  if excluded and excluded[table_name] then
    return false
  end
  if only then
    return only[table_name] == true
  end
  return true
end

return M
