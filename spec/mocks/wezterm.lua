local wezterm = {}

wezterm.GLOBAL = {}
wezterm._logs = {}
wezterm._default_keys = {}
wezterm._format_calls = {}

local memo_store = {}
local memo = {
  cache = {
    get = function(key)
      return memo_store[key]
    end,
    set = function(key, value)
      memo_store[key] = value
    end,
    clear = function()
      for key in pairs(memo_store) do
        memo_store[key] = nil
      end
    end,
  },
}

local Ribbon = {}
Ribbon.__index = Ribbon

function Ribbon:append(bg, fg, text, attributes)
  self.items[#self.items + 1] = {
    bg = bg,
    fg = fg,
    text = text,
    attributes = attributes,
  }
  return self
end

function Ribbon:append_items(items)
  if type(items) ~= "table" or #items == 0 then
    self.items[#self.items + 1] = items
    return self
  end

  for _, item in ipairs(items) do
    self.items[#self.items + 1] = item
  end
  return self
end

function Ribbon:format()
  local out = {}
  for _, item in ipairs(self.items) do
    if type(item) == "table" and item.Text then
      out[#out + 1] = item.Text
    elseif type(item) == "table" and item.text then
      out[#out + 1] = item.text
    end
  end
  return table.concat(out)
end

local ribbon = {}

function ribbon:new(name, atomic)
  return setmetatable({
    name = name,
    atomic = atomic,
    items = {},
  }, Ribbon)
end

ribbon.new = ribbon.new

local function warp_is_list(value)
  if type(value) ~= "table" then
    return false
  end
  local n = #value
  local count = 0
  for _ in pairs(value) do
    count = count + 1
  end
  return count == n
end

local function warp_copy(value)
  if type(value) ~= "table" then
    return value
  end
  local copy = {}
  for key, child in pairs(value) do
    copy[key] = child
  end
  return copy
end

local function warp_deepcopy(value)
  if type(value) ~= "table" then
    return value
  end
  local copy = {}
  for key, child in pairs(value) do
    copy[key] = warp_deepcopy(child)
  end
  return copy
end

local function warp_merge(_, dst, ...)
  for i = 1, select("#", ...) do
    local src = select(i, ...)
    if type(src) == "table" then
      for key, value in pairs(src) do
        if
          type(value) == "table"
          and type(dst[key]) == "table"
          and not warp_is_list(value)
          and not warp_is_list(dst[key])
        then
          warp_merge("force", dst[key], value)
        else
          dst[key] = value
        end
      end
    end
  end
  return dst
end

local warp = {
  table = {
    copy = warp_copy,
    deepcopy = warp_deepcopy,
    merge = warp_merge,
  },
}

wezterm.plugin = {
  list = function()
    return {
      {
        url = "file:///tmp/chord.wz",
        plugin_dir = ".",
      },
    }
  end,
  require = function(url)
    if url:find("memo.wz", 1, true) then
      return memo
    end
    if url:find("ribbon.wz", 1, true) then
      return ribbon
    end
    if url:find("warp.wz", 1, true) then
      return warp
    end
    error("unknown plugin: " .. tostring(url))
  end,
}

function wezterm.column_width(value)
  return #tostring(value or "")
end

function wezterm.format(items)
  wezterm._format_calls[#wezterm._format_calls + 1] = items
  local out = {}
  for _, item in ipairs(items or {}) do
    if item.Text then
      out[#out + 1] = item.Text
    end
  end
  return table.concat(out)
end

function wezterm.action_callback(fn)
  return {
    __type = "action_callback",
    callback = fn,
  }
end

wezterm.action = {
  ActivateKeyTable = function(args)
    return {
      type = "ActivateKeyTable",
      args = args,
    }
  end,
  InputSelector = function(args)
    return {
      type = "InputSelector",
      args = args,
    }
  end,
}

wezterm.gui = {
  default_keys = function()
    return wezterm._default_keys
  end,
}

function wezterm._set_default_keys(keys)
  wezterm._default_keys = keys or {}
end

function wezterm.log_error(message)
  wezterm._logs[#wezterm._logs + 1] = { level = "error", message = message }
end

function wezterm.log_warn(message)
  wezterm._logs[#wezterm._logs + 1] = { level = "warn", message = message }
end

function wezterm.log_info(message)
  wezterm._logs[#wezterm._logs + 1] = { level = "info", message = message }
end

function wezterm.to_string(value)
  return tostring(value)
end

package.loaded.wezterm = wezterm

return wezterm
