#!/bin/bash
# <xbar.title>Claude Status</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Pablo Sanhueza Rosas</xbar.author>
# <xbar.desc>Estado en vivo de Claude Code: idle, corriendo, esperando permiso, exito o error.</xbar.desc>
# <xbar.dependencies>bash</xbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>

STATE_FILE="$HOME/.claude/status.state"
STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "NOP")

case "$STATE" in
  RUN) MNEM="RUN"; COLOR="#39ff14" ;;
  INT) MNEM="INT"; if (( $(date +%s) % 2 == 0 )); then COLOR="#8aff5c"; else COLOR="#1fae0a"; fi ;;
  RET) MNEM="RET"; COLOR="#39ff14" ;;
  HLT) MNEM="HLT"; COLOR="#ff3b30" ;;
  *)   MNEM="NOP"; COLOR="#1fae0a" ;;
esac

echo "CLD:$MNEM | font=Menlo size=13 color=$COLOR"
echo "---"
echo "state: $STATE | font=Menlo color=#39ff14"
echo "NOP = idle | font=Menlo color=#1fae0a"
echo "RUN = ejecutando | font=Menlo color=#1fae0a"
echo "INT = esperando permiso | font=Menlo color=#1fae0a"
echo "RET = tarea OK | font=Menlo color=#1fae0a"
echo "HLT = error | font=Menlo color=#1fae0a"
echo "---"
echo "Refresh | refresh=true"
echo "---"
echo "▓ SETTINGS ▓ | font=Menlo size=11 color=#1fae0a"

SOUNDS_DIR="$HOME/.claude/sounds"
SET_SOUND="$HOME/.claude/scripts/set-sound.sh"
SOUND_STATE="$HOME/.claude/sound-settings.json"
mkdir -p "$SOUNDS_DIR"

for EVT in permission success error; do
  CURRENT=$(jq -r --arg e "$EVT" '.[$e] // "?"' "$SOUND_STATE" 2>/dev/null)
  echo "-- Sonido: $EVT (actual: $CURRENT) | font=Menlo size=11"
  for f in "$SOUNDS_DIR"/*.mp3; do
    [ -e "$f" ] || continue
    NAME=$(basename "$f")
    MARK=""
    [ "$NAME" = "$CURRENT" ] && MARK=" ✓"
    echo "---- $NAME$MARK | bash=$SET_SOUND param1=$EVT param2=\"$f\" terminal=false refresh=true"
  done
done

SET_VOLUME="$HOME/.claude/scripts/set-volume.sh"
CURRENT_VOL=$(cat "$HOME/.claude/sound-volume.txt" 2>/dev/null || echo "1.0")
echo "-- Volumen (actual: ${CURRENT_VOL}) | font=Menlo size=11"
for LEVEL in "10%:0.1" "20%:0.2" "30%:0.3" "40%:0.4" "50%:0.5" "60%:0.6" "70%:0.7" "80%:0.8" "90%:0.9" "100%:1.0"; do
  LABEL="${LEVEL%%:*}"
  VAL="${LEVEL##*:}"
  MARK=""
  [ "$VAL" = "$CURRENT_VOL" ] && MARK=" ✓"
  echo "---- $LABEL$MARK | bash=$SET_VOLUME param1=$VAL terminal=false refresh=true"
done

echo "-- Abrir carpeta de sonidos | bash=/usr/bin/open param1=\"$SOUNDS_DIR\" terminal=false"
echo "---"
echo "by Pablo Sanhueza Rosas | font=Menlo size=10 color=#1fae0a"
