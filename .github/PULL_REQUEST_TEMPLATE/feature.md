### Summary

Describe the new chord.wz feature and the user-facing keybinding workflow it
enables.

### Motivation

Explain why this belongs in chord.wz. Focus on Vim-style mappings, WezTerm key
tables, command discovery, key hints, overlays, or command picker behavior.

### API Sketch

```lua
-- show intended mapping, mode, picker, or setup usage
```

### Behavior

Describe how the feature behaves, including default options, mapping syntax,
generated WezTerm actions, key table behavior, picker entries, hints, and failure
cases.

### Compatibility

- [ ] Non-breaking
- [ ] Potentially breaking
- [ ] Breaking

If this is potentially breaking or breaking, explain the migration path.

### Tests

Describe the tests added or updated for this behavior.

### Documentation

Describe the README, examples, annotation, or template changes made for this
feature.

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

