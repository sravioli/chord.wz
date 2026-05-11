---@module "chord.command"

local Logger = require "chord.logger"
local config = require "chord.config"
local picker = require "chord.picker"
local wezterm = require "wezterm" --[[@as Wezterm]]

local tconcat = table.concat

---@class Chord.Command
---@field id string
---@field label string
---@field action any
---@field lhs? string
---@field source string
---@field table_name? string
---@field binding_id? string

---@class Chord.CommandSpec
---@field id? string
---@field label? string
---@field desc? string
---@field lhs? string
---@field key? string
---@field mods? string
---@field action any

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

---@return Chord.Logger
local function logger()
  return Logger.new("Chord", config.get().log)
end

---@param opts? table
---@return table
local function command_options(opts)
  local cfg = shallow_copy(config.get().command or {})
  for key, value in pairs(opts or {}) do
    cfg[key] = value
  end
  return cfg
end

---@param input table<string, boolean>
---@return string[]
local function sorted_names(input)
  local names = {}
  for name in pairs(input or {}) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

---@param mods string|nil
---@return string
local function normalize_mods(mods)
  local parts = {}
  for mod in tostring(mods or ""):gmatch "[^|]+" do
    if mod ~= "" then
      parts[#parts + 1] = mod
    end
  end
  table.sort(parts)
  return tconcat(parts, "|")
end

---@param action any
---@return string
local function action_label(action)
  if type(action) == "string" then
    return action
  end

  if type(action) == "table" then
    local names = {}
    for key in pairs(action) do
      if type(key) == "string" and key:sub(1, 2) ~= "__" then
        names[#names + 1] = key
      end
    end
    table.sort(names)
    if names[1] then
      return names[1]
    end
  end

  return tostring(action)
end

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

---@param name any
---@return string|nil
local function normalize_source_name(name)
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
local function option_set(value, normalize)
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
---@param opts table
---@return boolean
local function source_enabled(source, opts)
  local sources = option_set(opts.sources, normalize_source_name)
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
---@param opts table
---@return boolean
local function table_allowed(table_name, opts)
  if not table_name then
    return true
  end

  local only = option_set(opts.tables)
  local excluded = option_set(opts.exclude_tables)
  if excluded and excluded[table_name] then
    return false
  end
  if only then
    return only[table_name] == true
  end
  return true
end

---@param source string
---@param entry table
---@param table_name? string
---@return string
local function binding_id(source, entry, table_name)
  local key = tostring(entry.key or "")
  local mods = normalize_mods(entry.mods)

  if source == "key_table" then
    return "table:" .. tostring(table_name or "") .. "|" .. mods .. "|" .. key
  end

  return "global|" .. mods .. "|" .. key
end

---@param core Chord
---@param source string
---@param entry table
---@param opts table
---@param table_name? string
---@return Chord.Command|nil
local function command_from_entry(core, source, entry, opts, table_name)
  if type(entry) ~= "table" or entry.action == nil or entry.key == nil then
    return nil
  end
  if entry.__chord_command_picker then
    return nil
  end

  local label = entry.desc or entry.label
  if not label or label == "" then
    if source ~= "default" and not opts.include_undocumented then
      return nil
    end
    label = action_label(entry.action)
  end

  local bind = binding_id(source, entry, table_name)
  local id = source .. ":" .. bind

  return {
    id = id,
    label = tostring(label),
    lhs = core.__entry_lhs(entry),
    action = entry.action,
    source = source,
    table_name = table_name,
    binding_id = bind,
  }
end

---@param core Chord
---@param spec Chord.CommandSpec
---@return Chord.Command|nil
local function registered_command(core, spec)
  if type(spec) ~= "table" then
    logger():error("cannot register command: expected table, got %s", type(spec))
    return nil
  end

  local label = spec.label or spec.desc or spec[3]
  local action = spec.action or spec.rhs or spec[2]
  if action == nil then
    logger():error "cannot register command without action"
    return nil
  end
  if not label or label == "" then
    logger():error "cannot register command without label"
    return nil
  end

  local entry
  if spec.key ~= nil or spec.lhs ~= nil or spec[1] ~= nil then
    entry = core.key(spec)
  end

  core._command_seq = core._command_seq + 1

  local cmd = {
    id = spec.id or ("registered:" .. core._command_seq),
    label = tostring(label),
    action = action,
    source = "registered",
  }

  if entry then
    cmd.action = entry.action
    cmd.lhs = core.__entry_lhs(entry)
    cmd.binding_id = binding_id("keys", entry)
  end

  return cmd
end

---@param commands Chord.Command[]
---@param seen table<string, boolean>
---@param opts table
---@param cmd Chord.Command|nil
local function add_command(commands, seen, opts, cmd)
  if not cmd then
    return
  end

  local dedupe_key = cmd.binding_id or cmd.id
  if opts.dedupe and seen[dedupe_key] then
    return
  end

  seen[dedupe_key] = true
  commands[#commands + 1] = cmd
end

---@param core Chord
---@param commands Chord.Command[]
---@param seen table<string, boolean>
---@param source string
---@param entries table[]
---@param opts table
---@param table_name? string
local function collect_entries(core, commands, seen, source, entries, opts, table_name)
  if not source_enabled(source, opts) or not table_allowed(table_name, opts) then
    return
  end

  for _, entry in ipairs(entries or {}) do
    add_command(commands, seen, opts, command_from_entry(core, source, entry, opts, table_name))
  end
end

---@param core Chord
---@param config_table table
---@param opts table
---@return table<string, boolean>
local function key_table_names(core, config_table, opts)
  local names = {}
  if not source_enabled("key_table", opts) then
    return names
  end

  if type(config_table.key_tables) == "table" then
    for name in pairs(config_table.key_tables) do
      if table_allowed(name, opts) then
        names[name] = true
      end
    end
  end

  if type(core._defs) == "table" then
    for name in pairs(core._defs) do
      if table_allowed(name, opts) then
        names[name] = true
      end
    end
  end

  return names
end

---@param core Chord
---@return table
return function(core)
  ---@class Chord.CommandApi
  local command = {}

  ---Clear commands registered through `chord.command.register`.
  ---@return nil
  function command.clear()
    core._registered_commands = {}
    core._command_seq = 0
    return nil
  end

  ---Register an action-only command or a key-backed command.
  ---@param spec Chord.CommandSpec
  ---@return Chord.Command|nil
  function command.register(spec)
    local cmd = registered_command(core, spec)
    if cmd then
      core._registered_commands[#core._registered_commands + 1] = cmd
    end
    return cmd
  end

  ---Register many commands.
  ---@param specs Chord.CommandSpec[]
  ---@return nil
  function command.register_many(specs)
    for _, spec in ipairs(specs or {}) do
      command.register(spec)
    end
    return nil
  end

  ---Collect commands from registered entries, config keys, key tables, and defaults.
  ---@param config_table table
  ---@param opts? table
  ---@return Chord.Command[]
  function command.collect(config_table, opts)
    local options = command_options(opts)
    local commands = {}
    local seen = {}
    config_table = config_table or {}

    if source_enabled("registered", options) then
      for _, cmd in ipairs(core._registered_commands or {}) do
        add_command(commands, seen, options, shallow_copy(cmd))
      end
    end

    collect_entries(core, commands, seen, "keys", config_table.keys or {}, options)

    for _, name in ipairs(sorted_names(key_table_names(core, config_table, options))) do
      collect_entries(
        core,
        commands,
        seen,
        "key_table",
        core.__resolve_entries(config_table, name),
        options,
        name
      )
    end

    if
      source_enabled("default", options)
      and wezterm.gui
      and type(wezterm.gui.default_keys) == "function"
    then
      collect_entries(core, commands, seen, "default", wezterm.gui.default_keys() or {}, options)
    end

    return commands
  end

  ---Return a WezTerm action that opens the command picker.
  ---@param config_table table
  ---@param opts? table
  ---@return table
  function command.action(config_table, opts)
    return wezterm.action_callback(function(window, pane)
      local options = command_options(opts)
      local commands = command.collect(config_table, options)
      local by_id = {}

      for _, cmd in ipairs(commands) do
        by_id[cmd.id] = cmd
      end

      window:perform_action(
        wezterm.action.InputSelector {
          title = options.title,
          choices = picker.choices(commands, options),
          fuzzy = options.fuzzy,
          description = options.description,
          fuzzy_description = options.fuzzy_description,
          alphabet = options.alphabet,
          action = wezterm.action_callback(function(inner_window, inner_pane, id)
            if not id then
              return
            end

            local cmd = by_id[id]
            if cmd then
              inner_window:perform_action(cmd.action, inner_pane or pane)
            end
          end),
        },
        pane
      )
    end)
  end

  ---Inject a trigger binding that opens the command picker.
  ---@param config_table table
  ---@param opts? table
  ---@return table
  function command.apply(config_table, opts)
    local options = command_options(opts)
    local action = command.action(config_table, options)

    config_table.keys = config_table.keys or {}
    local entry = core.key(options.key, action, options.desc)
    if entry then
      entry.__chord_command_picker = true
      config_table.keys[#config_table.keys + 1] = entry
    end

    return action
  end

  return command
end
