---@module "chord.mosaic.mode"
---@author sravioli
---@license GNU-GPLv2

---mosaic integration `chord.mode`: the active chord mode or temporary mode,
---in that mode's colour (as styled by the mosaic preset). mosaic reads this
---file only when a layout names it.

return {
  api = 1,
  events = { "chord-temporary-changed" },
  new = function()
    local core = require "chord.core"

    return function(window, _, theme)
      local temporary = core.temporary.get(window, theme)
      local mode = temporary and temporary.meta or core.get_modes(theme)[window:active_key_table()]
      if not mode then
        return { enabled = false }
      end
      return {
        enabled = true,
        cond = true,
        padding = { left = 1 },
        accent = mode.bg, -- the mode's colour; the preset styles the module
        icon = { enabled = true, value = mode.i, padding = 1 },
        text = { enabled = true, value = mode.txt, padding = { right = 1 } },
      }
    end
  end,
}
