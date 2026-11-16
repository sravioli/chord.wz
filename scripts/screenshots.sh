#!/usr/bin/env bash
# Screenshot the chord command picker, help overlay and WezTerm's copy and search modes, dark (kanagawa-wave) and light
# (kanagawa-lotus) from the kanagawa plugin
# (https://github.com/kanagawa-community/wezterm): .github/assets/<scene>/{dark,light}.png.
#
# Needs KDE Plasma (spectacle) and wezterm; oxipng is used when installed.
# Run it from a session you leave alone: each shot opens a window that must
# keep the focus until it is captured.
#
#   scripts/screenshots.sh                  # every scene
#   scripts/screenshots.sh mode_copy mode_search  # only these
#
# Scenes: command help mode_copy mode_search
#
# Settings (environment): CHORD_FONT ("FiraCode Nerd Font"), CHORD_FONT_SIZE (14),
# CHORD_COLS (100), CHORD_ROWS (30), CHORD_DELAY (seconds to wait for the window, default 5).
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
delay=${CHORD_DELAY:-5}
all=(command help mode_copy mode_search)
scenes=("${@:-${all[@]}}")

for tool in wezterm spectacle; do
  command -v "$tool" >/dev/null || { echo "missing: $tool" >&2; exit 1; }
done

export CHORD_REPO="$repo"

shoot() { # scene kanagawa-scheme file-name
  local dir="$repo/.github/assets/$1"
  mkdir -p "$dir"
  CHORD_SCENE=$1 CHORD_KANAGAWA=$2 \
    wezterm --config-file "$repo/scripts/screenshot.wezterm.lua" start --always-new-process &
  local pid=$!
  sleep "$delay"
  spectacle --activewindow --background --nonotify --output "$dir/$3.png"
  case "$1" in
    mode_*) magick "$dir/$3.png" -gravity North -crop 100%x50%+0+0 +repage "$dir/$3.png" ;;
  esac
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  command -v oxipng >/dev/null && oxipng -q -o4 --strip all "$dir/$3.png"
  echo "$dir/$3.png"
}

for scene in "${scenes[@]}"; do
  shoot "$scene" wave dark
  shoot "$scene" lotus light
done
