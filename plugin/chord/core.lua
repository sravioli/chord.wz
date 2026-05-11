---@module "chord.core"

local Logger = require "chord.logger"
local config = require "chord.config"
local deps = require "chord.deps"
local wezterm = require "wezterm" --[[@as Wezterm]]

local sgsub, ssub, smatch, sformat = string.gsub, string.sub, string.match, string.format
local tconcat = table.concat

---@class Chord.KeyMeta
---@field i string
---@field txt string
---@field bg string
---@field pad? number
---@field name? string

---@class Chord.KeyTableDef
---@field meta Chord.KeyMeta
---@field keys table[]

---@alias Chord.KeyTableDefFn fun(theme: table): Chord.KeyTableDef

---@class Chord
local M = {
  ---@type table<string, string>
  aliases = {},
  ---@type table<string, string>
  modifiers = {},
  ---@private
  _defs = {},
  ---@private
  _hint_entries_cache = nil,
  ---@private
  _modes_cache_key = nil,
  ---@private
  _modes_cache = nil,
  ---@private
  _rev_aliases = nil,
  ---@private
  _registered_commands = {},
  ---@private
  _command_seq = 0,
}

---@type Chord.Logger
local log

---@param s string
---@param pattern string
---@return string[]
local function split(s, pattern)
  local out = {}
  for part in tostring(s):gmatch("([^" .. pattern .. "]+)") do
    out[#out + 1] = part
  end
  return out
end

---@return nil
local function clear_caches()
  M._hint_entries_cache = nil
  M._modes_cache_key = nil
  M._modes_cache = nil
  M._rev_aliases = nil
end

---@return nil
local function refresh_config_refs()
  local cfg = config.get()
  M.aliases = cfg.aliases
  M.modifiers = cfg.modifiers
  log = Logger.new("Chord", cfg.log)
  clear_caches()
end

refresh_config_refs()

---@param opts? table
---@return Chord
function M.setup(opts)
  config.setup(opts)
  refresh_config_refs()
  return M
end

---@return Chord.Config
function M.config()
  return config.get()
end

---@param value any
---@return table
local function shallow_copy(value)
  local out = {}
  if type(value) ~= "table" then
    return out
  end

  for k, v in pairs(value) do
    out[k] = v
  end
  return out
end

---@param value any
---@return boolean
local function is_native_entry(value)
  return type(value) == "table" and value.key ~= nil and value.action ~= nil
end

---@param value any
---@return boolean
local function is_vim_spec(value)
  return type(value) == "table" and (value.lhs ~= nil or value[1] ~= nil)
end

---@param lhs string
---@param mods string[]
---@return string
local function strip_leader(lhs, mods)
  if smatch(lhs, "^<[Ll][Ee][Aa][Dd][Ee][Rr]>") then
    lhs = sgsub(lhs, "^<[Ll][Ee][Aa][Dd][Ee][Rr]>", "")
    mods[#mods + 1] = "LEADER"
  end
  return lhs
end

---@param lhs string
---@return boolean valid
---@return string|nil error_message
function M.validate(lhs)
  if not lhs or type(lhs) ~= "string" or lhs == "" then
    return false, "keymap must be a non-empty string"
  end
  if #lhs == 1 then
    return true
  end

  local test_lhs = lhs
  if smatch(test_lhs, "^<[Ll][Ee][Aa][Dd][Ee][Rr]>") then
    test_lhs = sgsub(test_lhs, "^<[Ll][Ee][Aa][Dd][Ee][Rr]>", "")
  end
  if not test_lhs:match "%b<>" then
    return true
  end

  local normalized = sgsub(test_lhs, "(%b<>)", function(s)
    return ssub(s, 2, -2)
  end)
  local keys = split(normalized, "%-")
  if #keys == 1 then
    return true
  end

  local key = keys[#keys]
  if M.modifiers[key] then
    return false, "keymap cannot end with modifier!"
  end
  for i = 1, #keys - 1 do
    if not M.modifiers[keys[i]] then
      return false, sformat("unknown modifier: %s", keys[i])
    end
  end
  return true
end

---@param lhs string
---@return table|nil entry
---@return string|nil error_message
function M.normalize(lhs)
  local valid, err = M.validate(lhs)
  if not valid then
    return nil, err
  end

  local mods = {}
  if #lhs == 1 then
    return { key = lhs }
  end

  lhs = strip_leader(lhs, mods)
  if not smatch(lhs, "%b<>") then
    return {
      key = lhs,
      mods = #mods > 0 and tconcat(mods, "|") or nil,
    }
  end

  lhs = sgsub(lhs, "(%b<>)", function(s)
    return ssub(s, 2, -2)
  end)
  local keys = split(lhs, "%-")
  if #keys == 1 then
    return {
      key = M.aliases[keys[1]] or keys[1],
      mods = #mods > 0 and tconcat(mods, "|") or nil,
    }
  end

  local key = keys[#keys]
  if M.modifiers[key] then
    return nil, "keymap cannot end with modifier!"
  end
  key = M.aliases[key] or key

  for i = 1, #keys - 1 do
    local mod = M.modifiers[keys[i]]
    if not mod then
      return nil, sformat("unknown modifier: %s", keys[i])
    end
    mods[#mods + 1] = mod
  end

  return {
    key = key,
    mods = #mods > 0 and tconcat(mods, "|") or nil,
  }
end

---@param lhs_or_spec string|table
---@param action? any
---@param desc? string
---@return table|nil
function M.key(lhs_or_spec, action, desc)
  if is_native_entry(lhs_or_spec) then
    local entry = shallow_copy(lhs_or_spec)
    if desc ~= nil then
      entry.desc = desc
    end
    return entry
  end

  local lhs = lhs_or_spec
  if type(lhs_or_spec) == "table" then
    lhs = lhs_or_spec.lhs or lhs_or_spec[1]
    action = lhs_or_spec.action or lhs_or_spec.rhs or lhs_or_spec[2]
    desc = lhs_or_spec.desc or lhs_or_spec[3]
  end

  if type(lhs) ~= "string" then
    log:error("cannot map %s without lhs!", tostring(action))
    return nil
  end
  if action == nil then
    log:error("cannot map %s to a nil action!", lhs)
    return nil
  end

  local entry, err = M.normalize(lhs)
  if not entry then
    log:error("invalid keymap %s: %s", lhs, err)
    return nil
  end

  entry.action = action
  if desc ~= nil then
    entry.desc = desc
  end
  return entry
end

---@param lhs_or_spec string|table
---@param action any
---@param target table
---@return nil
function M.map(lhs_or_spec, action, target)
  if not target then
    log:error "cannot add keymap! No table given"
    return nil
  end

  local entry = M.key(lhs_or_spec, action)
  if entry then
    target[#target + 1] = entry
  end
  return nil
end

---@param mappings table[]
---@param target table
---@return nil
function M.map_batch(mappings, target)
  if not mappings then
    log:error "cannot batch map: no mappings provided"
    return nil
  end
  if not target then
    log:error "cannot batch map: no table provided"
    return nil
  end

  local ok, fail = 0, 0
  for idx, mapping in ipairs(mappings) do
    local entry = M.key(mapping)
    if entry then
      target[#target + 1] = entry
      ok = ok + 1
    else
      log:error(
        "invalid mapping format at index %d: expected mapping table, got %s",
        idx,
        type(mapping)
      )
      fail = fail + 1
    end
  end

  log:debug("batch map complete: %d succeeded, %d failed", ok, fail)
  return nil
end

---@param mappings table[]
---@return table[]
function M.table(mappings)
  local key_table = {}
  if not mappings then
    log:error "cannot create key table: no mappings provided"
    return key_table
  end
  M.map_batch(mappings, key_table)
  return key_table
end

---@param config_table table
---@param mappings table[]
---@return nil
function M.maps(config_table, mappings)
  config_table.keys = config_table.keys or {}
  M.map_batch(mappings, config_table.keys)
  return nil
end

---@param name string
---@param def Chord.KeyTableDef|Chord.KeyTableDefFn
---@param theme table
---@return Chord.KeyTableDef|nil
local function resolve_def(name, def, theme)
  if type(def) == "function" then
    return def(theme)
  end
  if type(def) == "table" then
    return def
  end
  log:error("key table '%s' must be a table or function, got %s", name, type(def))
  return nil
end

---@return table
local function proxy_theme()
  local proxy
  proxy = setmetatable({}, {
    __index = function()
      return proxy
    end,
  })
  return proxy
end

---@param entry table
---@return string|nil
local function normalize_entry_ref(entry)
  if type(entry) == "string" then
    local normalized = M.normalize(entry)
    return normalized and M.__entry_lhs(normalized) or nil
  end

  if is_native_entry(entry) then
    return M.__entry_lhs(entry)
  end

  if is_vim_spec(entry) then
    return normalize_entry_ref(entry.lhs or entry[1])
  end

  return nil
end

---@param spec table|nil
---@return any rhs
---@return string|nil desc
local function parse_spec(spec)
  if type(spec) ~= "table" then
    return nil, nil
  end

  if is_native_entry(spec) then
    return spec.action, spec.desc
  end

  if spec.rhs ~= nil then
    return spec.rhs, spec.desc
  end

  if spec.action ~= nil then
    return spec.action, spec.desc
  end

  local rhs = spec[1]
  if rhs == nil then
    return nil, nil
  end
  return rhs, spec[2]
end

---@param entries table[]
---@param spec table|nil
---@return table[]
local function apply_wez_entries(entries, spec)
  local out = {}
  for i = 1, #(entries or {}) do
    out[#out + 1] = shallow_copy(entries[i])
  end

  local disabled = {}
  for _, lhs in ipairs(spec and spec.disable or {}) do
    local normalized = normalize_entry_ref(lhs)
    if normalized then
      disabled[normalized] = true
    end
  end

  if next(disabled) then
    local filtered = {}
    for i = 1, #out do
      local lhs = M.__entry_lhs(out[i])
      if not disabled[lhs] then
        filtered[#filtered + 1] = out[i]
      end
    end
    out = filtered
  end

  local by_lhs = {}
  for i = 1, #out do
    by_lhs[M.__entry_lhs(out[i])] = i
  end

  for lhs, value in pairs(spec and spec.override or {}) do
    local normalized = normalize_entry_ref(lhs)
    local rhs, desc = parse_spec(value)
    if normalized and rhs ~= nil then
      local idx = by_lhs[normalized]
      if idx then
        out[idx].action = rhs
        if desc ~= nil then
          out[idx].desc = desc
        end
      else
        local entry = M.key(lhs, rhs, desc)
        if entry then
          out[#out + 1] = entry
          by_lhs[normalized] = #out
        end
      end
    end
  end

  for _, mapping in ipairs(spec and spec.add or {}) do
    local entry = M.key(mapping)
    if entry then
      out[#out + 1] = entry
    end
  end

  return out
end

---@param entries table[]
---@param spec table|nil
---@return table[]
local function apply_raw_entries(entries, spec)
  local out = {}
  for i = 1, #(entries or {}) do
    out[#out + 1] = shallow_copy(entries[i])
  end

  local disabled = {}
  for _, lhs in ipairs(spec and spec.disable or {}) do
    local normalized = normalize_entry_ref(lhs)
    if normalized then
      disabled[normalized] = true
    end
  end

  if next(disabled) then
    local filtered = {}
    for i = 1, #out do
      local lhs = normalize_entry_ref(out[i])
      if not lhs or not disabled[lhs] then
        filtered[#filtered + 1] = out[i]
      end
    end
    out = filtered
  end

  local by_lhs = {}
  for i = 1, #out do
    local lhs = normalize_entry_ref(out[i])
    if lhs then
      by_lhs[lhs] = i
    end
  end

  for lhs, value in pairs(spec and spec.override or {}) do
    local normalized = normalize_entry_ref(lhs)
    local rhs, desc = parse_spec(value)
    if normalized and rhs ~= nil then
      local idx = by_lhs[normalized]
      if idx then
        local current = out[idx]
        if is_native_entry(current) then
          current.action = rhs
          if desc ~= nil then
            current.desc = desc
          end
        else
          current[1] = lhs
          current[2] = rhs
          if desc ~= nil then
            current[3] = desc
          end
        end
      else
        out[#out + 1] = { lhs, rhs, desc }
        by_lhs[normalized] = #out
      end
    end
  end

  for _, mapping in ipairs(spec and spec.add or {}) do
    out[#out + 1] = shallow_copy(mapping)
  end

  return out
end

---@param config_table table
---@param overrides table
---@return nil
function M.apply_overrides(config_table, overrides)
  if type(overrides) ~= "table" then
    return nil
  end

  local enabled = overrides.enabled or {}

  if enabled.keys == false then
    config_table.keys = {}
  else
    config_table.keys = apply_wez_entries(config_table.keys or {}, overrides.keys or {})
  end

  if enabled.key_tables == false then
    config_table.key_tables = {}
    M._defs = {}
  else
    config_table.key_tables = config_table.key_tables or {}
    local table_specs = overrides.key_tables or {}

    for name, spec in pairs(table_specs) do
      if type(spec) == "table" then
        if spec.enabled == false then
          config_table.key_tables[name] = nil
          M._defs[name] = nil
        else
          local existing = config_table.key_tables[name] or {}
          config_table.key_tables[name] = apply_wez_entries(existing, spec)

          local def = M._defs[name]
          if def then
            M._defs[name] = function(theme)
              local resolved = resolve_def(name, def, theme)
              if not resolved then
                return nil
              end

              local next_resolved = {
                meta = resolved.meta,
                keys = apply_raw_entries(resolved.keys or {}, spec),
              }
              if next_resolved.meta then
                next_resolved.meta.name = name
              end
              return next_resolved
            end
          end
        end
      end
    end
  end

  clear_caches()
  return nil
end

---@param config_table table
---@param defs table<string, Chord.KeyTableDef|Chord.KeyTableDefFn>
---@return nil
function M.tables(config_table, defs)
  if not defs then
    log:error "cannot register key tables: no definitions provided"
    return nil
  end

  M._defs = defs
  clear_caches()

  local proxy = proxy_theme()
  config_table.key_tables = config_table.key_tables or {}

  for name, def in pairs(defs) do
    local resolved = resolve_def(name, def, proxy)
    if resolved then
      if resolved.meta then
        resolved.meta.name = name
      end
      if resolved.keys then
        config_table.key_tables[name] = M.table(resolved.keys)
      else
        log:error("key table '%s' is missing a 'keys' field", name)
      end
    end
  end
  return nil
end

---@param theme table
---@return string
local function theme_cache_key(theme)
  return tostring(theme.foreground or "")
    .. "|"
    .. tostring(theme.background or "")
    .. "|"
    .. tostring(theme.ansi and theme.ansi[5] or "")
end

---@param theme table
---@return table<string, Chord.KeyMeta>
function M.get_modes(theme)
  local key = theme_cache_key(theme or {})
  if key == M._modes_cache_key and M._modes_cache then
    return M._modes_cache
  end

  local modes = {}
  for name, def in pairs(M._defs or {}) do
    local resolved = resolve_def(name, def, theme or {})
    if resolved then
      if resolved.meta then
        modes[name] = resolved.meta
      else
        log:warn("key table '%s' has no 'meta' field; skipped in get_modes()", name)
      end
    end
  end

  M._modes_cache_key = key
  M._modes_cache = modes
  return modes
end

---@param name string
---@param theme? table
---@return Chord.KeyMeta|nil
function M.__mode_meta(name, theme)
  local def = M._defs and M._defs[name]
  if not def then
    return nil
  end

  local resolved = resolve_def(name, def, theme or proxy_theme())
  return resolved and resolved.meta or nil
end

---@return table<string, string>
local function get_rev_aliases()
  if not M._rev_aliases then
    local rev = {}
    for vim_key, wez_key in pairs(M.aliases) do
      rev[wez_key] = vim_key
    end
    M._rev_aliases = rev
  end
  return M._rev_aliases
end

---@param mods_str string
---@return boolean
---@return string[]
local function parse_mods(mods_str)
  local rev_mods = { CTRL = "C", SHIFT = "S", ALT = "A", SUPER = "W" }
  local has_leader, parts = false, {}
  for mod in tostring(mods_str or ""):gmatch "[^|]+" do
    if mod == "LEADER" then
      has_leader = true
    else
      parts[#parts + 1] = rev_mods[mod] or mod
    end
  end
  return has_leader, parts
end

---@param display_key string
---@param mod_parts string[]
---@param has_leader boolean
---@return string
local function format_lhs(display_key, mod_parts, has_leader)
  local lhs
  if #mod_parts > 0 then
    lhs = "<" .. tconcat(mod_parts, "-") .. "-" .. display_key .. ">"
  elseif #display_key > 1 then
    lhs = "<" .. display_key .. ">"
  else
    lhs = display_key
  end
  if has_leader then
    lhs = "<leader>" .. lhs
  end
  return lhs
end

---@param entry table
---@return string
M.__entry_lhs = function(entry)
  local display_key = get_rev_aliases()[entry.key] or entry.key
  local has_leader, mod_parts = parse_mods(entry.mods or "")
  return format_lhs(display_key, mod_parts, has_leader)
end

---@param window_id integer|string
---@param pane_id integer|string
---@param name string|nil
---@return string
M.__hint_var = function(window_id, pane_id, name)
  local prefix = config.get().hints.page_cache_prefix or "chord_hint_page"
  return prefix .. "_w" .. window_id .. "_p" .. pane_id .. "_" .. (name or "__keys__")
end

---@param value string
---@return integer
local function width(value)
  value = tostring(value or "")
  if wezterm and type(wezterm.column_width) == "function" then
    return wezterm.column_width(value)
  end
  return #value
end

---@param entries table[]
---@return {lhs:string, desc:string}[]
local function collect_raw(entries)
  local raw = {}
  for _, entry in ipairs(entries or {}) do
    if entry.desc and entry.desc ~= "" then
      raw[#raw + 1] = { lhs = M.__entry_lhs(entry), desc = entry.desc }
    end
  end
  return raw
end

---@param raw {lhs:string, desc:string}[]
---@param budget number
---@return {lhs:string, desc:string}[][]
local function pack_pages(raw, budget)
  local sep = config.get().hints.separator or " / "
  local sep_w = width(sep)
  if #raw == 0 then
    return {}
  end

  local pages, page, used = {}, {}, 0
  for _, item in ipairs(raw) do
    local item_w = width(item.lhs .. " " .. item.desc)
    if #page > 0 and used + sep_w + item_w > budget then
      pages[#pages + 1] = page
      page, used = { item }, item_w
    else
      if #page > 0 then
        used = used + sep_w
      end
      page[#page + 1] = item
      used = used + item_w
    end
  end
  if #page > 0 then
    pages[#pages + 1] = page
  end
  return pages
end

---@param entries table[]
---@param width_cols integer
---@param window table
---@param name string|nil
---@return {lhs:string, desc:string}[]|nil
---@return string
---@return integer
local function current_page(entries, width_cols, window, name)
  local cache = deps.memo().cache
  local raw = collect_raw(entries)

  local probe = pack_pages(raw, width_cols)
  local total = #probe
  if total == 0 then
    return nil, "", 0
  end
  if total == 1 then
    return probe[1], "", 0
  end

  local max_ind = sformat(" [%d/%d]", total, total)
  local ind_w = width(max_ind)

  local pages = pack_pages(raw, width_cols - ind_w)
  total = #pages

  local active_pane = window:active_pane()
  local var_key = M.__hint_var(window:window_id(), active_pane:pane_id(), name)
  local stored = cache.get(var_key)
  local page = (type(stored) == "number") and stored or 1
  page = math.max(1, math.min(page, total))
  cache.set(var_key, page)

  local indicator = sformat(" [%d/%d]", page, total)
  local pad = ind_w - width(indicator)
  if pad > 0 then
    indicator = indicator .. string.rep(" ", pad)
  end

  return pages[page], indicator, ind_w
end

---@param config_table table
---@param name string|nil
---@return table[]
local function resolve_entries(config_table, name)
  local function has_descriptions(entries)
    for _, entry in ipairs(entries or {}) do
      if entry.desc and entry.desc ~= "" then
        return true
      end
    end
    return false
  end

  local function resolve_entries_from_defs(table_name)
    if type(table_name) ~= "string" or table_name == "" then
      return nil
    end

    M._hint_entries_cache = M._hint_entries_cache or {}
    if M._hint_entries_cache[table_name] then
      return M._hint_entries_cache[table_name]
    end

    local def = M._defs and M._defs[table_name]
    if not def then
      return nil
    end

    local resolved = resolve_def(table_name, def, proxy_theme())
    if not resolved or not resolved.keys then
      return nil
    end

    local rebuilt = M.table(resolved.keys)
    M._hint_entries_cache[table_name] = rebuilt
    return rebuilt
  end

  if not name then
    return config_table.keys or {}
  end

  local entries = config_table.key_tables and config_table.key_tables[name]
  if entries and has_descriptions(entries) then
    return entries
  end

  local fallback_entries = resolve_entries_from_defs(name)
  if fallback_entries then
    return fallback_entries
  end

  if not entries then
    log:warn("hint: key table '%s' not found", name)
  end
  return entries or {}
end

M.__resolve_entries = resolve_entries

---@param config_table table
---@param name string|nil
---@param width_cols integer
---@param window table
---@return string
function M.hint(config_table, name, width_cols, window)
  local entries = resolve_entries(config_table, name)
  local items, indicator, ind_w = current_page(entries, width_cols, window, name)

  if not items then
    return string.rep(" ", width_cols)
  end

  local sep = config.get().hints.separator or " / "
  local sep_w = width(sep)
  local budget = width_cols - ind_w
  local parts = {}
  local used = 0

  for _, item in ipairs(items) do
    local item_text = item.lhs .. " " .. item.desc
    local item_w = width(item_text)
    local need = item_w + (#parts > 0 and sep_w or 0)
    if used + need > budget then
      break
    end
    if #parts > 0 then
      used = used + sep_w
    end
    parts[#parts + 1] = item_text
    used = used + item_w
  end

  local body = tconcat(parts, sep)
  local body_w = width(body)
  if body_w < budget then
    body = string.rep(" ", budget - body_w) .. body
  end
  return body .. indicator
end

---@param config_table table
---@param name string|nil
---@param width_cols integer
---@param window table
---@param opts table
---@return table
function M.hint_layout(config_table, name, width_cols, window, opts)
  local ribbon = deps.ribbon()
  local theme = opts.theme
  local mode_bg = tostring(opts.mode_bg)
  local bg = tostring(theme.tab_bar.background)
  local fg = tostring(theme.foreground)
  local dim_fg = theme.brights and tostring(theme.brights[1]) or fg
  local layout = ribbon:new("HintBar", true)
  local entries = resolve_entries(config_table, name)
  local items, indicator, ind_w = current_page(entries, width_cols, window, name)

  if not items then
    layout:append(bg, fg, string.rep(" ", width_cols))
    return layout
  end

  local sep = config.get().hints.separator or " / "
  local sep_w = width(sep)
  local budget = width_cols - ind_w
  local used = 0
  local selected = {}

  for i, item in ipairs(items) do
    local item_w = width(item.lhs) + 1 + width(item.desc)
    local need = item_w + (i > 1 and sep_w or 0)
    if used + need > budget then
      break
    end

    selected[#selected + 1] = item
    if i > 1 then
      used = used + sep_w
    end
    used = used + item_w
  end

  if used < budget then
    layout:append(bg, fg, string.rep(" ", budget - used))
  end

  local function append_lhs(lhs)
    if lhs:sub(1, 1) == "<" and lhs:sub(-1) == ">" then
      layout:append(bg, fg, "<", "Bold")
      layout:append(bg, mode_bg, lhs:sub(2, -2), "Normal")
      layout:append(bg, fg, ">", "Bold")
    else
      layout:append(bg, mode_bg, lhs, "Bold")
    end
  end

  for i, item in ipairs(selected) do
    if i > 1 then
      layout:append(bg, dim_fg, sep, "Normal")
    end

    append_lhs(item.lhs)
    layout:append(bg, fg, " " .. item.desc, "Italic")
  end

  if indicator ~= "" then
    layout:append(bg, fg, indicator, "Normal")
  end

  return layout
end

---@param name string|nil
---@param direction number
---@return table
function M.hint_action(name, direction)
  return wezterm.action_callback(function(window, pane)
    local cache = deps.memo().cache
    local active_pane = window:active_pane()
    local pane_id = active_pane and active_pane:pane_id() or pane:pane_id()
    local active_name = window:active_key_table() or name
    local var_key = M.__hint_var(window:window_id(), pane_id, active_name)
    local current = cache.get(var_key)
    local page = (type(current) == "number") and current or 1

    page = math.max(1, page + direction)
    cache.set(var_key, page)
    window:set_right_status ""
  end)
end

local command_api

---@param loader fun(): table
---@return table
local function lazy_proxy(loader)
  return setmetatable({}, {
    __index = function(_, key)
      return loader()[key]
    end,
    __newindex = function(_, key, value)
      loader()[key] = value
    end,
  })
end

---@return table
local function load_command()
  if not command_api then
    command_api = require "chord.command"(M)
  end
  return command_api
end

---@return table
function M.__command_api()
  return load_command()
end

M.command = lazy_proxy(load_command)

return M
