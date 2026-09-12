#!/bin/bash
# Installs the Claude Usage SwiftBar menu bar widget.
#
#   - Copies the plugin script into SwiftBar's Plugins folder.
#   - Copies the icon assets into a folder OUTSIDE SwiftBar's Plugins tree
#     (SwiftBar recursively scans the Plugins folder and would otherwise
#     treat the icons/build script as extra plugins — see README).
#   - Prints, but does not silently apply, the statusLine config you need to
#     add to ~/.claude/settings.json.
#
# Requires: SwiftBar (https://swiftbar.app) and jq (`brew install jq`).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$HOME/Library/Application Support/SwiftBar/Plugins"
ASSETS_DIR="$HOME/Library/Application Support/ClaudeUsageMenuBar/claude-usage-assets"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found. Install it first: brew install jq" >&2
  exit 1
fi

mkdir -p "$PLUGINS_DIR" "$ASSETS_DIR"

cp "$SCRIPT_DIR/claude-usage.5m.sh" "$PLUGINS_DIR/claude-usage.5m.sh"
chmod +x "$PLUGINS_DIR/claude-usage.5m.sh"

cp "$SCRIPT_DIR"/assets/icon-*.png "$ASSETS_DIR/"
cp "$SCRIPT_DIR/assets/generate-icons.py" "$ASSETS_DIR/generate-icons.py"

echo "Installed plugin: $PLUGINS_DIR/claude-usage.5m.sh"
echo "Installed assets: $ASSETS_DIR"
echo
echo "Next steps:"
echo "1. Make sure SwiftBar is installed and running: https://swiftbar.app"
echo "2. Add this statusLine command to ~/.claude/settings.json (merge with"
echo "   any existing settings, don't just overwrite the file):"
echo
echo '   "statusLine": {'
echo '     "type": "command",'
echo "     \"command\": \"bash $SCRIPT_DIR/cache-writer/claude-usage-cache.sh\""
echo '   }'
echo
echo "3. Start (or restart) a Claude Code session once to populate the cache."
echo "4. Restart SwiftBar: pkill -x SwiftBar && open -a SwiftBar"
