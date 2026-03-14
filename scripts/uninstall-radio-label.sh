#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <label>" >&2
  echo "Removes:" >&2
  echo "  ~/.config/systemd/user/radio-record@<label>.timer" >&2
  echo "  ~/.config/radio-record/<label>.env" >&2
  echo "  (optional) ~/.config/systemd/user/radio-record@.service" >&2
  echo "  (optional) ~/bin/record-radio.sh" >&2
  exit 2
}

LABEL="${1:-}"
[[ -n "$LABEL" ]] || usage

SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"
RADIO_ENV_DIR="${HOME}/.config/radio-record"
BIN_DIR="${HOME}/bin"

TIMER_UNIT="radio-record@${LABEL}.timer"
SERVICE_UNIT="radio-record@${LABEL}.service"

TIMER_PATH="${SYSTEMD_USER_DIR}/${TIMER_UNIT}"
ENV_PATH="${RADIO_ENV_DIR}/${LABEL}.env"
SERVICE_TEMPLATE_PATH="${SYSTEMD_USER_DIR}/radio-record@.service"
SCRIPT_PATH="${BIN_DIR}/record-radio.sh"

# Stop and disable timer if present
if systemctl --user list-unit-files | grep -q "^${TIMER_UNIT}"; then
  systemctl --user disable --now "${TIMER_UNIT}" || true
fi

rm -f "$TIMER_PATH" "$ENV_PATH"

# Optional cleanups if not used by any other label
if ! ls -1 "${SYSTEMD_USER_DIR}"/radio-record@*.timer >/dev/null 2>&1; then
  rm -f "$SERVICE_TEMPLATE_PATH"
fi

if ! ls -1 "${RADIO_ENV_DIR}"/*.env >/dev/null 2>&1; then
  rm -f "$SCRIPT_PATH"
fi

echo "Removed:"
[[ ! -f "$TIMER_PATH" ]] && echo "  $TIMER_PATH"
[[ ! -f "$ENV_PATH" ]] && echo "  $ENV_PATH"
[[ ! -f "$SERVICE_TEMPLATE_PATH" ]] && echo "  $SERVICE_TEMPLATE_PATH"
[[ ! -f "$SCRIPT_PATH" ]] && echo "  $SCRIPT_PATH"

echo
echo "Now run:"
echo "  systemctl --user daemon-reload"
