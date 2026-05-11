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

function Ribbon:format()
  local out = {}
  for _, item in ipairs(self.items) do
    out[#out + 1] = item.text
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
