local chord = require "chord.api"

describe("chord overrides", function()
  before_each(function()
    chord.setup {
      log = { enabled = false },
    }
  end)

  it("disables, overrides, and adds top-level keys", function()
    local config = {}
    chord.maps(config, {
      { "<C-S-c>", "copy", "copy" },
      { "<C-S-v>", "paste", "paste" },
    })

    chord.apply_overrides(config, {
      keys = {
        disable = { "<C-S-c>" },
        override = {
          ["<C-S-v>"] = { "paste-primary", "paste primary" },
        },
        add = {
          { "<leader>x", "extra", "extra" },
        },
      },
    })

    assert.same({
      { key = "v", mods = "CTRL|SHIFT", action = "paste-primary", desc = "paste primary" },
      { key = "x", mods = "LEADER", action = "extra", desc = "extra" },
    }, config.keys)
  end)

  it("updates key table config and raw definitions used by hints", function()
    local config = {}
    chord.tables(config, {
      mode = {
        meta = { i = "M", txt = "MODE", bg = "#111" },
        keys = {
          { "a", "alpha", "alpha" },
          { "b", "beta", "beta" },
        },
      },
    })

    chord.apply_overrides(config, {
      key_tables = {
        mode = {
          disable = { "a" },
          override = {
            b = { "bravo", "bravo" },
          },
          add = {
            { "c", "charlie", "charlie" },
          },
        },
      },
    })

    assert.same({
      { key = "b", action = "bravo", desc = "bravo" },
      { key = "c", action = "charlie", desc = "charlie" },
    }, config.key_tables.mode)
  end)
end)
