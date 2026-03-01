#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/PrintableBingoOffline/Resources/Voice/Numbers"
VOICE="Samantha"

mkdir -p "$OUT_DIR"

for i in $(seq 1 90); do
  tmp_aiff="$OUT_DIR/${i}-English.aiff"
  out_mp3="$OUT_DIR/${i}-English.mp3"

  if [[ -f "$out_mp3" ]]; then
    echo "Skipping $out_mp3 (exists)"
    continue
  fi

  say -v "$VOICE" -o "$tmp_aiff" "$i"
  afconvert -f mp3 -d "mp3" "$tmp_aiff" "$out_mp3"
  rm -f "$tmp_aiff"
  echo "Generated $out_mp3"
done
