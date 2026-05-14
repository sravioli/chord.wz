### Summary

Describe the bug fixed in chord.wz and the user-visible mapping, mode, hint, or
picker behavior that changed.

### Reproduction

Provide the smallest mapping or setup that reproduced the issue.

```lua
-- mapping, mode, or picker setup that reproduced the bug
```

### Root Cause

Explain why key normalization, mode activation, command discovery, picker
formatting, hint rendering, or dependency loading was wrong.

### Fix

Describe the implementation change and why it fixes the problem.

### Regression Test

Describe the regression test added or updated.

### Compatibility Impact

- [ ] Non-breaking
- [ ] Potentially breaking
- [ ] Breaking

If this changes behavior intentionally, explain why the new behavior is correct.

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

