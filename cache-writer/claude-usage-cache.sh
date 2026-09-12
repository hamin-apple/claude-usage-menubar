#!/bin/bash
# Minimal Claude Code `statusLine` command: caches the 5h/7d rate-limit
# percentages to disk so claude-usage.5m.sh (the SwiftBar menu bar plugin)
# can read them, and prints a one-line summary so it's also useful as a
# bare-bones statusline on its own.
#
# Install as your statusLine command in ~/.claude/settings.json:
#   { "statusLine": { "type": "command", "command": "bash /path/to/claude-usage-cache.sh" } }
#
# rate_limits is only present after the first API response of a session, so
# on a freshly started session (before any response) it's empty. Cache the
# latest known values so downstream readers still see real numbers
# immediately at startup, and refresh whenever fresh data is available.

input=$(cat)
CACHE_FILE="$HOME/.claude/statusline-rate-limits-cache.json"

five_h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
five_h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

if [ -n "$five_h" ] || [ -n "$seven_d" ]; then
  jq -n \
    --arg five "$five_h" --arg five_r "$five_h_reset" \
    --arg seven "$seven_d" --arg seven_r "$seven_d_reset" \
    '{
      five_hour: {
        used_percentage: (if $five == "" then null else ($five | tonumber) end),
        resets_at: (if $five_r == "" then null else ($five_r | tonumber) end)
      },
      seven_day: {
        used_percentage: (if $seven == "" then null else ($seven | tonumber) end),
        resets_at: (if $seven_r == "" then null else ($seven_r | tonumber) end)
      }
    }' > "$CACHE_FILE" 2>/dev/null
elif [ -f "$CACHE_FILE" ]; then
  five_h=$(jq -r '.five_hour.used_percentage // empty' "$CACHE_FILE" 2>/dev/null)
  five_h_reset=$(jq -r '.five_hour.resets_at // empty' "$CACHE_FILE" 2>/dev/null)
  seven_d=$(jq -r '.seven_day.used_percentage // empty' "$CACHE_FILE" 2>/dev/null)
  seven_d_reset=$(jq -r '.seven_day.resets_at // empty' "$CACHE_FILE" 2>/dev/null)
fi

fmt() {
  local pct="$1"
  [ -n "$pct" ] && printf "%.0f%%" "$pct" || echo "-"
}

printf "5h: %s | 7d: %s\n" "$(fmt "$five_h")" "$(fmt "$seven_d")"
