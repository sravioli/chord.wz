local chord = require "chord.api"

describe("chord mappings", function()
  before_each(function()
    chord.setup {
      log = { enabled = false },
    }
  end)

  it("builds a single key from vim-style syntax", function()
    assert.same({
      key = "c",
      mods = "CTRL|SHIFT",
      action = "copy",
      desc = "copy",
    }, chord.key("<C-S-c>", "copy", "copy"))
  end)

  it("passes native wezterm key entries through", function()
    local entry = chord.key {
      key = "v",
      mods = "CTRL|SHIFT",
      action = "paste",
      desc = "paste",
    }

    assert.same({
      key = "v",
      mods = "CTRL|SHIFT",
      action = "paste",
      desc = "paste",
    }, entry)
  end)

  it("accepts mixed mapping lists", function()
    local config = {}
    chord.maps(config, {
      { "<C-S-c>", "copy", "copy" },
      { key = "v", mods = "CTRL|SHIFT", action = "paste", desc = "paste" },
    })

    assert.same({
      { key = "c", mods = "CTRL|SHIFT", action = "copy", desc = "copy" },
      { key = "v", mods = "CTRL|SHIFT", action = "paste", desc = "paste" },
    }, config.keys)
  end)

  it("appends to existing config keys", function()
    local config = {
      keys = {
        { key = "x", action = "existing" },
      },
    }

    chord.maps(config, {
      { "y", "new", "new" },
    })

    assert.same({
      { key = "x", action = "existing" },
      { key = "y", action = "new", desc = "new" },
    }, config.keys)
  end)
end)
