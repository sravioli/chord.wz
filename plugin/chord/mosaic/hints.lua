---@module "chord.mosaic.hints"
---@author sravioli
---@license GNU-GPLv2

---mosaic integration `chord.hints`: the active key table's hint bar, paged
---by `chord.hint_action`, filling the columns left on its side. mosaic reads
---this file only when a layout names it.
---
---Options (`options["chord.hints"]`):
---  leader? fun(width: integer, theme: table): table  hint layout shown while
---          the leader is held and no key table is active

return {
  api = 1,
  events = { "chord-hint-page-changed", "chord-temporary-changed" },
  new = function(opts, mosaic)
    local core = require "chord.core"
    local leader = opts.leader

    return function(window, _, theme, config)
      local active = window:active_key_table()

      if not active and leader and window:leader_is_active() then
        return {
          enabled = true,
          cond = true,
          layout = function(ctx)
            return leader(mosaic.remaining_width(), ctx.theme)
          end,
        }
      end
      if not active then
        return { enabled = false }
      end

      local temporary = core.temporary.get(window, theme)
      local mode = temporary and temporary.meta or core.get_modes(theme)[active]
      if not mode then
        return { enabled = false }
      end
      return {
        enabled = true,
        cond = true,
        layout = function(ctx)
          return core.hint_layout(config, active, mosaic.remaining_width(), window, {
            theme = ctx.theme,
            mode_bg = mode.bg,
          })
        end,
      }
    end
  end,
}
