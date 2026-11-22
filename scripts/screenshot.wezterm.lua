-- Minimal WezTerm config for `scripts/screenshots.sh`: a window with a small
-- bar from mosaic.wz (https://github.com/sravioli/mosaic.wz) in the kanagawa
-- scheme ($CHORD_KANAGAWA: "wave" dark, "lotus" light) of the kanagawa plugin
-- (https://github.com/kanagawa-community/wezterm) and the scene named by $CHORD_SCENE open. Settings come from the
-- environment so the script stays the only place that knows the defaults.
local wezterm = require "wezterm"
local act = wezterm.action

local repo = assert(os.getenv "CHORD_REPO", "CHORD_REPO is not set")
local scene = assert(os.getenv "CHORD_SCENE", "CHORD_SCENE is not set")
-- Bar-only scenes: an undecorated one-row window the script crops to the bar.
local bar_only = scene:match "^mode_" ~= nil
for _, name in ipairs { "mosaic", "warp", "warden", "sigil", "memo" } do
  local base = repo .. "/../" .. name .. ".wz/plugin/"
  package.path = base .. "?.lua;" .. base .. "?/init.lua;" .. package.path
end
package.path = repo .. "/plugin/?.lua;" .. repo .. "/plugin/?/init.lua;" .. package.path

local kanagawa = wezterm.plugin.require "https://github.com/kanagawa-community/wezterm"

local chord = require "chord.api"
local mosaic = require "mosaic.api"
mosaic.setup {
  preset = bar_only and "powerline" or "minimal",
  position = "top",
  layout = { left = { "chord.mode", "workspace" }, right = { "chord.hints", "clock" } },
}

local config = wezterm.config_builder()
config.font = wezterm.font_with_fallback {
  os.getenv "CHORD_FONT" or "FiraCode Nerd Font",
  "Symbols Nerd Font",
}
config.font_size = tonumber(os.getenv "CHORD_FONT_SIZE" or 14)
config.initial_cols = tonumber(os.getenv "CHORD_COLS" or 100)
config.initial_rows = tonumber(os.getenv "CHORD_ROWS" or 30)
config.enable_wayland = false -- XWayland: KDE draws the frame and title bar
config.window_decorations = "TITLE | RESIZE"
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.enable_scroll_bar = false
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 24
config.check_for_updates = false
-- The scheme first: mosaic draws the new-tab button in the scheme set when it is applied.
kanagawa.apply_to_config(config, { scheme = os.getenv "CHORD_KANAGAWA" or "wave" })
mosaic.apply_to_config(config)
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }
chord.setup {
  command = {
    style = {
      enabled = true,
      formatter = "wezterm",
      color_by = "mode",
      mode_colors = {
        copy_mode = { fg = "#16161d", bg = "#98bb6c" },
        search_mode = { fg = "#16161d", bg = "#e6c384" },
      },
    },
  },
}
local icon = require("sigil.api").symbol "Modes"

local function hint_page(direction)
  return act.Multiple { chord.hint_action(nil, direction), act.EmitEvent "chord-hint-page-changed" }
end
local pages = {
  { "<C-S-A-Left>", hint_page(-1), "" },
  { "<C-S-A-Right>", hint_page(1), "" },
}
-- Modes: name -> { meta, keys }, keys without the hint paging and exit keys.
local function mode(name, meta, keys)
  return chord.mode(name, function(theme)
    local m = meta(theme)
    local all = { { "<ESC>", act.PopKeyTable, "exit" }, pages[1], pages[2] }
    for _, k in ipairs(keys) do
      all[#all + 1] = k
    end
    return { meta = m, keys = all }
  end)
end

local modes = {
  copy_mode = mode("copy_mode", function(theme)
    return { i = icon.copy, txt = "COPY", bg = theme.brights[3], pad = 5 }
  end, {
    { "y", act.CopyTo "ClipboardAndPrimarySelection", "copy selection" },
    { "h", act.CopyMode "MoveLeft", "left" },
    { "j", act.CopyMode "MoveDown", "down" },
    { "k", act.CopyMode "MoveUp", "up" },
    { "l", act.CopyMode "MoveRight", "right" },
    { "b", act.CopyMode "MoveBackwardWord", "word ←" },
    { "e", act.CopyMode "MoveForwardWordEnd", "word end" },
    { "w", act.CopyMode "MoveForwardWord", "word →" },
    { "0", act.CopyMode "MoveToStartOfLine", "line start" },
    { "G", act.CopyMode "MoveToScrollbackBottom", "bot" },
    { "g", act.CopyMode "MoveToScrollbackTop", "top" },
    { "V", act.CopyMode { SetSelectionMode = "Line" }, "line mode" },
    { "v", act.CopyMode { SetSelectionMode = "Cell" }, "cell mode" },
    { "<C-v>", act.CopyMode { SetSelectionMode = "Block" }, "block mode" },
  }),
  search_mode = mode("search_mode", function(theme)
    return { i = icon.search, txt = "SEARCH", bg = theme.brights[4], pad = 5 }
  end, {
    { "<C-n>", act.CopyMode "NextMatch", "next" },
    { "<C-N>", act.CopyMode "PriorMatch", "prev" },
    { "<C-r>", act.CopyMode "CycleMatchType", "cycle type" },
    { "<C-u>", act.CopyMode "ClearPattern", "clear" },
    { "<PageUp>", act.CopyMode "PriorMatchPage", "prev page" },
    { "<PageDown>", act.CopyMode "NextMatchPage", "next page" },
  }),
}
local list = {}
for _, m in pairs(modes) do
  list[#list + 1] = m
end
chord.tables(config, list)

chord.command.register_many {
  { id = "reload-config", label = "Reload config", action = act.ReloadConfiguration },
  { id = "debug-overlay", label = "Debug overlay", action = act.ShowDebugOverlay },
  { id = "new-window", label = "New window", action = act.SpawnWindow },
}
local sources = { "registered", "key_table" }
local tables = {}
for name in pairs(modes) do
  tables[name] = true
end
local commands =
  chord.command.action(config, { title = "Chord commands", sources = sources, tables = tables })
local help = chord.overlay.action(config, { title = "Chord help", sources = sources })

if bar_only then
  config.window_decorations = "NONE"
  config.initial_cols = tonumber(os.getenv "CHORD_BAR_COLS" or 140)
  config.initial_rows = 1 -- the bar plus one row; the script keeps only the bar
  config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
end

-- The title bar names the feature on show.
wezterm.on("format-window-title", function()
  return "chord: " .. scene
end)

-- Pane content that stays open: fastfetch with a config that prints a logo and
-- colour blocks only, so nothing about the machine the shots are taken on shows.
local demo =
  { "sh", "-c", ("fastfetch -c %q; exec sleep 100000"):format(repo .. "/scripts/fastfetch.jsonc") }

-- scene name -> function(window, pane) that opens it.
local scenes = {
  command = function(w, p)
    w:perform_action(commands, p)
  end,
  help = function(w, p)
    w:perform_action(help, p)
  end,
  -- The modes' hints fill the bar. Copy and search are WezTerm's own modes.
  mode_copy = function(w, p)
    w:perform_action(act.ActivateCopyMode, p)
  end,
  mode_search = function(w, p)
    w:perform_action(act.Search "CurrentSelectionOrEmptyString", p)
  end,
}

wezterm.on("gui-startup", function()
  local tab, pane, window = wezterm.mux.spawn_window { args = demo, cwd = wezterm.home_dir }
  tab:set_title "dotfiles"
  -- A split with some output behind the overlay, and two more tabs for the bar.
  if not bar_only then
    pane:split { direction = "Right", args = demo }
  end
  pane:activate()
  for _, title in ipairs { "notes", "build" } do
    window:spawn_tab({ cwd = wezterm.home_dir }):set_title(title)
  end
  tab:activate()
  -- The GUI window exists only after startup returns.
  wezterm.time.call_after(1, function()
    scenes[scene](window:gui_window(), pane)
  end)
end)

return config
