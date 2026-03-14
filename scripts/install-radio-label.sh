#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <label> [repo_dir]" >&2
  echo "Expects in repo_dir (default: repo root):" >&2
  echo "  shows/<label>.timer" >&2
  echo "  shows/<label>.env" >&2
  echo "  radio-record@.service" >&2
  echo "  scripts/record-radio.sh" >&2
  exit 2
}

LABEL="${1:-}"
REPO_DIR="${2:-}"

[[ -n "$LABEL" ]] || usage

if [[ -z "$REPO_DIR" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
fi

TIMER_SRC="${REPO_DIR%/}/shows/${LABEL}.timer"
ENV_SRC="${REPO_DIR%/}/shows/${LABEL}.env"
SERVICE_SRC="${REPO_DIR%/}/radio-record@.service"
SCRIPT_SRC="${REPO_DIR%/}/scripts/record-radio.sh"

[[ -f "$TIMER_SRC" ]] || { echo "Missing timer file: $TIMER_SRC" >&2; exit 1; }
[[ -f "$ENV_SRC" ]]   || { echo "Missing env file:   $ENV_SRC" >&2; exit 1; }
[[ -f "$SERVICE_SRC" ]] || { echo "Missing service template: $SERVICE_SRC" >&2; exit 1; }
[[ -f "$SCRIPT_SRC" ]]  || { echo "Missing script: $SCRIPT_SRC" >&2; exit 1; }

SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"
RADIO_ENV_DIR="${HOME}/.config/radio-record"
BIN_DIR="${HOME}/bin"

TIMER_DST="${SYSTEMD_USER_DIR}/radio-record@${LABEL}.timer"
ENV_DST="${RADIO_ENV_DIR}/${LABEL}.env"
SERVICE_DST="${SYSTEMD_USER_DIR}/radio-record@.service"
SCRIPT_DST="${BIN_DIR}/record-radio.sh"

mkdir -p "$SYSTEMD_USER_DIR" "$RADIO_ENV_DIR" "$BIN_DIR"

install -m 0644 "$TIMER_SRC" "$TIMER_DST"
install -m 0644 "$ENV_SRC"   "$ENV_DST"
install -m 0644 "$SERVICE_SRC" "$SERVICE_DST"
install -m 0755 "$SCRIPT_SRC" "$SCRIPT_DST"

echo "Installed:"
echo "  $TIMER_DST"
echo "  $ENV_DST"
echo "  $SERVICE_DST"
echo "  $SCRIPT_DST"
echo
echo "Now run:"
echo "  systemctl --user daemon-reload"
echo "  systemctl --user enable --now radio-record@${LABEL}.timer"
