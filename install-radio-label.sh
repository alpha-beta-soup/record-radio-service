#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <label> [bundle_dir]" >&2
  echo "Expects in bundle_dir (default: current dir):" >&2
  echo "  <label>.timer" >&2
  echo "  <label>.env" >&2
  exit 2
}

LABEL="${1:-}"
BUNDLE_DIR="${2:-.}"

[[ -n "$LABEL" ]] || usage

TIMER_SRC="${BUNDLE_DIR%/}/${LABEL}.timer"
ENV_SRC="${BUNDLE_DIR%/}/${LABEL}.env"

[[ -f "$TIMER_SRC" ]] || { echo "Missing timer file: $TIMER_SRC" >&2; exit 1; }
[[ -f "$ENV_SRC" ]]   || { echo "Missing env file:   $ENV_SRC" >&2; exit 1; }

SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"
RADIO_ENV_DIR="${HOME}/.config/radio-record"

TIMER_DST="${SYSTEMD_USER_DIR}/radio-record@${LABEL}.timer"
ENV_DST="${RADIO_ENV_DIR}/${LABEL}.env"

mkdir -p "$SYSTEMD_USER_DIR" "$RADIO_ENV_DIR"

install -m 0644 "$TIMER_SRC" "$TIMER_DST"
install -m 0644 "$ENV_SRC"   "$ENV_DST"

echo "Installed:"
echo "  $TIMER_DST"
echo "  $ENV_DST"
echo
echo "Now run:"
echo "  systemctl --user daemon-reload"
echo "  systemctl --user enable --now radio-record@${LABEL}.timer"