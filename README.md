# HermesTokenBar

A tiny native macOS menu bar monitor for Hermes Agent token activity.

HermesTokenBar reads Hermes Agent's local SQLite session database in read-only mode and shows today's token total in the macOS status bar. The dropdown menu shows Today/Month totals, model-side Input/Output breakdowns, top models, database path, and last refresh time.

## What it looks like

Status bar:

```text
10.0M
```

Dropdown:

```text
Hermes Token Bar
Today total: 10.0M tokens
  Input: 9.9M tokens
  Output: 19.1K tokens
Month total: 2,109.0M tokens
  Input: 2,103.1M tokens
  Output: 5.9M tokens

Top models this month
  deepseek-v4-pro: 1,257.1M
  deepseek-v4-flash: 665.5M

DB: ~/.hermes/state.db
Read-only · no hooks
Updated: 2026-05-25 01:03:29
Refresh
Quit HermesTokenBar
```

Menu color coding is intentionally restrained:

- Today total: blue
- Input: green
- Output: orange
- Month total: purple
- Secondary metadata: gray

## Privacy and safety

HermesTokenBar is intentionally small and local-only.

It does:

- read `~/.hermes/state.db` by default
- open SQLite with `SQLITE_OPEN_READONLY`
- refresh every 60 seconds
- show token activity in the macOS menu bar

It does not:

- upload data
- call network APIs
- install hooks
- modify Hermes config
- write to Hermes state
- depend on TokenTracker
- read or display API keys

## Requirements

- macOS 13+
- Swift 6 toolchain or newer
- Hermes Agent with a local `state.db`

## Build and run from source

```bash
git clone https://github.com/MuseFantasy/hermes-tokenbar.git
cd hermes-tokenbar
swift run HermesTokenCoreSmokeTests
scripts/build_app.sh
open -a "$HOME/Applications/HermesTokenBar.app"
```

The build script installs the app bundle at:

```text
~/Applications/HermesTokenBar.app
```

The app is configured as `LSUIElement=true`, so it has no Dock icon.

## Custom database path

By default, HermesTokenBar reads:

```text
~/.hermes/state.db
```

To use another database path, launch the executable directly with an environment variable:

```bash
HERMES_TOKENBAR_DB=/path/to/state.db \
  "$HOME/Applications/HermesTokenBar.app/Contents/MacOS/HermesTokenBar"
```

For persistent custom paths, set the environment variable in your LaunchAgent or shell wrapper. If you launch via Finder or `open -a`, use the default database path unless your LaunchAgent provides the environment explicitly.

## Token semantics

HermesTokenBar displays token activity from Hermes Agent's `sessions` table.

```text
Input  = input_tokens + cache_read_tokens + cache_write_tokens
Output = output_tokens + reasoning_tokens
Total  = Input + Output
```

This is a model-side token activity view. It is not a billing ledger and does not claim exact provider billing cost.

Formatting:

- status bar total: M units, one decimal, grouped numbers
- Today/Month totals: M units, one decimal, grouped numbers
- Input/Output detail rows: adaptive units
  - `>= 1M`: M
  - `>= 1K`: K
  - `< 1K`: raw number

## Login autostart

Create a per-user LaunchAgent:

```bash
cat > "$HOME/Library/LaunchAgents/com.muse.hermes-tokenbar.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.muse.hermes-tokenbar</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/open</string>
        <string>-a</string>
        <string>$HOME/Applications/HermesTokenBar.app</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/HermesTokenBar.launchd.out.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/HermesTokenBar.launchd.err.log</string>
</dict>
</plist>
PLIST

plutil -lint "$HOME/Library/LaunchAgents/com.muse.hermes-tokenbar.plist"
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.muse.hermes-tokenbar.plist"
launchctl enable "gui/$(id -u)/com.muse.hermes-tokenbar"
launchctl kickstart -k "gui/$(id -u)/com.muse.hermes-tokenbar"
```

Disable autostart:

```bash
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.muse.hermes-tokenbar.plist"
rm "$HOME/Library/LaunchAgents/com.muse.hermes-tokenbar.plist"
```

## Development checks

```bash
python3 scripts/check_release_hygiene.py
python3 scripts/check_colored_menu_items.py
python3 scripts/check_adaptive_detail_format.py
python3 scripts/check_input_output_breakdown.py
python3 scripts/check_status_label_format.py
python3 scripts/check_no_floating_window.py
swift run HermesTokenCoreSmokeTests
swift build -c release --product HermesTokenBar
```

## Release packaging

```bash
scripts/build_app.sh
cd "$HOME/Applications"
zip -r HermesTokenBar.app.zip HermesTokenBar.app
shasum -a 256 HermesTokenBar.app.zip
```

Upload `HermesTokenBar.app.zip` and its SHA256 to a GitHub Release.

## License

MIT
