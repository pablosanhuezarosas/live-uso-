#!/bin/bash
# Usage: set-volume.sh <volume float, e.g. 0.5, 1.0, 1.5>
VOL="$1"
[ -z "$VOL" ] && exit 1
echo "$VOL" > "$HOME/.claude/sound-volume.txt"
afplay -v "$VOL" "$HOME/.claude/sounds/success.mp3" &
