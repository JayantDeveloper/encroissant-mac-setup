#!/bin/bash
# Sets up En Croissant + Stockfish on a Mac, and puts an "Import PGN" shortcut on the Desktop.
# Safe to run again: it skips what's already there and refreshes the Stockfish entry.
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/JayantDeveloper/encroissant-mac-setup/main"
APP_DIR="${APP_DIR:-/Applications}"
APPDATA="$HOME/Library/Application Support/org.encroissant.app"
TOOLS="$HOME/Library/Application Support/encroissant-setup"
DOCS="$HOME/Documents/EnCroissant"

say() { printf '\n\033[1m%s\033[0m\n' "$*"; }
die() { printf '\n\033[31mError: %s\033[0m\n' "$*" >&2; exit 1; }
[[ "$(uname)" == Darwin ]] || die "this script is for macOS."

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Pull the download link for a release asset out of GitHub's API (no jq on a fresh Mac).
asset_url() {  # repo, asset-name regex
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" |
    grep -o '"browser_download_url": *"[^"]*"' | sed 's/.*"\(https[^"]*\)"/\1/' | grep -E "$2" | head -1
}

# 1. En Croissant
if ls -d "$APP_DIR"/[Ee]n*[Cc]roissant*.app >/dev/null 2>&1; then
  say "1/3 En Croissant is already installed, skipping."
else
  say "1/3 Downloading En Croissant..."
  [[ "$(uname -m)" == arm64 ]] && arch=aarch64 || arch=x64
  url="$(asset_url franciscoBSalgueiro/en-croissant "_${arch}\.dmg$")"
  [[ -n "$url" ]] || die "couldn't find the En Croissant download."
  curl -fL --progress-bar "$url" -o "$tmp/ec.dmg"
  hdiutil attach "$tmp/ec.dmg" -nobrowse -readonly -mountpoint "$tmp/mnt" -quiet
  cp -R "$tmp"/mnt/*.app "$APP_DIR"/
  hdiutil detach "$tmp/mnt" -quiet
  xattr -dr com.apple.quarantine "$APP_DIR"/[Ee]n*[Cc]roissant*.app 2>/dev/null || true
  echo "Installed to $APP_DIR."
fi

# 2. Stockfish (official universal build, works on Intel and Apple Silicon)
say "2/3 Downloading Stockfish..."
url="$(asset_url official-stockfish/Stockfish 'macos-universal\.tar')"
[[ -n "$url" ]] || die "couldn't find the Stockfish download."
version="$(basename "$(dirname "$url")" | sed 's/^sf_//')"
mkdir -p "$APPDATA/engines/stockfish"
curl -fL --progress-bar "$url" -o "$tmp/sf.tar.gz"
tar -xzf "$tmp/sf.tar.gz" -C "$tmp"
bin="$(find "$tmp" -type f -name 'stockfish*' ! -name '*.tar.gz' -perm -u+x | head -1)"
[[ -n "$bin" ]] || bin="$(find "$tmp" -type f -name 'stockfish-macos*' ! -name '*.tar.gz' | head -1)"
[[ -n "$bin" ]] || die "couldn't find the Stockfish program in the download."
engine="$APPDATA/engines/stockfish/stockfish"
cp "$bin" "$engine"; chmod +x "$engine"; xattr -d com.apple.quarantine "$engine" 2>/dev/null || true
"$engine" quit >/dev/null 2>&1 <<<"" || die "Stockfish was downloaded but won't run."

# Use half the cores, and a hash size that's safe on an 8 GB Mac.
cores="$(sysctl -n hw.ncpu)"; threads=$(( cores > 1 ? cores / 2 : 1 ))
ram_gb=$(( $(sysctl -n hw.memsize) / 1073741824 )); hash=256; (( ram_gb >= 16 )) && hash=512

# Add (or refresh) Stockfish in En Croissant's engine list. JavaScript for Automation ships with macOS.
osascript -l JavaScript - "$APPDATA/engines/engines.json" "$engine" "$version" "$threads" "$hash" <<'JS' >/dev/null
function run(argv) {
  ObjC.import('Foundation');
  const [file, path, version, threads, hash] = argv;
  let list = [];
  const txt = $.NSString.stringWithContentsOfFileEncodingError(file, $.NSUTF8StringEncoding, null);
  if (!txt.isNil()) { try { list = JSON.parse(txt.js); } catch (e) { list = []; } }
  list = list.filter(e => e.path !== path);
  list.unshift({ type: "local", id: $.NSUUID.UUID.UUIDString.js.toLowerCase(), name: "Stockfish " + version,
    version: version, path: path, loaded: true, enabled: true, go: { t: "Infinite" },
    settings: [{ name: "MultiPV", value: 3 }, { name: "Threads", value: +threads }, { name: "Hash", value: +hash }] });
  $(JSON.stringify(list, null, 4)).writeToFileAtomicallyEncodingError(file, true, $.NSUTF8StringEncoding, null);
}
JS
echo "Stockfish $version added to En Croissant ($threads threads, $hash MB hash)."

# 3. Import tool + Desktop shortcut
say "3/3 Adding the Import PGN shortcut..."
mkdir -p "$TOOLS" "$DOCS"
here="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" && pwd)"
if [[ -f "$here/import.sh" ]]; then cp "$here/import.sh" "$TOOLS/import.sh"
else curl -fsSL "$REPO_RAW/import.sh" -o "$TOOLS/import.sh"; fi
chmod +x "$TOOLS/import.sh"
shortcut="$HOME/Desktop/Import PGN into En Croissant.command"
printf '#!/bin/bash\nbash "%s/import.sh" "$@"\n' "$TOOLS" > "$shortcut"
chmod +x "$shortcut"

say "All set!"
echo "Next: double-click \"Import PGN into En Croissant\" on your Desktop and drag your PGN files in."
