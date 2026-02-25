#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <label_YYYY-MM-DD_hh-mm.m4a> <start_hh:mm:ss> <end_hh:mm:ss>" >&2
  echo "Example: $0 SnowmanShow_2026-02-24_18-55.m4a 00:04:53 01:24:37" >&2
  exit 2
fi

in="$1"
START="$2"
END="$3"

base="$(basename "$in")"

# Expect: label_YYYY-MM-DD_hh-mm.m4a
if [[ ! "$base" =~ ^(.+)_([0-9]{4}-[0-9]{2}-[0-9]{2})_[0-9]{2}-[0-9]{2}\.m4a$ ]]; then
  echo "Input must be named like: label_YYYY-MM-DD_hh-mm.m4a" >&2
  echo "Got: $base" >&2
  exit 2
fi

label="${BASH_REMATCH[1]}"
date="${BASH_REMATCH[2]}"

out="${label}_${date}.m4a"

# ---- EDIT THESE ONCE (show-level metadata) ----
COVER_IMAGE="snowman-logo.jpeg"
TITLE='7@7'
ARTIST='Tim Sorenson'
ALBUM="Snowman's Seven at Seven – Radio Woodville"
GENRE='Podcast'
COMMENT='Cut from the original broadcast.'
# ----------------------------------------------

# Basic validation of time format
if [[ ! "$START" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?$ ]]; then
  echo "START must be hh:mm:ss (optionally .ms), got: $START" >&2
  exit 2
fi
if [[ ! "$END" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?$ ]]; then
  echo "END must be hh:mm:ss (optionally .ms), got: $END" >&2
  exit 2
fi

ffmpeg -hide_banner -y \
  -ss "$START" -to "$END" -i "$in" \
  -i "$COVER_IMAGE" \
  -map 0:a:0 -map 1:v:0 \
  -c:a copy -c:v mjpeg \
  -disposition:v:0 attached_pic \
  -metadata "title=$TITLE" \
  -metadata "artist=$ARTIST" \
  -metadata "album=$ALBUM" \
  -metadata "date=$date" \
  -metadata "genre=$GENRE" \
  -metadata "comment=$COMMENT" \
  "$out"

echo "Wrote: $out"