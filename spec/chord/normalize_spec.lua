local chord = require "chord.api"

describe("chord normalization", function()
  before_each(function()
    chord.setup {
      log = { enabled = false },
    }
  end)

  it("normalizes vim-style modifiers", function()
    assert.same({
      key = "v",
      mods = "CTRL|SHIFT",
    }, chord.normalize "<C-S-v>")
  end)

  it("normalizes leader mappings", function()
    assert.same({
      key = "p",
      mods = "LEADER",
    }, chord.normalize "<leader>p")
  end)

  it("normalizes aliases and function keys", function()
    assert.same({ key = "Enter" }, chord.normalize "<CR>")
    assert.same({
      key = "F12",
      mods = "SHIFT",
    }, chord.normalize "<S-F12>")
  end)

  it("rejects invalid modifier-only mappings", function()
    local ok, err = chord.validate "<C-S>"
    assert.is_false(ok)
    assert.equal("keymap cannot end with modifier!", err)
  end)

  it("reconstructs vim-style labels from wezterm entries", function()
    assert.equal(
      "<C-S-v>",
      chord.__entry_lhs {
        key = "v",
        mods = "CTRL|SHIFT",
      }
    )
    assert.equal(
      "<leader>p",
      chord.__entry_lhs {
        key = "p",
        mods = "LEADER",
      }
    )
  end)
end)
