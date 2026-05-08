local chord = require "chord.api"
local wezterm = require "wezterm"

local function window()
  local pane = {
    pane_id = function()
      return 20
    end,
  }

  return {
    window_id = function()
      return 10
    end,
    active_pane = function()
      return pane
    end,
    active_key_table = function()
      return "mode"
    end,
    set_right_status = function(self, value)
      self.right_status = value
    end,
  },
    pane
end

describe("chord hints", function()
  before_each(function()
    chord.setup {
      log = { enabled = false },
    }
    wezterm.plugin.require("https://github.com/sravioli/memo.wz").cache.clear()
  end)

  it("renders fixed-width plain hints", function()
    local config = {}
    chord.maps(config, {
      { "a", "alpha", "alpha" },
      { "b", "beta", "beta" },
    })

    local rendered = chord.hint(config, nil, 20, window())

    assert.equal(20, #rendered)
    assert.truthy(rendered:find("a alpha", 1, true))
    assert.truthy(rendered:find("b beta", 1, true))
  end)

  it("renders ribbon hint layouts", function()
    local config = {}
    chord.tables(config, {
      mode = {
        meta = { i = "M", txt = "MODE", bg = "#111" },
        keys = {
          { "<C-a>", "alpha", "alpha" },
        },
      },
    })

    local rendered = chord
      .hint_layout(config, "mode", 20, window(), {
        theme = {
          foreground = "#fff",
          brights = { "#555" },
          tab_bar = { background = "#000" },
        },
        mode_bg = "#f00",
      })
      :format()

    assert.truthy(rendered:find "<C%-a> alpha")
  end)

  it("returns an action callback that pages hints", function()
    local win, pane = window()
    local action = chord.hint_action("mode", 1)
    assert.equal("action_callback", action.__type)

    action.callback(win, pane)

    local memo = wezterm.plugin.require "https://github.com/sravioli/memo.wz"
    assert.equal(2, memo.cache.get(chord.__hint_var(10, 20, "mode")))
    assert.equal("", win.right_status)
  end)
end)
