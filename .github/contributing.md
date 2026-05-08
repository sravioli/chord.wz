# memo.wz Contributing Guide

Welcome to the memo.wz contributing guide, and thank you for your interest.

We accept the following types of contributions:

- **Source code** — bug fixes, new features, and improvements to the cache,
  hash, or state modules. See [Environment setup](#environment-setup), [Best
  practices](#best-practices), and [Contribution workflow](#contribution-workflow).
- **Documentation** — improvements to the README, inline LuaLS annotations, or
  issue templates. See [Text formats](#text-formats).
- **Bug reports** — reproducible issues filed through the [bug report
  template](ISSUE_TEMPLATE/bug_report.md). See [Report issues and
  bugs](#report-issues-and-bugs).

At this time, we do not accept:

- Translations
- Social media or outreach contributions

## Overview

memo.wz is a memoization, caching, and persistent state library for
[WezTerm](https://wezfurlong.org/wezterm/) plugins and configuration code. It
provides a session-scoped cache backed by `wezterm.GLOBAL`, file-persistent
key/value stores, and XXH3-64 hashing utilities. See the
[README](readme.md) for full usage details.

## Ground rules

Before contributing, read our [Code of
Conduct](code_of_conduct.md) to learn more about our community guidelines and
expectations.

## Share ideas

To propose a new idea:

1. Check existing [issues](https://github.com/sravioli/memo.wz/issues) to avoid
   duplicates.
2. Open a new issue describing the idea, its motivation, and, if applicable, a
   rough implementation approach.
3. Wait for feedback from a maintainer before starting work.

## Before you start

Before contributing, ensure you have the following:

- A [GitHub account](https://docs.github.com/en/get-started/signing-up-for-github/signing-up-for-a-new-github-account)
- [Git](https://git-scm.com/) installed
- [WezTerm](https://wezfurlong.org/wezterm/installation.html) installed (to
  test changes)
- [StyLua](https://github.com/JohnnyMorganz/StyLua) installed (for code
  formatting)

## Environment setup

1. Fork the repository on GitHub.
2. Clone your fork:

   ```sh
   git clone https://github.com/<your-username>/memo.wz.git
   cd memo.wz
   ```

3. To test the plugin locally, point your WezTerm config at the checkout:

   ```lua
   local memo = wezterm.plugin.require(
     "file:///" .. wezterm.config_dir .. "/plugins/memo.wz"
   )
   ```

4. Verify that StyLua runs without errors:

   ```sh
   stylua --check plugin/
   ```

## Best practices

- **One concern per commit.** Keep commits focused on a single change.
- **Format before committing.** Run `stylua plugin/` to format all Lua files.
  The project uses 2-space indentation, Unix (LF) line endings, double quotes,
  and omitted call parentheses where safe. See [`.stylua.toml`](../.stylua.toml)
  for the full configuration.
- **Keep `require` blocks sorted.** StyLua's `sort_requires` is enabled; let it
  handle ordering.
- **Annotate types.** LuaLS type annotations live inline in the source files
  under `plugin/`. Update or add `---@class`, `---@field`, `---@param`, and
  `---@return` annotations when changing public APIs.
- **Run the test suite.** Tests use [Busted](https://lunarmodules.github.io/busted/).
  Run `busted --verbose` before submitting changes. Add or update tests in
  `spec/` when modifying public behaviour.

## Contribution workflow

### Fork and clone

See [Environment setup](#environment-setup). For a general guide on the
fork-and-branch workflow, read [Using the Fork-and-Branch Git
Workflow](https://blog.scottlowe.org/2015/01/27/using-fork-branch-git-workflow/).

### Report issues and bugs

Use the [bug report template](ISSUE_TEMPLATE/bug_report.md) to file issues.
Include your OS, WezTerm version, memo.wz version or commit, relevant
configuration code, and steps to reproduce the bug.

### Commit messages

This project uses [Conventional
Commits](https://www.conventionalcommits.org/) enforced by
[Cocogitto](https://docs.cocogitto.io/). Every commit message must follow the
format:

```text
<type>[(scope)]: <description>
```

**Standard types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`,
`ci`, `build`, `revert`.

**Project-specific types:**

| Type      | Purpose                         | In changelog? |
| --------- | ------------------------------- | ------------- |
| `chore`   | Miscellaneous maintenance tasks | No            |
| `hotfix`  | Urgent bug fixes                | Yes           |
| `release` | Release bookkeeping             | Yes           |

Examples:

```text
fix(cache): handle nil TTL in compute()
feat(state): add async background writes
docs: update README usage section
chore: bump stylua config
```

### Branch creation

Create a descriptive branch from `main`:

```sh
git switch -c feat/my-new-feature main
```

Use the commit type as the branch prefix (e.g. `fix/`, `feat/`, `docs/`).

### Pull requests

1. Push your branch to your fork.
2. Open a pull request against `main` on
   [sravioli/memo.wz](https://github.com/sravioli/memo.wz).
3. Fill in a description of the changes and reference any related issues.
4. Ensure StyLua formatting passes (`stylua --check plugin/`).
5. Ensure tests pass (`busted --verbose`).
6. A maintainer will review the PR. If you don't receive feedback within a
   reasonable time, leave a comment on the PR to request a review.

### Releases

Releases are automated. When a maintainer bumps the version with `cog bump`,
Cocogitto creates a SemVer tag and pushes it. A GitHub Actions workflow then
generates a changelog and publishes a GitHub release. Contributors do not need
to manage releases.

### Text formats

- **Source code** is written in Lua. Format with StyLua.
- **Documentation** (README, issue templates, contributing guide) is written in
  Markdown.

## Licensing

Code contributions are licensed under the [GNU General Public License
v2](../LICENSE). Documentation contributions are licensed under [Creative
Commons Attribution-NonCommercial 4.0 International](../LICENSE-DOCS).

---

> Template based on the [Contributing Guide
> template](https://thegooddocsproject.dev/) from The Good Docs Project.
