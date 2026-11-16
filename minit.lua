---Minimal config for bug reports. Run it in isolation from your own config:
---
---    wezterm --config-file minit.lua
---
---Put your reproduction below the marker. Keep it as small as possible and
---paste the edited file into the bug report.
local wezterm = require "wezterm"
local chord = wezterm.plugin.require "https://github.com/sravioli/chord.wz"
local config = wezterm.config_builder()

-- Edit below this line --------------------------------------------------------

config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }
chord.maps(config, {
  { "<leader>d", wezterm.action.ShowDebugOverlay, "debug overlay" },
})

return config
