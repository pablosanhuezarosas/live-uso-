#!/bin/bash
# Toggles the sound for account rate-limit alerts (20/50/75/90/95%) on/off.
# The visual bar in the menu bar keeps updating regardless of mute state.
MUTE_FILE="$HOME/.claude/account-alert-muted"

if [ -f "$MUTE_FILE" ]; then
  rm -f "$MUTE_FILE"
else
  touch "$MUTE_FILE"
fi
