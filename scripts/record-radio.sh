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
CODEC="${RADIO_CODEC:-copy}"
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
  copy)
    # Keep the stream's own bytes. The extension has to match what is actually
    # arriving, so ask the stream; if that fails (we are usually unattended,
    # and a dead probe must not cost us the recording) fall back to the URL.
    src="$(timeout 30 ffprobe -v error -select_streams a:0 \
             -show_entries stream=codec_name -of csv=p=0 "$RADIO_URL" 2>/dev/null || true)"
    if [[ -z "$src" ]]; then
      url_ext="${RADIO_URL##*.}"
      case "$url_ext" in
        mp3) src="mp3" ;;
        aac) src="aac" ;;
      esac
      echo "could not probe stream codec; assuming '${src:-unknown}' from URL" >&2
    fi
    case "$src" in
      # Both are raw framed formats: a recording cut short mid-write still plays.
      mp3) ext="mp3" ;;
      aac) ext="aac" ;;
      *) echo "RADIO_CODEC=copy cannot handle stream codec '${src:-unknown}'" >&2; exit 2 ;;
    esac
    ;;
  *) echo "Unsupported RADIO_CODEC=$CODEC (use aac, mp3 or copy)" >&2; exit 2 ;;
esac

out="$OUTDIR/${SAFE_LABEL}_${ts}.${ext}"

if [[ "$CODEC" == "copy" ]]; then
  exec ffmpeg -hide_banner -nostdin -loglevel info \
    -rw_timeout 10000000 \
    -reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 60 \
    -t "$RADIO_DURATION_SECONDS" -i "$RADIO_URL" \
    -c copy \
    "$out"
elif [[ "$CODEC" == "aac" ]]; then
  exec ffmpeg -hide_banner -nostdin -loglevel info \
    -rw_timeout 10000000 \
    -reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 60 \
    -t "$RADIO_DURATION_SECONDS" -i "$RADIO_URL" \
    -c:a aac -b:a "$BITRATE" \
    -movflags +faststart+frag_keyframe+empty_moov \
    "$out"
else
  exec ffmpeg -hide_banner -nostdin -loglevel info \
    -rw_timeout 10000000 \
    -reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 60 \
    -t "$RADIO_DURATION_SECONDS" -i "$RADIO_URL" \
    -c:a libmp3lame -b:a "$BITRATE" \
    "$out"
fi
