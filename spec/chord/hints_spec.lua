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
  local original_column_width = wezterm.column_width

  before_each(function()
    chord.setup {
      log = { enabled = false },
    }
    wezterm.plugin.require("https://github.com/sravioli/memo.wz").cache.clear()
  end)

  after_each(function()
    wezterm.column_width = original_column_width
  end)

  describe("temporary picker hints", function()
    local theme = {
      foreground = "#fff",
      brights = { "#555" },
      tab_bar = { background = "#000" },
    }
    local opts = { theme = theme, mode_bg = "#f00" }

    local function picker_window(id, name)
      local win, pane = window()
      win.window_id = function()
        return id
      end
      win.active = name
      win.active_key_table = function(self)
        return self.active
      end
      return win, pane
    end

    local function definition(name, label)
      return {
        name = name,
        meta = function(t)
          return { i = "P", txt = "PICKER", bg = t.foreground }
        end,
        keys = {
          { "<M-x>", "dispatch", label or "dispatch" },
          { "<ESC>", "cancel", "cancel" },
        },
      }
    end

    it("isolates arbitrary table names by window without replacing modal definitions", function()
      local config = {}
      chord.tables(config, {
        mode = {
          meta = { i = "M", txt = "MODE", bg = "#111" },
          keys = {
            { "a", "alpha", "alpha" },
          },
        },
      })
      local a, pane = picker_window(101, "custom_picker")
      local b = picker_window(102, "custom_picker")
      local normal = picker_window(103, "mode")
      local before = chord.hint_layout(config, "mode", 30, normal, opts):format()
      local release_a = chord.temporary.begin(a, pane, definition("custom_picker", "first"))
      local release_b = chord.temporary.begin(b, pane, definition("custom_picker", "second"))
      assert.equal("#fff", chord.temporary.get(a, theme).meta.bg)
      assert.truthy(
        chord.hint_layout(config, "custom_picker", 40, a, opts):format():find("first", 1, true)
      )
      assert.truthy(
        chord.hint_layout(config, "custom_picker", 40, b, opts):format():find("second", 1, true)
      )
      assert.same(before, chord.hint_layout(config, "mode", 30, normal, opts):format())
      assert.is_nil(chord.get_modes(theme).custom_picker)
      release_a()
      assert.is_nil(chord.temporary.get(a, theme))
      assert.is_not_nil(chord.temporary.get(b, theme))
      release_b()
    end)

    it("resets pagination on reopen and ignores stale or repeated releases", function()
      local win, pane = picker_window(104, "reopened")
      local old = chord.temporary.begin(win, pane, definition "reopened")
      chord.hint_action(nil, 1).callback(win, pane)
      local current = chord.temporary.begin(win, pane, definition("reopened", "new action"))
      local memo = wezterm.plugin.require "https://github.com/sravioli/memo.wz"
      assert.equal(1, memo.cache.get(chord.__hint_var(104, 20, "reopened")))
      old()
      assert.is_not_nil(chord.temporary.get(win, theme))
      local count = #wezterm._emitted
      current()
      current()
      assert.equal(count + 1, #wezterm._emitted)
      assert.equal("chord-temporary-changed", wezterm._emitted[#wezterm._emitted].name)
      assert.is_nil(chord.temporary.get(win, theme))
    end)

    it("uses existing notation, formatting and pagination within every width budget", function()
      local win, pane = picker_window(105, "width_picker")
      local release = chord.temporary.begin(win, pane, definition "width_picker")
      for width = 0, 100 do
        local text = chord.hint_layout({}, "width_picker", width, win, opts):format()
        assert.is_true(wezterm.column_width(text) <= width, "layout width " .. width)
        assert.equal(width, wezterm.column_width(chord.hint({}, "width_picker", width, win)))
      end
      local text = chord.hint_layout({}, "width_picker", 22, win, opts):format()
      assert.truthy(text:find("<A-x> dispatch", 1, true))
      assert.truthy(text:find("[1/2]", 1, true))
      win.right_status = "existing status"
      chord.hint_action(nil, 1).callback(win, pane)
      assert.equal("existing status", win.right_status)
      text = chord.hint_layout({}, "width_picker", 22, win, opts):format()
      assert.truthy(text:find("[2/2]", 1, true))
      assert.equal("chord-hint-page-changed", wezterm._emitted[#wezterm._emitted].name)
      win.active = "mode"
      assert.is_nil(chord.temporary.get(win, theme))
      release()
    end)

    it("reuses pagination for the same window, entries and width", function()
      local win = picker_window(107, "cached")
      local config = {
        key_tables = {
          cached = {
            { key = "a", desc = "alpha action" },
            { key = "b", desc = "bravo action" },
            { key = "c", desc = "charlie action" },
          },
        },
      }
      local call_count = 0
      local column_width = wezterm.column_width
      wezterm.column_width = function(value)
        call_count = call_count + 1
        return column_width(value)
      end

      local first = chord.hint_layout(config, "cached", 18, win, opts):format()
      local first_count = call_count
      call_count = 0
      local second = chord.hint_layout(config, "cached", 18, win, opts):format()
      local cached_count = call_count
      assert.equal(first, second)
      assert.is_true(cached_count < first_count)

      call_count = 0
      chord.hint_layout(config, "cached", 20, win, opts):format()
      assert.is_true(call_count > cached_count)

      config.key_tables.cached = { { key = "z", desc = "new action" } }
      local updated = chord.hint_layout(config, "cached", 20, win, opts):format()
      assert.truthy(updated:find("new action", 1, true))

      config.key_tables.cached[1].desc = "mutated action"
      local mutated = chord.hint_layout(config, "cached", 20, win, opts):format()
      assert.truthy(mutated:find("mutated action", 1, true))
      wezterm.column_width = column_width
    end)

    it("does not retain disposed windows in pagination cache", function()
      local config = { key_tables = { cached = { { key = "a", desc = "alpha" } } } }
      local ref = setmetatable({}, { __mode = "v" })
      do
        local win = picker_window(108, "cached")
        ref[1] = win
        chord.hint_layout(config, "cached", 20, win, opts)
      end
      collectgarbage "collect"
      assert.is_nil(ref[1])
    end)

    it("budgets pagination indicators when the page count gains a digit", function()
      local win, pane = picker_window(106, "many_pages")
      local def = definition "many_pages"
      for i = 1, 12 do
        def.keys[i] = { tostring(i), "action", "description" }
      end
      local release = chord.temporary.begin(win, pane, def)
      for width = 0, 160 do
        assert.is_true(#chord.hint_layout({}, def.name, width, win, opts):format() <= width)
      end
      release()
    end)
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
    local config = {}
    chord.tables(config, {
      mode = {
        meta = { i = "M", txt = "MODE", bg = "#111" },
        keys = {
          { "a", "alpha", "alpha" },
          { "b", "bravo", "bravo" },
        },
      },
    })
    local opts = {
      theme = {
        foreground = "#fff",
        brights = { "#555" },
        tab_bar = { background = "#000" },
      },
      mode_bg = "#f00",
    }

    local first_page = chord.hint_layout(config, "mode", 12, win, opts):format()
    assert.truthy(first_page:find("[1/2]", 1, true))

    local action = chord.hint_action("mode", 1)
    assert.equal("action_callback", action.__type)

    action.callback(win, pane)

    local memo = wezterm.plugin.require "https://github.com/sravioli/memo.wz"
    assert.equal(2, memo.cache.get(chord.__hint_var(10, 20, "mode")))
    local second_page = chord.hint_layout(config, "mode", 12, win, opts):format()
    assert.truthy(second_page:find("[2/2]", 1, true))
    assert.equal("", win.right_status)
  end)
end)
