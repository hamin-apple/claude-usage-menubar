#!/bin/bash
# <swiftbar.title>Claude Usage</swiftbar.title>
# <swiftbar.version>1.4</swiftbar.version>
# <swiftbar.author>jahoonjin</swiftbar.author>
# <swiftbar.desc>Shows remaining Claude Code usage limit (5h/7d) as a battery gauge in the menu bar.</swiftbar.desc>

CACHE_FILE="$HOME/.claude/statusline-rate-limits-cache.json"
ICON_DIR="$HOME/Library/Application Support/ClaudeUsageMenuBar/claude-usage-assets"
STALE_SECS=1200 # 20 min

# Which limit's remaining percentage to show in the menu bar:
#   auto       -> whichever of 5h/7d has less remaining (most urgent)
#   five_hour  -> always show the 5h limit
#   seven_day  -> always show the 7d limit
SHOW_METRIC="auto"

to_int() {
  [ -z "$1" ] && { echo 0; return; }
  printf "%.0f" "$1"
}

bucket_for() {
  local r=$1
  if   (( r >= 90 )); then echo 100
  elif (( r >= 70 )); then echo 80
  elif (( r >= 50 )); then echo 60
  elif (( r >= 30 )); then echo 40
  elif (( r >= 10 )); then echo 20
  else echo 0
  fi
}

render_frame() {
  if [ ! -f "$CACHE_FILE" ]; then
    echo "?"
    echo "---"
    echo "Claude usage data not available yet"
    echo "Open a Claude Code session once to populate the cache"
    return
  fi

  local five_used seven_used five_reset seven_reset
  five_used=$(to_int "$(jq -r '.five_hour.used_percentage // empty' "$CACHE_FILE")")
  seven_used=$(to_int "$(jq -r '.seven_day.used_percentage // empty' "$CACHE_FILE")")
  five_reset=$(jq -r '.five_hour.resets_at // empty' "$CACHE_FILE")
  seven_reset=$(jq -r '.seven_day.resets_at // empty' "$CACHE_FILE")

  local five_remaining=$(( 100 - five_used ))
  local seven_remaining=$(( 100 - seven_used ))

  local shown_remaining
  case "$SHOW_METRIC" in
    five_hour) shown_remaining=$five_remaining ;;
    seven_day) shown_remaining=$seven_remaining ;;
    *)
      shown_remaining=$five_remaining
      (( seven_remaining < five_remaining )) && shown_remaining=$seven_remaining
      ;;
  esac

  local bucket icon icon_b64
  bucket=$(bucket_for "$shown_remaining")
  icon="$ICON_DIR/icon-${bucket}.png"
  icon_b64=$(base64 < "$icon" | tr -d '\n')

  local mtime now age stale=0
  mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
  now=$(date +%s)
  age=$(( now - mtime ))
  (( age > STALE_SECS )) && stale=1

  local title="${shown_remaining}%"
  (( stale )) && title="${title} (stale)"
  echo "${title}|image=${icon_b64}"
  echo "---"

  if (( stale )); then
    echo "No recent Claude Code session — showing last known values|color=gray"
    echo "---"
  fi

  local five_reset_fmt="-" seven_reset_fmt="-"
  [ -n "$five_reset" ] && five_reset_fmt=$(date -r "${five_reset%.*}" "+%H:%M")
  [ -n "$seven_reset" ] && seven_reset_fmt=$(date -r "${seven_reset%.*}" "+%m/%d %H:%M")

  echo "5h limit: ${five_used}% used, ${five_remaining}% remaining (resets ${five_reset_fmt})"
  echo "7d limit: ${seven_used}% used, ${seven_remaining}% remaining (resets ${seven_reset_fmt})"
  echo "---"
  echo "Refresh|refresh=true"
}

render_frame
