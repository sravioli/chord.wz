### Summary

Describe the chord.wz documentation change.

### Documentation Changed

List the README, examples, contributing guide, issue templates, pull request
templates, or annotation docs changed by this pull request.

### Reader Impact

Explain who benefits from this documentation change:

- Users defining Vim-style mappings.
- Users configuring key tables, hints, overlays, or the command picker.
- Contributors changing chord.wz internals.

### Examples Touched

```lua
-- mapping, mode, picker, or setup example changed by this pull request
```

### Behavior Change

- [ ] Documentation only
- [ ] Documents an existing behavior
- [ ] Documents a new behavior

If this documents a new behavior, link to the implementation pull request or
commit.

### Checklist

- [ ] The change is scoped to chord.wz.
- [ ] Public API changes are documented, if applicable.
- [ ] Mapping, mode, picker, or hint behavior is covered by tests, if applicable.
- [ ] Existing Vim-style mapping syntax remains compatible.
- [ ] Required checks pass:
  - [ ] `busted --verbose`
  - [ ] `luacheck .`
  - [ ] `stylua --check .`
  - [ ] `selene --display-style=quiet .`

