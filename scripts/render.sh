#!/usr/bin/env bash
# 単一 .d2 を tala レイアウト + IPA フォントで out/ にビルドする (レイアウト確認用)
# ファイルを repo ルート直下の tmp 配下にコピーしてからビルドすることで @../lib の相対 import を解決する
# usage: ./scripts/render.sh works/foo.d2 [png|svg]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FILE="${1:?usage: render.sh <file.d2> [png|svg]}"
FMT="${2:-png}"
OUT="out/${FILE%.*}.${FMT}"

TMP="$ROOT/tmp"
mkdir -p "$TMP" "$(dirname "$OUT")"

SRC="$TMP/render-$$-$(basename "$FILE")"
trap 'rm -f "$SRC"; rmdir "$TMP" 2>/dev/null || true' EXIT
cp "$FILE" "$SRC"

d2 --layout=tala --font-regular=./fonts/opentype/ipafont-gothic/ipag.ttf "$SRC" "$OUT"
echo "rendered: $OUT"
