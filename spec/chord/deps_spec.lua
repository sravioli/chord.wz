local deps = require "chord.deps"
local wezterm = require "wezterm"

describe("chord dependencies", function()
  after_each(function()
    deps._cache = {}
    package.loaded["memo.api"] = nil
  end)

  it("prefers local api modules before plugin URLs", function()
    local local_memo = { local_api = true }
    package.loaded["memo.api"] = local_memo
    deps._cache.memo = nil

    assert.equal(local_memo, deps.memo())
    assert.equal(local_memo, deps.memo())
  end)

  it("raises a useful error when a dependency cannot be loaded", function()
    local original_require = wezterm.plugin.require
    wezterm.plugin.require = function()
      error "missing dependency"
    end
    deps._cache.memo = nil

    local ok, err = pcall(deps.memo)

    wezterm.plugin.require = original_require

    assert.is_false(ok)
    assert.truthy(tostring(err):find("unable to load dependency", 1, true))
  end)

  it("returns nil for unavailable optional dependencies", function()
    local original_require = wezterm.plugin.require
    wezterm.plugin.require = function()
      error "missing dependency"
    end
    deps._cache.memo = nil

    local plugin, err = deps.optional "memo"

    wezterm.plugin.require = original_require

    assert.is_nil(plugin)
    assert.truthy(tostring(err):find("missing dependency", 1, true))
  end)

  it("reports unknown optional dependencies", function()
    local plugin, err = deps.optional "missing"

    assert.is_nil(plugin)
    assert.equal("unknown dependency: missing", err)
  end)
end)
