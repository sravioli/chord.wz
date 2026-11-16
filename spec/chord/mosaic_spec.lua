-- Checked first: loading chord must not read its mosaic integrations.
local integrations_loaded_by_chord = package.loaded["chord.mosaic.mode"] ~= nil
  or package.loaded["chord.mosaic.hints"] ~= nil

local chord = require "chord.api"

local theme = {
  foreground = "#fff",
  background = "#000",
  ansi = { "#100", "#200" },
  brights = { "#555" },
  tab_bar = { background = "#000" },
}

-- Stand-in for the public mosaic API passed to `new(opts, mosaic)`.
local mosaic = {
  remaining_width = function()
    return 40
  end,
}

local function window(active, leader)
  return {
    window_id = function()
      return 1
    end,
    active_pane = function()
      return {
        pane_id = function()
          return 2
        end,
      }
    end,
    active_key_table = function()
      return active
    end,
    leader_is_active = function()
      return leader == true
    end,
  }
end

describe("mosaic integrations", function()
  local config

  before_each(function()
    chord.setup { log = { enabled = false } }
    config = {}
    chord.tables(config, {
      normal_mode = {
        meta = { i = "N", txt = "NORMAL", bg = "#0f0" },
        keys = { { "a", "alpha", "alpha" } },
      },
    })
  end)

  it("are not read when chord loads", function()
    assert.is_false(integrations_loaded_by_chord)
  end)

  for _, name in ipairs { "mode", "hints" } do
    it(name .. " follows the descriptor contract", function()
      local d = require("chord.mosaic." .. name)
      assert.equal(1, d.api)
      assert.is_function(d.new)
      for _, event in ipairs(d.events) do
        assert.is_string(event)
      end
      assert.is_function(d.new({}, mosaic))
    end)
  end

  describe("chord.mode", function()
    local module

    before_each(function()
      module = require("chord.mosaic.mode").new({}, mosaic)
    end)

    it("shows the active mode", function()
      local spec = module(window "normal_mode", nil, theme)
      assert.is_true(spec.enabled)
      assert.equal("NORMAL", spec.text.value)
      assert.equal("N", spec.icon.value)
      assert.equal("#0f0", spec.accent)
      assert.is_nil(spec.style) -- content only: the preset decorates it
    end)

    it("hides without a mode", function()
      assert.is_false(module(window(nil), nil, theme).enabled)
      assert.is_false(module(window "unknown", nil, theme).enabled)
    end)
  end)

  describe("chord.hints", function()
    it("lays out the active key table in the remaining width", function()
      local module = require("chord.mosaic.hints").new({}, mosaic)
      local spec = module(window "normal_mode", nil, theme, config)
      assert.is_true(spec.enabled)
      local text = spec.layout({ theme = theme }):format():gsub("\27%[[%d;]*m", "")
      assert.is_truthy(text:find("alpha", 1, true), text)
      assert.is_true(require("wezterm").column_width(text) <= 40)
    end)

    it("uses the leader option while the leader is held", function()
      local seen
      local module = require("chord.mosaic.hints").new({
        leader = function(width, t)
          seen = { width = width, theme = t }
          return { { Text = "leader" } }
        end,
      }, mosaic)
      local spec = module(window(nil, true), nil, theme, config)
      assert.same({ { Text = "leader" } }, spec.layout { theme = theme })
      assert.same({ width = 40, theme = theme }, seen)
    end)

    it("hides when idle, or for the leader without the option", function()
      local module = require("chord.mosaic.hints").new({}, mosaic)
      assert.is_false(module(window(nil), nil, theme, config).enabled)
      assert.is_false(module(window(nil, true), nil, theme, config).enabled)
    end)
  end)
end)
