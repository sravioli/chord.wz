local chord = require "chord.api"

describe("chord key tables", function()
  before_each(function()
    chord.setup {
      log = { enabled = false },
    }
  end)

  it("registers key tables and injects mode names", function()
    local config = {}

    chord.tables(config, {
      resize = {
        meta = { i = "R", txt = "RESIZE", bg = "#111111" },
        keys = {
          { "h", "left", "left" },
          { key = "l", action = "right", desc = "right" },
        },
      },
    })

    assert.same({
      resize = {
        { key = "h", action = "left", desc = "left" },
        { key = "l", action = "right", desc = "right" },
      },
    }, config.key_tables)

    local modes = chord.get_modes {}
    assert.equal("resize", modes.resize.name)
    assert.equal("RESIZE", modes.resize.txt)
  end)

  it("supports theme-aware table definitions", function()
    local config = {}

    chord.tables(config, {
      themed = function(theme)
        return {
          meta = { i = "T", txt = "THEME", bg = theme.brights[3] },
          keys = {
            { "x", "action", "action" },
          },
        }
      end,
    })

    assert.same({
      { key = "x", action = "action", desc = "action" },
    }, config.key_tables.themed)

    local modes = chord.get_modes {
      foreground = "#fff",
      background = "#000",
      brights = { "#111", "#222", "#333" },
    }

    assert.equal("#333", modes.themed.bg)
  end)

  it("accepts mode helper objects and builds activation bindings", function()
    local config = {}
    local resize = chord.mode("resize", {
      one_shot = false,
      meta = { i = "R", txt = "RESIZE", bg = "#111111" },
      keys = {
        { "h", "left", "left" },
      },
    })

    chord.tables(config, { resize })
    local entry = resize:activate("<leader>r", "resize mode", {
      replace_current = true,
    })

    assert.same({
      resize = {
        { key = "h", action = "left", desc = "left" },
      },
    }, config.key_tables)
    assert.equal("r", entry.key)
    assert.equal("LEADER", entry.mods)
    assert.equal("resize mode", entry.desc)
    assert.equal("ActivateKeyTable", entry.action.type)
    assert.equal("resize", entry.action.args.name)
    assert.is_false(entry.action.args.one_shot)
    assert.is_true(entry.action.args.replace_current)
  end)
end)
