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
echo "by Pablo Sanhueza Rosas | font=Menlo size=10 color=#1fae0a"
