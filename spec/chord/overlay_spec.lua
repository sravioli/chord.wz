local chord = require "chord.api"

local function reset()
  chord.setup {
    log = { enabled = false },
  }
  chord.command.clear()
  chord.apply_overrides({}, { enabled = { key_tables = false } })
end

local function new_window()
  local calls = {}
  local win = {
    perform_action = function(_, action, pane)
      calls[#calls + 1] = {
        action = action,
        pane = pane,
      }
    end,
  }
  return win, {}, calls
end

describe("chord overlay", function()
  before_each(reset)

  it("opens a grouped InputSelector and performs the selected command", function()
    local config = {}
    chord.maps(config, {
      { "a", "alpha-action", "alpha" },
    })

    local action = chord.overlay.action(config, {
      title = "Help",
      sources = { "keys" },
    })
    local win, pane, calls = new_window()

    action.callback(win, pane)

    local selector = calls[1].action
    assert.equal("InputSelector", selector.type)
    assert.equal("Help", selector.args.title)
    assert.equal("[global] a  alpha", selector.args.choices[1].label)

    selector.args.action.callback(win, pane, selector.args.choices[1].id)

    assert.equal("alpha-action", calls[2].action)
  end)

  it("applies an overlay trigger without listing the overlay itself", function()
    local config = {}
    chord.maps(config, {
      { "a", "alpha-action", "alpha" },
    })

    local action = chord.overlay.apply(config, {
      key = "<leader>?",
      sources = { "keys" },
    })

    assert.equal(action, config.keys[2].action)
    assert.equal("<leader>?", chord.__entry_lhs(config.keys[2]))

    local commands = chord.command.collect(config)
    assert.equal(1, #commands)
    assert.equal("alpha", commands[1].label)
  end)
end)
