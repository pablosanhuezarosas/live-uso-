#!/bin/bash
# Usage: set-account-volume.sh <volume float, e.g. 0.5, 1.0>
# Volume for the account rate-limit threshold alerts only — independent of
# sound-volume.txt, which controls the permission/success/error hook sounds.
VOL="$1"
[ -z "$VOL" ] && exit 1
echo "$VOL" > "$HOME/.claude/account-alert-volume.txt"
afplay -v "$VOL" "$HOME/.claude/sounds/account-alert.mp3" &
