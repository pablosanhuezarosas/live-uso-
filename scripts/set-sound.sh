#!/bin/bash
# Usage: set-sound.sh <event: permission|success|error> <source-sound-file>
# Copies the chosen sound over the fixed target file the hooks always call,
# records the choice so the menu can show which one is active, and plays it
# once as confirmation.
EVENT="$1"
SRC="$2"
TARGET="$HOME/.claude/sounds/$EVENT.mp3"
STATE_FILE="$HOME/.claude/sound-settings.json"

if [ -z "$EVENT" ] || [ -z "$SRC" ] || [ ! -f "$SRC" ]; then
  exit 1
fi

cp "$SRC" "$TARGET"

SRC_NAME=$(basename "$SRC")
python3 -c "
import json
try:
    with open('$STATE_FILE') as f:
        d = json.load(f)
except Exception:
    d = {}
d['$EVENT'] = '$SRC_NAME'
with open('$STATE_FILE', 'w') as f:
    json.dump(d, f)
"

VOLUME=$(cat "$HOME/.claude/sound-volume.txt" 2>/dev/null || echo 1.0)
afplay -v "$VOLUME" "$TARGET" &
