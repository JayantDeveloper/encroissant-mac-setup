#!/bin/bash
# Imports PGN files into En Croissant as repertoire files, with the right side set for Practice.
#   bash import.sh file.pgn [more.pgn | a-folder ...]     (or run with no arguments and drag files in)
set -uo pipefail

DOCS="${DOCS:-$HOME/Documents/EnCroissant}"
mkdir -p "$DOCS"

ask() { local a; read -r -p "$1" a </dev/tty; printf '%s' "$a"; }

if (( $# == 0 )); then
  echo "Drag your PGN files (or a folder of them) into this window, then press Enter:"
  read -r line </dev/tty
  eval "set -- $line"   # Terminal escapes dragged paths, so let the shell unpick them
fi

files=()
for p in "$@"; do
  if [[ -d "$p" ]]; then while IFS= read -r f; do files+=("$f"); done < <(find "$p" -iname '*.pgn' | sort)
  elif [[ -f "$p" ]]; then files+=("$p")
  else echo "Skipping $p (not found)"; fi
done
(( ${#files[@]} )) || { echo "No PGN files found."; exit 1; }

done_count=0
for f in "${files[@]}"; do
  name="$(basename "$f")"; name="${name%.*}"
  lower="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
  side=""
  [[ "$lower" == *white* ]] && side=white
  [[ "$lower" == *black* ]] && side=black
  while [[ -z "$side" ]]; do
    case "$(ask "Is \"$name\" your White or Black repertoire? [w/b] ")" in
      w|W) side=white ;; b|B) side=black ;;
    esac
  done
  dest="$DOCS/$name.pgn"
  if [[ -e "$dest" ]] && [[ "$(ask "\"$name\" already exists in En Croissant. Replace it? [y/N] ")" != [yY]* ]]; then
    echo "Kept the existing \"$name\"."; continue
  fi

  # ChessBase on Windows often writes Windows-1252 text with CRLF line endings; En Croissant wants UTF-8.
  if iconv -f UTF-8 -t UTF-8 "$f" >/dev/null 2>&1; then cat "$f"; else iconv -f WINDOWS-1252 -t UTF-8 "$f"; fi |
    sed $'1s/^\xEF\xBB\xBF//' | tr -d '\r' |
    awk -v side="$side" '
      /^\[Orientation / { next }
      /^\[[A-Za-z0-9_]+ "/ { if (!hdr) { print "[Orientation \"" side "\"]"; hdr = 1 } print; next }
      { if ($0 !~ /^[ \t]*$/) hdr = 0; print }' > "$dest"
  printf '{"type": "repertoire", "tags": ["%s"]}' "$side" > "${dest%.pgn}.info"
  games=$(grep -c '^\[Orientation ' "$dest")
  echo "Imported \"$name\" as a $side repertoire ($games game$( (( games == 1 )) || echo s))."
  done_count=$((done_count + 1))
done

echo
echo "Done: $done_count file(s). In En Croissant, open Files and double-click one to start."
