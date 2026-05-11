local wezterm = require "wezterm"
local act = wezterm.action

local chord = wezterm.plugin.require("file:///" .. wezterm.config_dir .. "/plugins/chord.wz")
local config = wezterm.config_builder and wezterm.config_builder() or {}

config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }

chord.setup {
  command = {
    style = {
      enabled = true,
      formatter = "wezterm",
      color_by = "mode",
      mode_colors = {
        resize_mode = { fg = "#1a1b26", bg = "#7aa2f7" },
      },
    },
  },
}

chord.command.register_many {
  {
    id = "reload-config",
    label = "Reload config",
    action = act.ReloadConfiguration,
  },
  {
    id = "debug-overlay",
    label = "Debug overlay",
    action = act.ShowDebugOverlay,
  },
}

chord.maps(config, {
  { "<leader>c", act.CopyTo "Clipboard", "copy" },
  { "<leader>v", act.PasteFrom "Clipboard", "paste" },
  { "<leader>n", act.SpawnWindow, "new window" },
})

local resize = chord.mode("resize_mode", {
  one_shot = false,
  meta = { i = "R", txt = "RESIZE", bg = "#7aa2f7" },
  keys = {
    { "h", act.AdjustPaneSize { "Left", 5 }, "left" },
    { "j", act.AdjustPaneSize { "Down", 5 }, "down" },
    { "k", act.AdjustPaneSize { "Up", 5 }, "up" },
    { "l", act.AdjustPaneSize { "Right", 5 }, "right" },
    { "<ESC>", act.PopKeyTable, "exit" },
  },
})

chord.tables(config, { resize })
config.keys[#config.keys + 1] = resize:activate("<leader>r", "resize mode")

chord.command.apply(config, {
  key = "<leader><Space>",
  title = "Chord commands",
  sources = { "registered", "keys", "key_table" },
  tables = { resize_mode = true },
})

chord.overlay.apply(config, {
  key = "<leader>?",
  title = "Chord help",
  sources = { "keys", "key_table" },
})

wezterm.on("augment-command-palette", function()
  return chord.command.palette(config, {
    prefix = "Chord: ",
    sources = { keys = true, key_tables = true },
    include_lhs = true,
  })
end)

for _, conflict in ipairs(chord.conflicts(config)) do
  wezterm.log_warn(("Chord conflict in %s: %s"):format(conflict.scope, conflict.lhs))
end

return config
