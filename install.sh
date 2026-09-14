#!/bin/bash
# Installs the Claude Usage SwiftBar menu bar widget.
#
#   - Copies the plugin into SwiftBar's Plugins folder, with your absolute home
#     path written into it (SwiftBar sometimes runs plugins with an empty $HOME).
#   - Copies the icon assets into a folder OUTSIDE SwiftBar's Plugins tree
#     (SwiftBar recursively scans the Plugins folder and would otherwise
#     treat the icons/build script as extra plugins — see README).
#   - Copies the cache writer to ~/.claude/claude-usage-cache.sh, so the
#     statusLine command doesn't depend on where this repo was cloned.
#   - Prints, but does not silently apply, the statusLine config you need to
#     add to ~/.claude/settings.json.
#
# Requires: SwiftBar (https://swiftbar.app) and jq (`brew install jq`).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$HOME/Library/Application Support/SwiftBar/Plugins"
ASSETS_DIR="$HOME/Library/Application Support/ClaudeUsageMenuBar/claude-usage-assets"
PLUGIN="$PLUGINS_DIR/claude-usage.3m.sh"
CACHE_WRITER="$HOME/.claude/claude-usage-cache.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found. Install it first: brew install jq" >&2
  exit 1
fi

mkdir -p "$PLUGINS_DIR" "$ASSETS_DIR" "$HOME/.claude"

home_escaped=$(printf '%s' "$HOME" | sed 's/[&|\\]/\\&/g')
sed -E "/^(CACHE_FILE|ICON_DIR)=/s|\\\$HOME|${home_escaped}|" \
  "$SCRIPT_DIR/claude-usage.3m.sh" > "$PLUGIN"
if grep -Eq '^(CACHE_FILE|ICON_DIR)=.*\$HOME' "$PLUGIN"; then
  echo "Failed to write absolute paths into $PLUGIN" >&2
  exit 1
fi
chmod +x "$PLUGIN"

cp "$SCRIPT_DIR"/assets/icon-*.png "$ASSETS_DIR/"
cp "$SCRIPT_DIR/assets/generate-icons.py" "$ASSETS_DIR/generate-icons.py"

cp "$SCRIPT_DIR/cache-writer/claude-usage-cache.sh" "$CACHE_WRITER"
chmod +x "$CACHE_WRITER"

echo "Installed plugin:       $PLUGIN"
echo "Installed assets:       $ASSETS_DIR"
echo "Installed cache writer: $CACHE_WRITER"
echo
echo "Next steps:"
echo "1. Make sure SwiftBar is installed and running: https://swiftbar.app"
echo "2. Add this to ~/.claude/settings.json (keep your other settings):"
echo
echo '   "statusLine": {'
echo '     "type": "command",'
echo '     "command": "bash ~/.claude/claude-usage-cache.sh"'
echo '   }'
echo
echo "   statusLine takes a single command, so this replaces any status line you"
echo "   already have. To keep your own, see \"Already have a custom status line?\""
echo "   in the README."
echo
echo "3. Start (or restart) a Claude Code session once to populate the cache."
echo "4. Restart SwiftBar: pkill -x SwiftBar && open -a SwiftBar"
