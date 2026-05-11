local chord = require "chord.api"

describe("chord diagnostics", function()
  before_each(function()
    chord.setup {
      log = { enabled = false },
    }
    chord.apply_overrides({}, { enabled = { key_tables = false } })
  end)

  it("reports duplicate global keys", function()
    local config = {}
    chord.maps(config, {
      { "<C-c>", "copy", "copy" },
      { "<C-c>", "cancel", "cancel" },
    })

    local conflicts = chord.conflicts(config)

    assert.equal(1, #conflicts)
    assert.equal("global", conflicts[1].scope)
    assert.equal("<C-c>", conflicts[1].lhs)
    assert.equal(2, #conflicts[1].entries)
    assert.equal("copy", conflicts[1].entries[1].desc)
    assert.equal("cancel", conflicts[1].entries[2].desc)
  end)

  it("reports duplicate key table entries by table scope", function()
    local config = {}
    chord.tables(config, {
      resize = {
        meta = { i = "R", txt = "RESIZE", bg = "#111111" },
        keys = {
          { "h", "left", "left" },
          { "h", "other-left", "other left" },
        },
      },
      window = {
        meta = { i = "W", txt = "WINDOW", bg = "#222222" },
        keys = {
          { "h", "split", "split" },
        },
      },
    })

    local conflicts = chord.conflicts(config)

    assert.equal(1, #conflicts)
    assert.equal("table:resize", conflicts[1].scope)
    assert.equal("h", conflicts[1].lhs)
  end)

  it("returns an empty list when there are no duplicates", function()
    local config = {}
    chord.maps(config, {
      { "a", "alpha", "alpha" },
      { "b", "beta", "beta" },
    })

    assert.same({}, chord.conflicts(config))
  end)
end)
