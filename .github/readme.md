# chord.wz

[![Awesome](https://awesome.re/mentioned-badge.svg)](https://github.com/michaelbrusegard/awesome-wezterm)
[![Tests](https://img.shields.io/github/actions/workflow/status/sravioli/chord.wz/tests.yaml?label=Tests&logo=Lua)](https://github.com/sravioli/chord.wz/actions?workflow=tests)
[![Lint](https://img.shields.io/github/actions/workflow/status/sravioli/chord.wz/lint.yaml?label=Lint&logo=Lua)](https://github.com/sravioli/chord.wz/actions?workflow=lint)
[![Coverage](https://img.shields.io/coverallsCoverage/github/sravioli/chord.wz?label=Coverage&logo=coveralls)](https://coveralls.io/github/sravioli/chord.wz)

Vim-style key notation, key tables, and hint bars for
[WezTerm](https://wezfurlong.org/wezterm/).

- Declare bindings with compact strings such as `<C-S-v>` and `<leader>p`
- Mix Vim-style entries with native WezTerm keymap tables
- Register modal key tables with display metadata
- Render paginated key-hint bars for active modes
- Apply user overrides for keys and key tables
- Use configurable aliases, modifiers, leader notation, and hint separators

## Installation

```lua
local wezterm = require "wezterm"

-- from git
local chord = wezterm.plugin.require "https://github.com/sravioli/chord.wz"

-- from a local checkout
local chord = wezterm.plugin.require("file:///" .. wezterm.config_dir .. "/plugins/chord.wz")
```

Chord loads one plugin dependency automatically:

- [`memo.wz`](https://github.com/sravioli/memo.wz) for hint pagination state

Chord can also use optional plugin dependencies when their features need them:

- [`log.wz`](https://github.com/sravioli/log.wz) for tagged internal logging
- [`ribbon.wz`](https://github.com/sravioli/ribbon.wz) for `hint_layout()` and
  command picker labels when `formatter = "ribbon"`

If an optional plugin is unavailable, Chord falls back where possible:
`log.wz` falls back to WezTerm's native `wezterm.log_*` functions, and command
picker labels fall back to `wezterm.format`.

<!--
### Type annotations

Chord ships LuaCATS annotations. After installing
[wezterm-types](https://github.com/DrKJeff16/wezterm-types), annotate the import
to get completion and type checking:

```lua
---@type Chord
local chord = wezterm.plugin.require "https://github.com/sravioli/chord.wz"
```
-->

## Setup

```lua
local chord = wezterm.plugin.require "https://github.com/sravioli/chord.wz"

chord.setup {
  aliases = {
    CR = "Enter",
    ESC = "Escape",
  },
  modifiers = {
    C = "CTRL",
    S = "SHIFT",
    A = "ALT",
    M = "ALT",
    W = "SUPER",
  },
  hints = {
    separator = " / ",
  },
  command = {
    key = "<leader><Space>",
    title = "Commands",
    include_defaults = false,
  },
}
```

`setup()` is optional. Defaults are ready for the usual Vim-style notation.

## Keymaps

`chord.maps(config, mappings)` appends normalized entries to `config.keys`.
Each item can be Vim-style, native WezTerm-style, or a named Lua table.

```lua
local act = wezterm.action

chord.maps(config, {
  { "<C-S-c>", act.CopyTo "Clipboard", "copy" },
  { "<C-S-v>", act.PasteFrom "Clipboard", "paste" },
  { "<leader>p", act.ActivateCommandPalette, "command palette" },

  -- Native WezTerm entries pass through.
  {
    key = "f",
    mods = "CTRL|SHIFT",
    action = act.Search "CurrentSelectionOrEmptyString",
    desc = "search",
  },

  -- Named fields are accepted too.
  {
    lhs = "<M-CR>",
    action = act.ToggleFullScreen,
    desc = "fullscreen",
  },
})
```

Use `chord.key(lhs_or_spec, action?, desc?)` when you need a single normalized
entry, and `chord.table(mappings)` when you need a standalone key table.

## Key tables

`chord.tables(config, defs)` registers modal key tables and keeps their metadata
available for status bars or prompts.

```lua
chord.tables(config, {
  resize_mode = {
    meta = { i = "R", txt = "RESIZE", bg = "#7aa2f7" },
    keys = {
      { "h", act.AdjustPaneSize { "Left", 5 }, "left" },
      { "j", act.AdjustPaneSize { "Down", 5 }, "down" },
      { "k", act.AdjustPaneSize { "Up", 5 }, "up" },
      { "l", act.AdjustPaneSize { "Right", 5 }, "right" },
      { "<ESC>", "PopKeyTable", "exit" },
    },
  },
})
```

Definitions can also be functions. Chord passes the active theme to them when
metadata is requested:

```lua
chord.tables(config, {
  window_mode = function(theme)
    return {
      meta = { i = "W", txt = "WINDOW", bg = theme.brights[3] },
      keys = {
        { "n", act.SpawnWindow, "new window" },
      },
    }
  end,
})
```

Use `chord.mode()` when you want the key-table definition and activation
binding to stay together:

```lua
local resize = chord.mode("resize_mode", {
  one_shot = false,
  meta = { i = "R", txt = "RESIZE", bg = "#7aa2f7" },
  keys = {
    { "h", act.AdjustPaneSize { "Left", 5 }, "left" },
    { "l", act.AdjustPaneSize { "Right", 5 }, "right" },
  },
})

chord.tables(config, { resize })
config.keys[#config.keys + 1] = resize:activate("<leader>r", "resize mode")
```

## Hints

Chord can render a fixed-width hint string for the current key table:

```lua
local text = chord.hint(config, "resize_mode", 80, window)
```

For styled status bars, use `hint_layout()`. It returns a
[`ribbon.wz`](https://github.com/sravioli/ribbon.wz) instance, so callers that
understand Ribbon can format it directly.

```lua
local hint = chord.hint_layout(config, active_mode, width, window, {
  theme = theme,
  mode_bg = "#7aa2f7",
})
```

Add `hint_action()` bindings to page through long hint bars:

```lua
{ "<C-S-A-Left>", chord.hint_action(nil, -1), "" },
{ "<C-S-A-Right>", chord.hint_action(nil, 1), "" },
```

## Command picker

Chord can open a searchable command picker for your keybindings. It discovers
described entries from `config.keys` and `config.key_tables`, plus commands you
register explicitly.

```lua
chord.command.register {
  id = "ssh-prod",
  label = "SSH: production",
  action = act.SpawnCommandInNewTab { args = { "ssh", "prod" } },
}

chord.command.apply(config, {
  key = "<leader><Space>",
  title = "Commands",
})
```

Call `chord.command.apply(config, opts)` after your keys and key tables are in
place. The picker snapshots the config when it opens, so entries added later are
still visible as long as they are present in the same config table.

By default, Chord shows only entries with descriptions. Enable undocumented
entries or WezTerm defaults when you want a broader, noisier picker:

```lua
chord.command.apply(config, {
  include_undocumented = true,
  include_defaults = true,
})
```

Filter the picker by command source or key table:

```lua
chord.command.apply(config, {
  sources = { "key_table" },
  tables = { "resize_mode", "window_mode" },
})
```

Sources are `registered`, `keys`, `key_table`, and `default`. Chord also accepts
`global` for `keys`, `tables` or `key_tables` for `key_table`, and `defaults`
for `default`.

Enable styled labels when you want picker rows to show mode or source context.
Plain labels remain the default.

```lua
chord.command.apply(config, {
  style = {
    enabled = true,
    formatter = "wezterm",
    color_by = "mode",
    mode_colors = {
      resize_mode = { fg = "#1a1b26", bg = "#7aa2f7" },
      window_mode = { fg = "#1a1b26", bg = "#bb9af7" },
    },
  },
})
```

`formatter = "wezterm"` uses `wezterm.format` directly. `formatter = "ribbon"`
uses `ribbon.wz` when available and falls back to `wezterm.format` with a
warning when it is not.

Generate command-palette entries from the same command metadata:

```lua
wezterm.on("augment-command-palette", function()
  return chord.command.palette(config, {
    prefix = "Chord: ",
    sources = { "keys", "key_table" },
  })
end)
```

Chord returns entries only; it does not register WezTerm events for you.

## Help overlay

Use `chord.overlay.apply()` to bind a searchable help overlay built from Chord
commands:

```lua
chord.overlay.apply(config, {
  key = "<leader>?",
  title = "Leader keys",
  sources = { "keys", "key_table" },
})
```

The first overlay implementation uses WezTerm's `InputSelector` and groups rows
by global keys, registered commands, defaults, or key-table name.

## Overrides

`apply_overrides()` is useful when your configuration has a user override layer.
It can disable, override, and add mappings without rebuilding the whole config.

```lua
chord.apply_overrides(config, {
  keys = {
    disable = { "<C-S-c>" },
    override = {
      ["<C-S-v>"] = { act.PasteFrom "PrimarySelection", "paste primary" },
    },
    add = {
      { "<leader>x", act.ShowDebugOverlay, "debug" },
    },
  },
  key_tables = {
    resize_mode = {
      disable = { "h" },
      add = {
        { "H", act.AdjustPaneSize { "Left", 10 }, "left fast" },
      },
    },
  },
})
```

## Conflict diagnostics

`conflicts()` reports duplicate bindings without changing runtime behavior:

```lua
local conflicts = chord.conflicts(config)
for _, conflict in ipairs(conflicts) do
  wezterm.log_warn(conflict.scope .. " duplicates " .. conflict.lhs)
end
```

Conflicts are grouped by scope, key, and modifiers. Global keys and each key
table are checked independently.

## API

| Function                          | Description                                      |
| --------------------------------- | ------------------------------------------------ |
| `setup(opts?)`                    | Merge user options with defaults.                |
| `validate(lhs)`                   | Validate Vim-style key notation.                 |
| `normalize(lhs)`                  | Convert Vim-style notation to `{ key, mods }`.   |
| `key(lhs_or_spec, action?, desc?)`| Build one WezTerm key entry.                     |
| `map(lhs_or_spec, action, target)`| Append one entry to a target table.              |
| `map_batch(mappings, target)`     | Append many entries to a target table.           |
| `table(mappings)`                 | Build a WezTerm key table.                       |
| `maps(config, mappings)`          | Append mappings to `config.keys`.                |
| `tables(config, defs)`            | Register `config.key_tables` and mode metadata.  |
| `mode(name, def)`                 | Create a key-table helper with activation.       |
| `get_modes(theme)`                | Return metadata for registered key tables.       |
| `apply_overrides(config, specs)`  | Apply user key and key-table overrides.          |
| `conflicts(config, opts?)`        | Report duplicate bindings without applying them. |
| `hint(config, name, width, win)`  | Render plain fixed-width hints.                  |
| `hint_layout(...)`                | Render styled hints as a Ribbon instance.        |
| `hint_action(name, direction)`    | Return an action callback for hint pagination.   |
| `command.register(spec)`          | Register an action-only or key-backed command.   |
| `command.register_many(specs)`    | Register multiple commands.                      |
| `command.collect(config, opts?)`  | Collect commands from config and registrations.  |
| `command.action(config, opts?)`   | Return an action that opens the command picker.  |
| `command.apply(config, opts?)`    | Add a trigger binding for the command picker.    |
| `command.palette(config, opts?)`  | Generate `augment-command-palette` entries.      |
| `command.clear()`                 | Clear explicitly registered commands.            |
| `overlay.action(config, opts?)`   | Return an action that opens the help overlay.    |
| `overlay.apply(config, opts?)`    | Add a trigger binding for the help overlay.      |

## License

Code is licensed under the [GNU General Public License v2](../LICENSE).
Documentation is licensed under
[Creative Commons Attribution-NonCommercial 4.0 International](../LICENSE-DOCS).
