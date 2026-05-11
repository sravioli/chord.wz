local chord = require "chord.api"
local deps = require "chord.deps"
local wezterm = require "wezterm"

local function reset()
  chord.setup {
    log = { enabled = false },
  }
  chord.command.clear()
  chord.apply_overrides({}, { enabled = { key_tables = false } })
  deps._cache = {}
  wezterm._logs = {}
  wezterm._format_calls = {}
  wezterm._set_default_keys {}
end

local function new_window()
  local calls = {}
  local win = {
    perform_action = function(_, action, pane)
      calls[#calls + 1] = {
        action = action,
        pane = pane,
      }
    end,
  }
  return win, {}, calls
end

describe("chord command picker", function()
  before_each(reset)

  it("collects registered commands and described config keys", function()
    chord.command.register {
      id = "ssh-prod",
      label = "SSH: production",
      action = "ssh-action",
    }

    local config = {}
    chord.maps(config, {
      { "<leader>p", "palette", "command palette" },
      { "x", "hidden" },
    })

    local commands = chord.command.collect(config)

    assert.equal(2, #commands)
    assert.equal("ssh-prod", commands[1].id)
    assert.equal("SSH: production", commands[1].label)
    assert.equal("<leader>p", commands[2].lhs)
    assert.equal("command palette", commands[2].label)
  end)

  it("can include undocumented config keys", function()
    local config = {}
    chord.maps(config, {
      { "x", "xray" },
    })

    local commands = chord.command.collect(config, {
      include_undocumented = true,
    })

    assert.equal(1, #commands)
    assert.equal("x", commands[1].lhs)
    assert.equal("xray", commands[1].label)
  end)

  it("collects key table commands using chord metadata", function()
    local config = {}
    chord.tables(config, {
      mode = {
        meta = { i = "M", txt = "MODE", bg = "#111111" },
        keys = {
          { "a", "alpha", "alpha" },
          { "b", "bravo" },
        },
      },
    })

    local commands = chord.command.collect(config)

    assert.equal(1, #commands)
    assert.equal("key_table", commands[1].source)
    assert.equal("mode", commands[1].table_name)
    assert.equal("a", commands[1].lhs)
    assert.equal("alpha", commands[1].label)
  end)

  it("dedupes defaults against user keys", function()
    local config = {}
    chord.maps(config, {
      { "<C-c>", "copy-user", "copy" },
    })

    wezterm._set_default_keys {
      { key = "c", mods = "CTRL", action = "copy-default" },
      { key = "v", mods = "CTRL", action = { PasteFrom = "Clipboard" } },
    }

    local commands = chord.command.collect(config, {
      include_defaults = true,
    })

    assert.equal(2, #commands)
    assert.equal("copy-user", commands[1].action)
    assert.equal("PasteFrom", commands[2].label)
    assert.equal("default", commands[2].source)
  end)

  it("opens an InputSelector and performs the selected command", function()
    local config = {}
    chord.maps(config, {
      { "a", "alpha-action", "alpha" },
    })

    local action = chord.command.action(config, {
      title = "Run command",
    })
    local win, pane, calls = new_window()

    action.callback(win, pane)

    local selector = calls[1].action
    assert.equal("InputSelector", selector.type)
    assert.equal("Run command", selector.args.title)
    assert.equal("a  alpha", selector.args.choices[1].label)

    selector.args.action.callback(win, pane, selector.args.choices[1].id)

    assert.equal("alpha-action", calls[2].action)
    assert.equal(pane, calls[2].pane)
  end)

  it("applies a trigger binding without listing the picker itself", function()
    local config = {}
    chord.maps(config, {
      { "a", "alpha-action", "alpha" },
    })

    local action = chord.command.apply(config, {
      key = "<leader><Space>",
    })

    assert.equal(action, config.keys[2].action)
    assert.equal("<leader><Space>", chord.__entry_lhs(config.keys[2]))

    local commands = chord.command.collect(config)
    assert.equal(1, #commands)
    assert.equal("alpha", commands[1].label)
  end)

  it("filters commands by source and table", function()
    chord.command.register {
      id = "registered",
      label = "registered",
      action = "registered-action",
    }

    local config = {}
    chord.maps(config, {
      { "g", "global-action", "global" },
    })
    chord.tables(config, {
      alpha = {
        meta = { i = "A", txt = "ALPHA", bg = "#111111" },
        keys = {
          { "a", "alpha-action", "alpha" },
        },
      },
      beta = {
        meta = { i = "B", txt = "BETA", bg = "#222222" },
        keys = {
          { "b", "beta-action", "beta" },
        },
      },
    })
    wezterm._set_default_keys {
      { key = "d", mods = "CTRL", action = "default-action" },
    }

    local table_commands = chord.command.collect(config, {
      sources = { "key_table" },
      tables = { "alpha" },
    })
    assert.equal(1, #table_commands)
    assert.equal("alpha", table_commands[1].label)
    assert.equal("alpha", table_commands[1].table_name)

    local global_commands = chord.command.collect(config, {
      sources = { "global" },
    })
    assert.equal(1, #global_commands)
    assert.equal("keys", global_commands[1].source)

    local default_commands = chord.command.collect(config, {
      sources = { "defaults" },
    })
    assert.equal(1, #default_commands)
    assert.equal("default", default_commands[1].source)
  end)

  it("ignores excluded key tables", function()
    local config = {}
    chord.tables(config, {
      alpha = {
        meta = { i = "A", txt = "ALPHA", bg = "#111111" },
        keys = {
          { "a", "alpha-action", "alpha" },
        },
      },
      beta = {
        meta = { i = "B", txt = "BETA", bg = "#222222" },
        keys = {
          { "b", "beta-action", "beta" },
        },
      },
    })

    local commands = chord.command.collect(config, {
      sources = { "tables" },
      exclude_tables = { "alpha" },
    })

    assert.equal(1, #commands)
    assert.equal("beta", commands[1].table_name)
  end)

  it("builds styled picker labels with wezterm.format", function()
    local config = {}
    chord.tables(config, {
      mode = {
        meta = { i = "M", txt = "MODE", bg = "#111111" },
        keys = {
          { "a", "alpha-action", "alpha" },
        },
      },
    })

    local action = chord.command.action(config, {
      sources = { "key_table" },
      style = {
        enabled = true,
        formatter = "wezterm",
        mode_colors = {
          mode = { fg = "#000000", bg = "#ffffff" },
        },
      },
    })
    local win, pane, calls = new_window()

    action.callback(win, pane)

    local selector = calls[1].action
    assert.equal("[mode] a  alpha", selector.args.choices[1].label)
    assert.equal(1, #wezterm._format_calls)
  end)

  it("falls back from ribbon picker labels to wezterm.format", function()
    local original_require = wezterm.plugin.require
    wezterm.plugin.require = function(url)
      if tostring(url):find("ribbon.wz", 1, true) then
        error "missing ribbon"
      end
      return original_require(url)
    end

    local config = {}
    chord.maps(config, {
      { "a", "alpha-action", "alpha" },
    })

    local action = chord.command.action(config, {
      style = {
        enabled = true,
        formatter = "ribbon",
      },
    })
    local win, pane, calls = new_window()

    action.callback(win, pane)

    wezterm.plugin.require = original_require

    local selector = calls[1].action
    assert.equal("[keys] a  alpha", selector.args.choices[1].label)
    assert.equal(1, #wezterm._format_calls)
  end)
end)
