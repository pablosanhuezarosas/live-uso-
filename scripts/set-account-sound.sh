#!/bin/bash
# Usage: set-account-sound.sh <source-sound-file>
# Sets the sound used by the account rate-limit threshold alerts (20/50/75/90/95%).
# Kept separate from set-sound.sh (permission/success/error hooks) on purpose —
# these are independent settings, not shared state.
SRC="$1"
TARGET="$HOME/.claude/sounds/account-alert.mp3"
STATE_FILE="$HOME/.claude/sound-settings.json"

if [ -z "$SRC" ] || [ ! -f "$SRC" ]; then
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
d['account_alert'] = '$SRC_NAME'
with open('$STATE_FILE', 'w') as f:
    json.dump(d, f)
"

VOLUME=$(cat "$HOME/.claude/account-alert-volume.txt" 2>/dev/null || echo 1.0)
afplay -v "$VOLUME" "$TARGET" &
