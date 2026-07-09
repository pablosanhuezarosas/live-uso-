#!/bin/bash
# <xbar.title>Claude Rate Limits</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Pablo Sanhueza Rosas</xbar.author>
# <xbar.desc>Uso real de cuenta (ventana de 5h y 7d) via el endpoint OAuth de Anthropic. Alerta con sonido en 20/50/75/90/95%.</xbar.desc>
# <xbar.dependencies>bash,jq,python3,curl</xbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>

RESULT=$(bash "$HOME/.claude/scripts/claude-account-usage.sh" 2>/dev/null)

if [ -z "$RESULT" ] || echo "$RESULT" | grep -q '"error"'; then
  echo "5H[----------]--% | font=Menlo size=13 color=#888888"
  echo "---"
  echo "◢◤ CLAUDE.SYS :: LINK DOWN ◢◤ | font=Menlo size=12 color=#ff2fd0"
  echo "sin datos de cuenta aun"
  exit 0
fi

make_bar() {
  local pct=$1
  local filled=$(( pct / 10 ))
  (( filled > 10 )) && filled=10
  (( filled < 0 )) && filled=0
  local empty=$(( 10 - filled ))
  local bar=""
  for ((i = 0; i < filled; i++)); do bar+="▓"; done
  for ((i = 0; i < empty; i++)); do bar+="░"; done
  echo "$bar"
}

sev_color() {
  case "$1" in
    critical) echo "#ff3b30" ;;
    warning)  echo "#8aff5c" ;;
    *)        echo "#39ff14" ;;
  esac
}

local_reset() {
  # ISO 8601 UTC timestamp -> "Dow DD Mzo · HH:MM hs" in the Mac's local timezone
  python3 -c "
import sys
from datetime import datetime
iso = sys.argv[1]
if not iso:
    print('--')
    raise SystemExit
dt = datetime.fromisoformat(iso).astimezone()
dias = ['Lun','Mar','Mie','Jue','Vie','Sab','Dom']
meses = ['Ene','Feb','Mzo','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic']
print(f'{dias[dt.weekday()]} {dt.day:02d} {meses[dt.month-1]} · {dt.hour:02d}:{dt.minute:02d} hs')
" "$1" 2>/dev/null
}

FIVE_PCT=$(echo "$RESULT" | jq -r '.limits[]? | select(.kind=="session") | .percent // 0')
SEVEN_PCT=$(echo "$RESULT" | jq -r '.limits[]? | select(.kind=="weekly_all") | .percent // 0')
FIVE_SEV=$(echo "$RESULT" | jq -r '.limits[]? | select(.kind=="session") | .severity // "normal"')
SEVEN_SEV=$(echo "$RESULT" | jq -r '.limits[]? | select(.kind=="weekly_all") | .severity // "normal"')
FIVE_RESET=$(echo "$RESULT" | jq -r '.five_hour.resets_at // empty')
SEVEN_RESET=$(echo "$RESULT" | jq -r '.seven_day.resets_at // empty')

FIVE_PCT=${FIVE_PCT:-0}
SEVEN_PCT=${SEVEN_PCT:-0}

ALERT_STATE="$HOME/.claude/account-alert-state.json"
ALERT_SOUND="$HOME/.claude/sounds/account-alert.mp3"

check_alerts() {
  local pct=$1
  local reset_key=$2
  local prev_reset="" alerted="[]" new_alerted

  if [ -f "$ALERT_STATE" ]; then
    prev_reset=$(jq -r '.resets_at // empty' "$ALERT_STATE" 2>/dev/null)
    alerted=$(jq -c '.alerted // []' "$ALERT_STATE" 2>/dev/null)
  fi
  [ "$prev_reset" != "$reset_key" ] && alerted="[]"
  new_alerted="$alerted"

  local vol
  vol=$(cat "$HOME/.claude/account-alert-volume.txt" 2>/dev/null || echo 1.0)

  for threshold in 20 50 75 90 95; do
    already=$(echo "$alerted" | jq --argjson t "$threshold" 'index($t) != null')
    if [ "$pct" -ge "$threshold" ] && [ "$already" != "true" ]; then
      if [ "$threshold" -eq 95 ]; then
        ( afplay -v "$vol" "$ALERT_SOUND"; sleep 0.4; afplay -v "$vol" "$ALERT_SOUND" ) &
      else
        ( afplay -v "$vol" "$ALERT_SOUND" ) &
      fi
      new_alerted=$(echo "$new_alerted" | jq --argjson t "$threshold" '. + [$t]')
    fi
  done

  jq -n --arg r "$reset_key" --argjson a "$new_alerted" '{resets_at: $r, alerted: $a}' > "$ALERT_STATE"
}

