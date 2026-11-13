# chord.wz

[![Awesome](https://awesome.re/mentioned-badge.svg)](https://github.com/michaelbrusegard/awesome-wezterm)
[![Tests](https://img.shields.io/github/actions/workflow/status/sravioli/chord.wz/tests.yaml?style=flat-square&label=tests)](https://github.com/sravioli/chord.wz/actions/workflows/tests.yaml)
[![Lint](https://img.shields.io/github/actions/workflow/status/sravioli/chord.wz/lint.yaml?style=flat-square&label=lint)](https://github.com/sravioli/chord.wz/actions/workflows/lint.yaml)
[![Coverage](https://img.shields.io/coverallsCoverage/github/sravioli/chord.wz?label=Coverage&logo=coveralls)](https://coveralls.io/github/sravioli/chord.wz)
[![Code license](https://img.shields.io/badge/code-GPL--2.0-blue?style=flat-square)](../LICENSE)
[![Docs license](https://img.shields.io/badge/docs-CC_BY--NC_4.0-blue?style=flat-square)](../LICENSE-DOCS)

Vim-style mappings, modal hints, and command discovery for [WezTerm](https://wezterm.org/).

Keep actions and descriptions together, then reuse them in key tables,
searchable pickers, and your status renderer. Native WezTerm entries can live
alongside compact mappings, and user overrides can modify either form.

[Quick start](#quick-start) · [Usage](#usage) · [Configuration](#configuration) · [API reference](#api-reference) · [Troubleshooting](#troubleshooting) · [Development](#development) · [License](#license)

## Quick start

### Requirements

Requires **WezTerm [`20240127-113634-bbcac864`](https://wezterm.org/config/lua/keyassignment/InputSelector.html)
or newer** and Git. Without command/help pickers,
[`20230320-124340-559cb7b0`](https://wezterm.org/config/lua/wezterm.plugin/require.html)
or newer is sufficient. No nightly build or special font is required.

Automatically loads [warp.wz](https://github.com/sravioli/warp.wz), plus
[memo.wz](https://github.com/sravioli/memo.wz) for pagination.
[log.wz](https://github.com/sravioli/log.wz) is optional, with native logging
as the fallback. `hint_layout` requires [ribbon.wz](https://github.com/sravioli/ribbon.wz);
command-label formatting falls back to `wezterm.format` without it.
Local API modules take precedence over remote plugins.

### Install and run

Put this in `wezterm.lua`:

```lua
local wezterm = require "wezterm"
local chord = wezterm.plugin.require "https://github.com/sravioli/chord.wz"
local config = wezterm.config_builder()

config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }
chord.maps(config, {
  { "<leader>d", wezterm.action.ShowDebugOverlay, "debug overlay" },
})

return config
```

Press **Ctrl+Space**, release, then press **d** within one second to open
the debug overlay. In an existing config, reuse its builder and leader, and add
the mapping before its final return.

## Usage

### Define a persistent mode

After the imports and leader configuration:

```lua
local resize = chord.mode("resize", {
  meta = { i = "R", txt = "RESIZE", bg = "#7aa2f7" },
  keys = {
    { "h", wezterm.action.AdjustPaneSize { "Left", 5 }, "left" },
    { "l", wezterm.action.AdjustPaneSize { "Right", 5 }, "right" },
    { "<ESC>", wezterm.action.PopKeyTable, "exit" },
  },
})
chord.tables(config, { resize })
chord.maps(config, { resize:activate("<leader>r", "resize") })
```

Press leader, then `r`; `h`/`l` resize until Esc. Register all mode definitions
in one `tables` call: later calls replace Chord's metadata registry, even though
unrelated native config tables can remain.
Definitions may be `function(theme)` returning `{ meta, keys }`; use theme
colors in metadata, not in startup actions that need actual color values.

### Discover commands and apply user overrides

```lua
chord.command.register {
  id = "reload",
  label = "Reload config",
  action = wezterm.action.ReloadConfiguration,
}
chord.apply_overrides(config, {
  keys = { add = { { "<leader>x", wezterm.action.SpawnWindow, "new window" } } },
})
chord.command.apply(config)
chord.overlay.apply(config)
```

Leader then Space opens commands; leader then `?` opens grouped help.
Type to search, Enter to execute, Esc to cancel. The selected action executes
directly; selecting a key-table command does not first activate that table.
Registration adds command metadata, not a physical key binding.

Chord applies `disable`, `override`, and `add` in that order. Replacement values
can be `{ action, description }`. Apply overrides after mappings and tables, before
picker bindings. The complete [command workflow example](../examples/command-workflows.lua)
also shows filters, palette entries, styling, and conflict diagnostics.

### Render hints in an existing status bar

In your window status callback, get a table name from
`window:active_key_table()` and call `chord.hint(config, name, width, window)`.
`name = nil` means global keys. Supply only the remaining column budget,
not the whole terminal width. The returned plain string fills that width.
`hint_layout` instead needs `{ theme, mode_bg }` and returns a Ribbon.

Add `chord.hint_action(nil, -1)` and `chord.hint_action(nil, 1)` bindings to
the active table for paging. Paging stops at either end; resizing clamps the page.
Only described entries appear; tiny budgets may show only an indicator or
spaces. You supply the status bar; Chord does not enable or install one.

For temporary pickers, call `chord.temporary.begin(window, pane, def)` with
`def = { name, keys, meta }`, where keys are the actual described bindings and
meta is a table or `function(theme)`. Keep its returned `release` function.
The picker remains responsible for registering, activating, and popping its
native table. Release before accepting, canceling, dispatching, handling an
error, or reopening.

The host renderer must prefer `temporary.get(window, theme)` over ordinary
mode metadata and refresh on `chord-temporary-changed` and
`chord-hint-page-changed`, both emitted with window and pane. Chord returns
a temporary session only while its table is active. Releasing twice is safe,
and an old release cannot clear a newer session. Hints require both the host
adapter and a visible bar.

## Configuration

### Example

Setup is optional. Call it before normalizing mappings or registering tables:

```lua
chord.setup {
  hints = { separator = " | " },
  command = {
    sources = { "keys", "key_table" },
    style = { enabled = true, formatter = "wezterm" },
  },
}
```

These values override the defaults. Set the physical leader separately through
`config.leader`; Chord's setup does not create it.

### Options

#### Plugin and picker settings

Aliases and modifiers are extensible maps. Custom keys merge with these
defaults; complete option types live in [config.lua](../plugin/chord/config.lua).

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `aliases.CR` | `string` | `"Enter"` | Return/Enter. |
| `aliases.BS` | `string` | `"Backspace"` | Backspace. |
| `aliases.ESC` | `string` | `"Escape"` | Escape. |
| `aliases.Bar` | `string` | `"\|"` | Literal pipe. |
| `aliases.Space` | `string` | `" "` | Literal space. |
| `aliases.Up` | `string` | `"UpArrow"` | Up arrow. |
| `aliases.Down` | `string` | `"DownArrow"` | Down arrow. |
| `aliases.Left` | `string` | `"LeftArrow"` | Left arrow. |
| `aliases.Right` | `string` | `"RightArrow"` | Right arrow. |
| `aliases.k0` | `string` | `"Numpad0"` | Keypad zero. |
| `aliases.k1` | `string` | `"Numpad1"` | Keypad one. |
| `aliases.k2` | `string` | `"Numpad2"` | Keypad two. |
| `aliases.k3` | `string` | `"Numpad3"` | Keypad three. |
| `aliases.k4` | `string` | `"Numpad4"` | Keypad four. |
| `aliases.k5` | `string` | `"Numpad5"` | Keypad five. |
| `aliases.k6` | `string` | `"Numpad6"` | Keypad six. |
| `aliases.k7` | `string` | `"Numpad7"` | Keypad seven. |
| `aliases.k8` | `string` | `"Numpad8"` | Keypad eight. |
| `aliases.k9` | `string` | `"Numpad9"` | Keypad nine. |
| `aliases.lt` | `string` | `"<"` | Literal opening bracket. |
| `aliases.gt` | `string` | `">"` | Literal closing bracket. |
| `aliases.PageUp` | `string` | `"PageUp"` | Native name retained. |
| `aliases.PageDown` | `string` | `"PageDown"` | Native name retained. |
| `aliases.F1` | `string` | `"F1"` | Native function-key name retained. |
| `aliases.F2` | `string` | `"F2"` | Native function-key name retained. |
| `aliases.F3` | `string` | `"F3"` | Native function-key name retained. |
| `aliases.F4` | `string` | `"F4"` | Native function-key name retained. |
| `aliases.F5` | `string` | `"F5"` | Native function-key name retained. |
| `aliases.F6` | `string` | `"F6"` | Native function-key name retained. |
| `aliases.F7` | `string` | `"F7"` | Native function-key name retained. |
| `aliases.F8` | `string` | `"F8"` | Native function-key name retained. |
| `aliases.F9` | `string` | `"F9"` | Native function-key name retained. |
| `aliases.F10` | `string` | `"F10"` | Native function-key name retained. |
| `aliases.F11` | `string` | `"F11"` | Native function-key name retained. |
| `aliases.F12` | `string` | `"F12"` | Native function-key name retained. |
| `modifiers.C` | `string` | `"CTRL"` | Control shorthand. |
| `modifiers.S` | `string` | `"SHIFT"` | Shift shorthand. |
| `modifiers.A` | `string` | `"ALT"` | Alt shorthand. |
| `modifiers.M` | `string` | `"ALT"` | Alternate Alt shorthand. |
| `modifiers.W` | `string` | `"SUPER"` | Super/Windows/Command shorthand. |
| `leader` | `string` | `"<leader>"` | Compatibility setting; the current parser recognizes literal `<leader>` case-insensitively, not a custom token. |
| `hints.separator` | `string` | `" / "` | Separator between hint entries. |
| `hints.page_cache_prefix` | `string` | `"chord_hint_page"` | Memo key prefix; pages are scoped by window, pane, and table. |
| `log.enabled` | `boolean` | `true` | Internal diagnostics switch. |
| `log.threshold` | `string\|integer` | `"warn"` | Case-insensitive level or numeric threshold. |
| `command.key` | `string` | `"<leader><Space>"` | Binding added by `command.apply`, not by setup. |
| `command.desc` | `string` | `"command picker"` | Trigger description. |
| `command.title` | `string` | `"Commands"` | Picker title. |
| `command.fuzzy` | `boolean` | `true` | Start in fuzzy mode. |
| `command.description` | `string` | `"Select command."` | Exact-mode description. |
| `command.fuzzy_description` | `string` | `"Search: "` | Fuzzy prompt. |
| `command.alphabet` | `string?` | `nil` | Leave shortcut alphabet selection to WezTerm. |
| `command.include_registered` | `boolean` | `true` | Include explicit commands when no `sources` filter is supplied. |
| `command.include_keys` | `boolean` | `true` | Include described global keys. |
| `command.include_key_tables` | `boolean` | `true` | Include described modal keys. |
| `command.include_defaults` | `boolean` | `false` | Include `wezterm.gui.default_keys()` when available. |
| `command.include_undocumented` | `boolean` | `false` | Derive labels for undescribed non-default bindings. |
| `command.dedupe` | `boolean` | `true` | Keep the first matching binding/command identity. |
| `command.sources` | `string[]\|table<string, boolean>?` | `nil` | Explicit source allowlist; overrides the four include-source flags. Empty means no sources. |
| `command.tables` | `string[]\|table<string, boolean>?` | `nil` | Allow only these key tables; does not filter globals. |
| `command.exclude_tables` | `string[]\|table<string, boolean>?` | `nil` | Exclude named tables; exclusion wins over inclusion. |
| `command.style.enabled` | `boolean` | `false` | Add source/table badges. |
| `command.style.formatter` | `"plain"\|"wezterm"\|"ribbon"` | `"plain"` | Label formatter; plain badges have no color. |
| `command.style.color_by` | `"mode"\|"source"\|"none"` | `"mode"` | Mode colors fall back to source colors. |
| `command.style.include_source` | `boolean` | `true` | Show source badge when no table badge is selected. |
| `command.style.include_table` | `boolean` | `true` | Prefer key-table name badges. |
| `command.style.mode_fg` | `string?` | `nil` | Foreground fallback for metadata-derived mode colors. |
| `command.style.mode_colors` | `table<string, Chord.ColorSpec>` | `{}` | Explicit per-mode `{ fg?, bg? }` colors. |
| `command.style.source_colors.registered` | `Chord.ColorSpec` | `{ fg = "#c0caf5", bg = "#414868" }` | Registered-command badge colors. |
| `command.style.source_colors.keys` | `Chord.ColorSpec` | `{ fg = "#1a1b26", bg = "#9ece6a" }` | Global-key badge colors. |
| `command.style.source_colors.key_table` | `Chord.ColorSpec` | `{ fg = "#1a1b26", bg = "#7aa2f7" }` | Modal-key badge colors. |
| `command.style.source_colors.default` | `Chord.ColorSpec` | `{ fg = "#1a1b26", bg = "#e0af68" }` | Default-key badge colors. |
| `command.theme` | `table?` | `nil` | Theme used for mode metadata during collection. |
| `command.prefix` | `string` | `"Chord: "` | Effective palette-entry prefix; used by `command.palette`. |
| `command.include_lhs` | `boolean` | `true` | Include key notation in palette entries. |
| `command.icon` | `string?` | `nil` | Optional palette-entry icon. |
| `overlay.key` | `string` | `"<leader>?"` | Binding added by `overlay.apply`. |
| `overlay.desc` | `string` | `"key help"` | Trigger description. |
| `overlay.title` | `string` | `"Chord help"` | Grouped-help title. |
| `overlay.fuzzy` | `boolean` | `true` | Initial search mode. |
| `overlay.description` | `string` | `"Select command."` | Exact-mode description. |
| `overlay.fuzzy_description` | `string` | `"Search: "` | Fuzzy prompt. |
| `overlay.alphabet` | `string?` | `nil` | Native shortcut alphabet. |
| `overlay.sources` | `string[]\|table<string, boolean>?` | `nil` | Source filter, with the same aliases as commands. |
| `overlay.tables` | `string[]\|table<string, boolean>?` | `nil` | Table allowlist. |
| `overlay.exclude_tables` | `string[]\|table<string, boolean>?` | `nil` | Table exclusions. |

Sources are `registered`, `keys`, `key_table`, `default`. Aliases are
`global→keys`, `tables/key_tables→key_table`, `defaults→default`.
Per-call command/overlay options omit the leading `command.`/`overlay.`.
Help collection inherits the command inclusion/dedupe defaults unless overridden.

#### Per-call rendering, activation, and diagnostics

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `hint_layout.theme` | `table` | Required | Palette with `foreground`, `tab_bar.background`, and optional `brights`. |
| `hint_layout.mode_bg` | `string` | Required | Accent color for key labels. |
| `activate.one_shot` | `boolean` | `false` | Override the mode definition's `one_shot`; absent in both means persistent. |
| `activate.replace_current` | `boolean?` | `nil` | Forward to native `ActivateKeyTable` when supplied. |
| `activate.until_unknown` | `boolean?` | `nil` | Forward to native `ActivateKeyTable` when supplied. |
| `activate.timeout_milliseconds` | `integer?` | `nil` | Native activation timeout in milliseconds. |
| `conflicts.include_key_tables` | `boolean` | `true` | Inspect modal tables as well as global keys. |
| `conflicts.include_descriptions` | `boolean` | `true` | Include descriptions in conflict entries. |

### Behavior and precedence

Setup resets settings to defaults plus overrides, merges nested maps, and
replaces lists. It refreshes parser references and caches without rebuilding
existing config entries. Chord does not schema-validate unknown settings.
It generally logs and skips invalid mappings; `validate`/`normalize` return
explicit diagnostics.

Compact entries are `{ lhs, action, description? }`; named entries use
`{ lhs, action, desc? }`, and native `{ key, mods?, action, desc? }` tables
are shallow-copied. `<leader>` is a modifier prefix, not an arbitrary
multi-key sequence grammar. Use `C`, `S`, `A`/`M`, and `W` inside brackets.

Chord collects explicit registrations, global keys, tables sorted by name,
then native defaults. Deduplication keeps the first identity. `apply` appends
a trigger each time; do not repeatedly apply it to the same builder.
Picker actions retain the config table and collect when opened.

Settings, mode definitions, commands, and temporary sessions are Lua-local.
Memo-backed page positions survive config reloads within the running process.
Overrides copy entry tables, but actions and nested references can remain shared.
Conflict reporting is diagnostic only; it never resolves duplicates for you.

## API reference

`?` marks optional arguments or nullable results. Actions are WezTerm key
assignments. Underscore-prefixed helpers are internal.

### Mappings, modes, and hints

| Signature → Return type | Description |
| --- | --- |
| `chord.setup(options?) → Chord` | Configure and return the module. |
| `chord.config() → Chord.Config` | Return live settings; not a configuration submodule. |
| `chord.validate(lhs) → boolean, string?` | Validate key notation without adding a binding. |
| `chord.normalize(lhs) → table?, string?` | Return `{ key, mods? }`, or `nil` plus a diagnostic. |
| `chord.key(lhs_or_spec, action?, description?) → table?` | Normalize one compact/named/native entry; invalid entries log and return `nil`. |
| `chord.map(lhs_or_spec, action, target) → nil` | Append one valid entry to a supplied list. |
| `chord.map_batch(mappings, target) → nil` | Append valid entries, logging skipped ones. |
| `chord.table(mappings) → table[]` | Build a standalone native key list. |
| `chord.maps(config, mappings) → nil` | Append to `config.keys`, creating it when absent. |
| `chord.tables(config, definitions) → nil` | Register native tables and replace the metadata registry. Accept named definitions or mode objects. |
| `chord.mode(name, definition) → Chord.Mode` | Package a table/function definition with activation support. |
| `mode:activate(lhs, description?, options?) → table?` | Build an activation binding; does not register the table itself. |
| `chord.get_modes(theme) → table<string, Chord.KeyMeta>` | Get cached metadata `{ i, txt, bg, pad?, name? }`; theme functions can be reevaluated. |
| `chord.apply_overrides(config, specs) → nil` | Modify keys/tables using disable, replacement, addition, and enable gates. |
| `chord.conflicts(config, options?) → Chord.Conflict[]` | Report duplicate normalized key/modifier pairs within each scope. |
| `chord.hint(config, name?, width, window) → string` | Render described keys padded to the non-negative column budget. |
| `chord.hint_layout(config, name?, width, window, options) → Ribbon` | Render styled hints; requires Ribbon and a live active pane. |
| `chord.hint_action(name?, direction) → KeyAssignment` | Page by signed offset; active table takes precedence over the fallback name. |
| `chord.temporary.begin(window, pane, definition) → fun()` | Publish one window-local hint session and return its release function. |
| `chord.temporary.get(window, theme?) → table?` | Return active `{ name, keys, meta }`; no theme means metadata functions are not evaluated. |

Override shape: `{ enabled = { keys?, key_tables? }, keys = spec,
key_tables = { [name] = spec } }`, with
`spec = { enabled?, disable?, override?, add? }`. A false top-level gate
clears that collection; a false table-level gate removes that table.
`get_modes` and temporary bindings expose shared nested references; treat them
as read-only. Both hint renderers need a live window with an active pane.

### Commands and help

| Signature → Return type | Description |
| --- | --- |
| `chord.command.register(spec) → Chord.Command?` | Add `{ id?, label, action, lhs? }` or a key-backed spec; invalid label/action logs and skips. |
| `chord.command.register_many(specs) → nil` | Register a list in order. |
| `chord.command.clear() → nil` | Clear explicit registrations and reset generated IDs. |
| `chord.command.collect(config, options?) → Chord.Command[]` | Collect `{ id, label, action, lhs?, source, table_name?, binding_id?, mode_meta? }`. |
| `chord.command.action(config, options?) → KeyAssignment` | Open an InputSelector when invoked. |
| `chord.command.apply(config, options?) → KeyAssignment` | Append its trigger and return the same picker action. |
| `chord.command.palette(config, options?) → table[]` | Build `{ brief, action, icon? }` entries; caller registers `augment-command-palette`. |
| `chord.overlay.action(config, options?) → KeyAssignment` | Build a grouped-help selector action. |
| `chord.overlay.apply(config, options?) → KeyAssignment` | Append its trigger and return the help action. |

## Troubleshooting

### A leader binding does nothing

Set `config.leader`; Chord only parses the token. Check modifier spelling,
initialization order, and **Ctrl+Shift+L** for skipped mappings. Use
`chord.conflicts(config)` to find duplicates without changing behavior.

### A command or hint is missing

Give it a non-empty description, inspect source and table filters, and register
all mode definitions together. For hints, check the remaining width, active
table and pane, renderer refresh, and Ribbon availability.

Update plugins with `wezterm.plugin.update_all()` from the debug overlay and
reload. File [issues](https://github.com/sravioli/chord.wz/issues) with a reduced
mapping definition, plugin revision, WezTerm build, and relevant diagnostics.

## Development

### Local checkout

Clone into `plugins/chord.wz` beneath `wezterm.config_dir`, then replace
the remote import:

```lua
local wezterm = require "wezterm"
local chord = wezterm.plugin.require(
  "file:///" .. wezterm.config_dir .. "/plugins/chord.wz"
)
```

Dependencies must remain available through the loader or `package.path`.

### Editor support

Follow the [wezterm-types setup](https://github.com/DrKJeff16/wezterm-types):

```lua
---@type Chord
local chord = wezterm.plugin.require "https://github.com/sravioli/chord.wz"
```

The [published definitions](https://github.com/DrKJeff16/wezterm-types/blob/main/lua/wezterm/types/plugins/chord.lua)
omit temporary sessions, overlays, palette generation, and newer filtering/style
options. Consult [core.lua](../plugin/chord/core.lua),
[config.lua](../plugin/chord/config.lua), and
[command.lua](../plugin/chord/command.lua) for this revision.

### Checks and contributions

From the repository root, with Lua 5.4 and the named tools installed:

```sh
busted --verbose
luacheck plugin
selene --display-style=quiet plugin
stylua --check .
```

Specs mock WezTerm and dependencies, and cover hint budgets and picker lifecycle.
Follow the [contribution guide](contributing.md), use Conventional Commits,
and keep public behavior changes covered.

## License

Code: [GNU GPL v2](../LICENSE). Documentation:
[CC BY-NC 4.0](../LICENSE-DOCS). Preserve existing attribution.
