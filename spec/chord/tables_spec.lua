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
end)
