local chord = require "chord.api"
local wezterm = require "wezterm"

local function window(active_key_table)
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
      return active_key_table
    end,
    set_right_status = function(self, value)
      self.right_status = value
    end,
  },
    pane
end

local function theme()
  return {
    foreground = "#fff",
    background = "#101010",
    ansi = { "#000", "#111", "#222", "#333", "#444" },
    brights = { "#555" },
    tab_bar = { background = "#000" },
  }
end

describe("chord edge behavior", function()
  before_each(function()
    chord.setup {
      log = { enabled = false },
    }
    chord.apply_overrides({}, { enabled = { key_tables = false } })
    wezterm.plugin.require("https://github.com/sravioli/memo.wz").cache.clear()
  end)

  it("exposes active and default configuration copies", function()
    chord.setup {
      aliases = {
        Space = " ",
      },
    }

    assert.equal(" ", chord.config().aliases.Space)

    local defaults = chord.config().aliases
    local defaults_copy = require("chord.config").defaults()
    defaults_copy.aliases.CR = "Changed"

    assert.equal("Enter", defaults.CR)
  end)

  it("rejects malformed mappings without mutating targets", function()
    local target = {}

    assert.is_nil(chord.key({}, "noop"))
    assert.is_nil(chord.key("x", nil))
    assert.is_nil(chord.key("<C-Z-x>", "bad"))
    assert.is_nil(chord.map("x", "noop", nil))

    chord.map("x", "ok", target)
    chord.map_batch(nil, target)
    chord.map_batch({ {} }, target)
    chord.map_batch({ { "y", "why" } }, nil)

    assert.same({ { key = "x", action = "ok" } }, target)
    assert.same({}, chord.table(nil))
  end)

  it("overrides keys using native entries and adds missing override targets", function()
    local config = {}
    chord.maps(config, {
      { "a", "alpha", "alpha" },
    })

    chord.apply_overrides(config, {
      keys = {
        override = {
          a = { key = "a", action = "alfa", desc = "alfa" },
          b = { action = "bravo", desc = "bravo" },
          c = "ignored",
          d = {},
        },
      },
    })

    assert.same({
      { key = "a", action = "alfa", desc = "alfa" },
      { key = "b", action = "bravo", desc = "bravo" },
    }, config.keys)
  end)

  it("can disable all keys, all key tables, or one key table", function()
    local config = {}
    chord.maps(config, {
      { "a", "alpha", "alpha" },
    })
    chord.tables(config, {
      mode = {
        meta = { i = "M", txt = "MODE", bg = "#111" },
        keys = {
          { "x", "xray", "xray" },
        },
      },
    })

    chord.apply_overrides(config, {
      enabled = { keys = false },
      key_tables = {
        mode = { enabled = false },
      },
    })

    assert.same({}, config.keys)
    assert.is_nil(config.key_tables.mode)

    chord.apply_overrides(config, {
      enabled = { key_tables = false },
    })

    assert.same({}, config.key_tables)
    assert.same({}, chord.get_modes(theme()))
  end)

  it("applies raw key table overrides used by hint fallbacks", function()
    local config = {}
    chord.tables(config, {
      mode = {
        meta = { i = "M", txt = "MODE", bg = "#111" },
        keys = {
          { lhs = "a", rhs = "alpha", desc = "alpha" },
          { "b", "beta", "beta" },
          { key = "c", action = "charlie", desc = "charlie" },
        },
      },
    })

    chord.apply_overrides(config, {
      key_tables = {
        mode = {
          disable = {
            { lhs = "a" },
          },
          override = {
            b = { rhs = "bravo", desc = "bravo" },
            c = { key = "c", action = "cee", desc = "cee" },
            d = { action = "delta", desc = "delta" },
          },
          add = {
            { "e", "echo", "echo" },
          },
        },
      },
    })

    config.key_tables.mode = {}
    local rendered = chord.hint(config, "mode", 80, window "mode")

    assert.is_nil(rendered:find("a alpha", 1, true))
    assert.truthy(rendered:find("b bravo", 1, true))
    assert.truthy(rendered:find("c cee", 1, true))
    assert.truthy(rendered:find("d delta", 1, true))
    assert.truthy(rendered:find("e echo", 1, true))

    local cached = chord.hint(config, "mode", 80, window "mode")
    assert.equal(rendered, cached)
  end)

  it("caches modes per theme and skips definitions without metadata", function()
    local config = {}
    chord.tables(config, {
      mode = {
        meta = { i = "M", txt = "MODE", bg = "#111" },
        keys = {
          { "x", "xray", "xray" },
        },
      },
      hidden = {
        keys = {
          { "h", "hidden", "hidden" },
        },
      },
    })

    local modes = chord.get_modes(theme())
    local cached = chord.get_modes(theme())

    assert.is_true(modes == cached)
    assert.equal("MODE", modes.mode.txt)
    assert.is_nil(modes.hidden)
  end)

  it("renders empty and paginated hint bars", function()
    local win = window()
    local empty = chord.hint({}, nil, 8, win)

    assert.equal("        ", empty)
    assert.equal(
      "        ",
      chord
        .hint_layout({}, nil, 8, win, {
          theme = theme(),
          mode_bg = "#f00",
        })
        :format()
    )

    local config = {}
    chord.maps(config, {
      { "a", "alpha", "alpha" },
      { "b", "bravo", "bravo" },
      { "c", "charlie", "charlie" },
    })

    local memo = wezterm.plugin.require "https://github.com/sravioli/memo.wz"
    memo.cache.set(chord.__hint_var(10, 20, "__keys__"), 99)

    local rendered = chord.hint(config, nil, 14, win)

    assert.equal(14, #rendered)
    assert.truthy(rendered:find "%[3/3%]")
  end)

  it("renders non-bracketed hint layout entries with separators", function()
    local config = {}
    chord.maps(config, {
      { "a", "alpha", "alpha" },
      { "b", "bravo", "bravo" },
    })

    local rendered = chord
      .hint_layout(config, nil, 28, window(), {
        theme = theme(),
        mode_bg = "#f00",
      })
      :format()

    assert.truthy(rendered:find("a alpha", 1, true))
    assert.truthy(rendered:find(" / ", 1, true))
    assert.truthy(rendered:find("b bravo", 1, true))
  end)

  it("uses pane fallback and configured cache prefixes for hint actions", function()
    chord.setup {
      hints = {
        page_cache_prefix = "custom_page",
      },
      log = { enabled = false },
    }

    local win = {
      window_id = function()
        return 30
      end,
      active_pane = function()
        return nil
      end,
      active_key_table = function()
        return nil
      end,
      set_right_status = function(self, value)
        self.right_status = value
      end,
    }
    local pane = {
      pane_id = function()
        return 40
      end,
    }

    chord.hint_action("fallback", -1).callback(win, pane)

    local memo = wezterm.plugin.require "https://github.com/sravioli/memo.wz"
    assert.equal(1, memo.cache.get "custom_page_w30_p40_fallback")
    assert.equal("", win.right_status)
  end)
end)
