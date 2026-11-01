#!/bin/zsh
set -euo pipefail

# Tells you when Crest has changes Thundermist doesn't, because it has no
# automatic updates. It only notifies; run Scripts/update-thundermist.sh to update.
#
# Usage: Scripts/thundermist-update-reminder.sh             check now and notify
#        Scripts/thundermist-update-reminder.sh --install   check every Sunday at 10:00
#        Scripts/thundermist-update-reminder.sh --remove    stop checking

repository_root="${0:A:h:h}"
label="com.theburl.thundermist.update-reminder"
agent="$HOME/Library/LaunchAgents/$label.plist"
domain="gui/$(id -u)"

case "${1:-}" in
  --install)
    mkdir -p "${agent:h}"
    cat > "$agent" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>$label</string>
	<key>ProgramArguments</key>
	<array>
		<string>/bin/zsh</string>
		<string>${0:A}</string>
	</array>
	<key>StartCalendarInterval</key>
	<dict>
		<key>Weekday</key>
		<integer>0</integer>
		<key>Hour</key>
		<integer>10</integer>
		<key>Minute</key>
		<integer>0</integer>
	</dict>
	<key>StandardOutPath</key>
	<string>$HOME/Library/Logs/thundermist-update-reminder.log</string>
	<key>StandardErrorPath</key>
	<string>$HOME/Library/Logs/thundermist-update-reminder.log</string>
</dict>
</plist>
PLIST
    launchctl bootout "$domain/$label" 2>/dev/null || true
    launchctl bootstrap "$domain" "$agent"
    print "Thundermist will check for Crest updates every Sunday at 10:00."
    exit 0
    ;;
  --remove)
    launchctl bootout "$domain/$label" 2>/dev/null || true
    rm -f "$agent"
    print "Stopped checking for Crest updates."
    exit 0
    ;;
  "") ;;
  *)
    print -u2 "Usage: Scripts/thundermist-update-reminder.sh [--install|--remove]"
    exit 64
    ;;
esac

cd "$repository_root"
git fetch --quiet upstream
behind="$(git rev-list --count thundermist..upstream/main)"
print "$(date): $behind commit(s) behind Crest."
[[ "$behind" == 0 ]] && exit 0

if git diff --quiet thundermist...upstream/main -- CrestEngines/Chromium/source.lock.json; then
  title="Crest has $behind new change(s)"
else
  title="Crest has a Chromium update"
fi
osascript - "$title" <<'APPLESCRIPT'
on run arguments
    display notification "Run Scripts/update-thundermist.sh in crest-fork to update Thundermist." with title (item 1 of arguments)
end run
APPLESCRIPT
