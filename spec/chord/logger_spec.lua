local Logger = require "chord.logger"
local deps = require "chord.deps"
local wezterm = require "wezterm"

describe("chord logger", function()
  before_each(function()
    deps._cache = {}
    package.loaded["warp.api"] = nil
    wezterm._logs = {}
  end)

  it("emits formatted messages through wezterm sinks", function()
    local logger = Logger.new("Test", { threshold = "debug" })

    logger:debug("debug %s", "message")
    logger:info "info message"
    logger:warn("warn %s", { value = true })
    logger:error("error %s", "message")

    assert.equal(4, #wezterm._logs)
    assert.same({ level = "info", message = "[Test] debug message" }, wezterm._logs[1])
    assert.same({ level = "info", message = "[Test] info message" }, wezterm._logs[2])
    assert.equal("warn", wezterm._logs[3].level)
    assert.truthy(wezterm._logs[3].message:find "^%[Test%] warn table:")
    assert.same({ level = "error", message = "[Test] error message" }, wezterm._logs[4])
  end)

  it("falls back to the raw message when string formatting fails", function()
    local logger = Logger.new("Test", { threshold = "debug" })

    logger:warn("%d", "not-a-number")

    assert.same({ level = "warn", message = "[Test] %d" }, wezterm._logs[1])
  end)

  it("honors disabled loggers and numeric thresholds", function()
    Logger.new("Disabled", { enabled = false, threshold = 0 }):error "hidden"

    local logger = Logger.new("Numeric", { threshold = 3 })
    logger:warn "hidden"
    logger:error "visible"

    assert.equal(1, #wezterm._logs)
    assert.same({ level = "error", message = "[Numeric] visible" }, wezterm._logs[1])
  end)

  it("uses warp.log when the optional logger is available", function()
    local events = {}
    local setups = {}
    local external = {}

    function external.setup(opts)
      setups[#setups + 1] = opts
    end

    function external.new(tag, enabled)
      external.made = {
        -- Formats its arguments like warp.log's Log:log.
        log = function(_, level, message, ...)
          events[#events + 1] = {
            tag = tag,
            enabled = enabled,
            level = level,
            message = message:format(...),
          }
        end,
      }
      return external.made
    end

    package.loaded["warp.api"] = { log = external }
    deps._cache.warp = nil

    local logger = Logger.new("External", { threshold = "debug" })
    logger:debug("debug %s", "message")
    logger:warn("warn %s", "message")

    -- warp.log's config is shared by every plugin: chord must never set it.
    assert.same({}, setups)
    assert.equal(0, external.made.threshold)
    assert.same({
      { tag = "External", enabled = true, level = "debug", message = "debug message" },
      { tag = "External", enabled = true, level = "warn", message = "warn message" },
    }, events)
    assert.same({}, wezterm._logs)
  end)
end)
