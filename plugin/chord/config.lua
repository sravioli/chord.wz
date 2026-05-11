---@module "chord.config"

local M = {}

---@class Chord.Config
---@field aliases table<string, string>
---@field modifiers table<string, string>
---@field leader string
---@field hints Chord.HintsConfig
---@field command Chord.CommandConfig
---@field overlay Chord.OverlayConfig
---@field log Chord.LogConfig

---@class Chord.HintsConfig
---@field separator string
---@field page_cache_prefix string

---@class Chord.CommandConfig
---@field key string
---@field desc string
---@field title string
---@field fuzzy boolean
---@field description string
---@field fuzzy_description string
---@field alphabet? string
---@field include_registered boolean
---@field include_keys boolean
---@field include_key_tables boolean
---@field include_defaults boolean
---@field include_undocumented boolean
---@field dedupe boolean
---@field sources? string[]|table<string, boolean>
---@field tables? string[]|table<string, boolean>
---@field exclude_tables? string[]|table<string, boolean>
---@field style Chord.CommandStyleConfig

---@class Chord.CommandStyleConfig
---@field enabled boolean
---@field formatter string
---@field color_by string
---@field include_source boolean
---@field include_table boolean
---@field mode_fg? string
---@field mode_colors table<string, table>
---@field source_colors table<string, table>

---@class Chord.OverlayConfig
---@field key string
---@field desc string
---@field title string
---@field fuzzy boolean
---@field description string
---@field fuzzy_description string
---@field alphabet? string

---@class Chord.LogConfig
---@field enabled boolean
---@field threshold string|integer

local defaults = {
  aliases = {
    CR = "Enter",
    BS = "Backspace",
    ESC = "Escape",
    Bar = "|",
    Space = " ",
    Up = "UpArrow",
    Down = "DownArrow",
    Left = "LeftArrow",
    Right = "RightArrow",
    k0 = "Numpad0",
    k1 = "Numpad1",
    k2 = "Numpad2",
    k3 = "Numpad3",
    k4 = "Numpad4",
    k5 = "Numpad5",
    k6 = "Numpad6",
    k7 = "Numpad7",
    k8 = "Numpad8",
    k9 = "Numpad9",
    lt = "<",
    gt = ">",
    PageUp = "PageUp",
    PageDown = "PageDown",
    F1 = "F1",
    F2 = "F2",
    F3 = "F3",
    F4 = "F4",
    F5 = "F5",
    F6 = "F6",
    F7 = "F7",
    F8 = "F8",
    F9 = "F9",
    F10 = "F10",
    F11 = "F11",
    F12 = "F12",
  },
  modifiers = {
    C = "CTRL",
    S = "SHIFT",
    A = "ALT",
    M = "ALT",
    W = "SUPER",
  },
  leader = "<leader>",
  hints = {
    separator = " / ",
    page_cache_prefix = "chord_hint_page",
  },
  command = {
    key = "<leader><Space>",
    desc = "command picker",
    title = "Commands",
    fuzzy = true,
    description = "Select command.",
    fuzzy_description = "Search",
    alphabet = nil,
    include_registered = true,
    include_keys = true,
    include_key_tables = true,
    include_defaults = false,
    include_undocumented = false,
    dedupe = true,
    sources = nil,
    tables = nil,
    exclude_tables = nil,
    style = {
      enabled = false,
      formatter = "plain",
      color_by = "mode",
      include_source = true,
      include_table = true,
      mode_fg = nil,
      mode_colors = {},
      source_colors = {
        registered = { fg = "#c0caf5", bg = "#414868" },
        keys = { fg = "#1a1b26", bg = "#9ece6a" },
        key_table = { fg = "#1a1b26", bg = "#7aa2f7" },
        default = { fg = "#1a1b26", bg = "#e0af68" },
      },
    },
  },
  overlay = {
    key = "<leader>?",
    desc = "key help",
    title = "Chord help",
    fuzzy = true,
    description = "Select command.",
    fuzzy_description = "Search",
    alphabet = nil,
  },
  log = {
    enabled = true,
    threshold = "warn",
  },
}

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
  local out = clone(base)
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

local current = clone(defaults)

---@param opts? table
---@return Chord.Config
function M.setup(opts)
  current = merge(defaults, opts)
  return current
end

---@return Chord.Config
function M.get()
  return current
end

---@return Chord.Config
function M.defaults()
  return clone(defaults)
end

return M
