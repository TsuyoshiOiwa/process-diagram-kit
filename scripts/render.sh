#!/usr/bin/env bash
# 単一 .d2 を tala レイアウト + IPA フォントで out/ にビルドする (レイアウト確認用)
# usage: ./scripts/render.sh works/foo.d2 [png|svg]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FILE="${1:?usage: render.sh <file.d2> [png|svg]}"
FMT="${2:-png}"
OUT="out/$(basename "${FILE%.*}").${FMT}"

mkdir -p out
d2 --layout=tala --font-regular=./fonts/opentype/ipafont-gothic/ipag.ttf "$FILE" "$OUT"
echo "rendered: $OUT"
