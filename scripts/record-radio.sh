#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <label>" >&2
  exit 2
fi

LABEL="$1"

: "${RADIO_URL:?RADIO_URL is required}"
: "${RADIO_DURATION_SECONDS:?RADIO_DURATION_SECONDS is required}"

OUTDIR="${RADIO_OUTDIR:-$HOME/radio-recordings}"
OUTDIR="${OUTDIR/#\~/$HOME}"
CODEC="${RADIO_CODEC:-aac}"
BITRATE="${RADIO_BITRATE:-192k}"

mkdir -p "$OUTDIR"

ts="$(date +%F_%H-%M)"

SAFE_LABEL="$(echo "$LABEL" | LC_ALL=C tr -cs 'A-Za-z0-9._+-' '_' | sed 's/^_//; s/_$//')"
# Use systemd's $SCHEDULED_START_TIME if available, else fallback to now
if [[ -n "${SCHEDULED_START_TIME:-}" ]]; then
  # Format: 2026-04-21 18:55:00 NZST
  ts="$(date -d "$SCHEDULED_START_TIME" +%F_%H-%M)"
else
  ts="$(date +%F_%H-%M)"
fi

case "$CODEC" in
  aac) ext="m4a" ;;
  mp3) ext="mp3" ;;
  *) echo "Unsupported RADIO_CODEC=$CODEC (use aac or mp3)" >&2; exit 2 ;;
esac

out="$OUTDIR/${SAFE_LABEL}_${ts}.${ext}"

if [[ "$CODEC" == "aac" ]]; then
  exec ffmpeg -hide_banner -nostdin -loglevel info \
    -t "$RADIO_DURATION_SECONDS" -i "$RADIO_URL" \
    -c:a aac -b:a "$BITRATE" \
    -movflags +faststart+frag_keyframe+empty_moov \
    "$out"
else
  exec ffmpeg -hide_banner -nostdin -loglevel info \
    -t "$RADIO_DURATION_SECONDS" -i "$RADIO_URL" \
    -c:a libmp3lame -b:a "$BITRATE" \
    "$out"
fi