check_alerts "$FIVE_PCT" "$FIVE_RESET"

FIVE_BAR=$(make_bar "$FIVE_PCT")
FIVE_COLOR=$(sev_color "$FIVE_SEV")
SEVEN_BAR=$(make_bar "$SEVEN_PCT")
SEVEN_COLOR=$(sev_color "$SEVEN_SEV")
FIVE_RESET_LOCAL=$(local_reset "$FIVE_RESET")
SEVEN_RESET_LOCAL=$(local_reset "$SEVEN_RESET")

printf "5H[%s]%d%% | font=Menlo size=13 color=%s\n" "$FIVE_BAR" "$FIVE_PCT" "$FIVE_COLOR"
echo "---"
echo "▓▓▓ CLAUDE.SYS // RATE-LIMIT MONITOR ▓▓▓ | font=Menlo size=11 color=#39ff14"
echo "──────────────────────────────"
echo ">> SESSION_5H | font=Menlo size=12 color=#1fae0a"
printf "   [%s] %d%% | font=Menlo size=13 color=%s\n" "$FIVE_BAR" "$FIVE_PCT" "$FIVE_COLOR"
printf "   RESET >> %s | font=Menlo size=12 color=#39ff14\n" "$FIVE_RESET_LOCAL"
echo "──────────────────────────────"
echo ">> WEEKLY_7D | font=Menlo size=12 color=#1fae0a"
printf "   [%s] %d%% | font=Menlo size=13 color=%s\n" "$SEVEN_BAR" "$SEVEN_PCT" "$SEVEN_COLOR"
printf "   RESET >> %s | font=Menlo size=12 color=#39ff14\n" "$SEVEN_RESET_LOCAL"
echo "──────────────────────────────"
echo ":: fuente no oficial :: api.anthropic.com/oauth/usage | font=Menlo size=10 color=#2d6e1e"
echo "---"
echo "▓ SETTINGS ▓ | font=Menlo size=11 color=#1fae0a"

SOUNDS_DIR="$HOME/.claude/sounds"
SET_ACCOUNT_SOUND="$HOME/.claude/scripts/set-account-sound.sh"
SOUND_STATE="$HOME/.claude/sound-settings.json"

CURRENT_SOUND=$(jq -r '.account_alert // "?"' "$SOUND_STATE" 2>/dev/null)
echo "-- Sonido de alerta (actual: $CURRENT_SOUND) | font=Menlo size=11"
for f in "$SOUNDS_DIR"/*.mp3; do
  [ -e "$f" ] || continue
  NAME=$(basename "$f")
  MARK=""
  [ "$NAME" = "$CURRENT_SOUND" ] && MARK=" ✓"
  echo "---- $NAME$MARK | bash=$SET_ACCOUNT_SOUND param1=\"$f\" terminal=false refresh=true"
done

SET_ACCOUNT_VOLUME="$HOME/.claude/scripts/set-account-volume.sh"
CURRENT_VOL=$(cat "$HOME/.claude/account-alert-volume.txt" 2>/dev/null || echo "1.0")
echo "-- Volumen de alerta (actual: ${CURRENT_VOL}) | font=Menlo size=11"
for LEVEL in "10%:0.1" "20%:0.2" "30%:0.3" "40%:0.4" "50%:0.5" "60%:0.6" "70%:0.7" "80%:0.8" "90%:0.9" "100%:1.0"; do
  LABEL="${LEVEL%%:*}"
  VAL="${LEVEL##*:}"
  MARK=""
  [ "$VAL" = "$CURRENT_VOL" ] && MARK=" ✓"
  echo "---- $LABEL$MARK | bash=$SET_ACCOUNT_VOLUME param1=$VAL terminal=false refresh=true"
done

echo "---"
echo "by Pablo Sanhueza Rosas | font=Menlo size=10 color=#1fae0a"
