# Claude Usage Menu Bar

A [SwiftBar](https://swiftbar.app) plugin that shows your Claude Code 5h/7d usage-limit
remaining as a battery-gauge icon in the macOS menu bar.

<!-- screenshot goes here -->

## How it works

```
Claude Code session
  -> statusLine hook (cache-writer/claude-usage-cache.sh)
  -> ~/.claude/statusline-rate-limits-cache.json
  -> SwiftBar plugin (claude-usage.5m.sh), polled every 5 minutes
  -> menu bar icon + dropdown detail
```

Claude Code only reports rate-limit data through the `statusLine` hook, and only while a
session is active. The cache-writer script saves the latest known 5h/7d percentages to
disk on every turn, so the menu bar plugin (which runs independently of any open Claude
Code session) always has a value to show, falling back to the last known numbers
(marked stale after 20 minutes) when no session is running.

## Requirements

- [SwiftBar](https://swiftbar.app)
- [Claude Code](https://claude.com/claude-code) CLI, with rate limit reporting available on your plan
- `jq`, `bash` (both ship with or are easy to add on macOS: `brew install jq`)

## Install

```bash
git clone https://github.com/hamin-apple/claude-usage-menubar.git
cd claude-usage-menubar
./install.sh
```

`install.sh` copies the plugin into SwiftBar's Plugins folder and the icon assets into
their own folder, then prints the `statusLine` snippet to add to
`~/.claude/settings.json`. It won't touch that file for you — merge the snippet in by
hand alongside any settings you already have.

After that, open (or restart) a Claude Code session once to populate the cache, then
restart SwiftBar:

```bash
pkill -x SwiftBar && open -a SwiftBar
```

### Manual install

1. Copy `claude-usage.5m.sh` to `~/Library/Application Support/SwiftBar/Plugins/` and
   `chmod +x` it.
2. Copy everything under `assets/` to
   `~/Library/Application Support/ClaudeUsageMenuBar/claude-usage-assets/` (this must be
   **outside** SwiftBar's own Plugins folder tree — see gotcha #1 below).
3. Add a `statusLine` command to `~/.claude/settings.json` pointing at
   `cache-writer/claude-usage-cache.sh`.
4. Start a Claude Code session once, then restart SwiftBar.

## Customization

- **Bucket thresholds** (which icon shows at which remaining %): `bucket_for()` in
  `claude-usage.5m.sh`.
- **Stale timeout**: `STALE_SECS` at the top of `claude-usage.5m.sh` (default 20 min).
- **Which limit to show**: `SHOW_METRIC` at the top of `claude-usage.5m.sh` —
  `auto` (default, shows whichever of 5h/7d has less remaining), `five_hour`, or
  `seven_day`.
- **Icon design**: edit `assets/icon-*.png` directly, or regenerate via
  `assets/generate-icons.py` (requires your own source silhouette image — see the note
  in that file).
- **Poll interval**: rename `claude-usage.5m.sh` using SwiftBar's interval syntax
  (`10s`, `1m`, `1h`, etc).

## SwiftBar gotchas

Learned the hard way on SwiftBar 2.1.1 (597):

1. **Only the plugin script belongs in the Plugins folder.** SwiftBar recursively scans
   `~/Library/Application Support/SwiftBar/Plugins/` and turns any other script/image it
   finds in there (including subfolders) into its own menu bar item. Keep icons and
   build scripts elsewhere — that's why `install.sh` puts them under a separate
   `ClaudeUsageMenuBar` folder.
2. **Avoid streamable (`<swiftbar.streamable>true</swiftbar.streamable>`) plugins** for
   something like this — a long-running process that writes to its own cache/data
   folder can retrigger the Plugins folder watcher and cause duplicate runs. This plugin
   is a plain one-shot script that SwiftBar runs on a timer and exits.
3. **Don't rely on `$HOME` or other env vars inside the plugin.** SwiftBar sometimes runs
   plugins with an empty `$HOME` in the GUI environment. This plugin resolves `$HOME` at
   the top and if that's ever empty for you, hardcode the paths instead.
4. **Restart SwiftBar with `pkill -x SwiftBar && open -a SwiftBar`**, not by launching the
   binary directly — the latter bypasses the single-instance check and can spawn
   duplicate menu bar items.
5. **Don't set the plugin folder via `defaults write com.ameba.SwiftBar PluginDirectory
   ...`** — this has a known bug where SwiftBar creates recursive mirror folders of
   itself. Use the GUI preferences instead, and `rm -rf` any
   `SwiftBar/Plugins/Users` junk folder that shows up.

An earlier version of this plugin tried compositing the percentage text onto the icon
bitmap (to control left/right ordering) instead of using SwiftBar's native title text.
It was dropped — no amount of supersampling or dark-mode color handling matched the
sharpness of SwiftBar/AppKit's own native title rendering. If icon/text ordering matters
to you, that's the tradeoff: native title text always renders after the image.

## License

MIT — see [LICENSE](LICENSE).
