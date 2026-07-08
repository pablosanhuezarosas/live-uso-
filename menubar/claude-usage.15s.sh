#!/bin/bash
# <xbar.title>Claude Usage</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Pablo Sanhueza Rosas</xbar.author>
# <xbar.desc>Costo real de la sesion de Claude Code (tokens exactos + pricing oficial) y contexto usado.</xbar.desc>
# <xbar.dependencies>bash,jq,node</xbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>

STATUSLINE_CACHE="$HOME/.claude/usage-cache.json"
FRESH_SECS=300
NOW=$(date +%s)

use_statusline=false
if [ -f "$STATUSLINE_CACHE" ]; then
  MTIME=$(stat -f "%m" "$STATUSLINE_CACHE" 2>/dev/null || echo 0)
  AGE=$((NOW - MTIME))
  if [ "$AGE" -le "$FRESH_SECS" ]; then
    use_statusline=true
  fi
fi

if [ "$use_statusline" = true ]; then
  COST=$(jq -r '.cost.total_cost_usd // 0' "$STATUSLINE_CACHE")
  CTX=$(jq -r '.context_window.used_percentage // 0' "$STATUSLINE_CACHE")
  printf "MOV \$%.2f | font=Menlo size=13 color=#39ff14\n" "$COST"
  echo "---"
  printf "CTX %d%% (real, terminal)\n" "$CTX"
  echo "---"
  echo "by Pablo Sanhueza Rosas | font=Menlo size=10 color=#ff2fd0"
  exit 0
fi

NODE_BIN=$(command -v node || echo /opt/homebrew/bin/node)
RESULT=$("$NODE_BIN" "$HOME/.claude/scripts/claude-usage.js" 2>/dev/null)

if [ -z "$RESULT" ] || echo "$RESULT" | grep -q '"error"'; then
  echo "MOV \$--.-- | font=Menlo size=13 color=#888888"
  echo "---"
  echo "Sin transcript aun"
  exit 0
fi

COST=$(echo "$RESULT" | jq -r '.cost_usd')
CTX=$(echo "$RESULT" | jq -r '.ctx_pct')
MODEL=$(echo "$RESULT" | jq -r '.model')

printf "MOV \$%.2f | font=Menlo size=13 color=#39ff14\n" "$COST"
echo "---"
printf "CTX %d%% vs ventana 1M (aprox, no igual al nativo de VSCode)\n" "$CTX"
echo "modelo: $MODEL | font=Menlo"
echo "---"
echo "by Pablo Sanhueza Rosas | font=Menlo size=10 color=#ff2fd0"
