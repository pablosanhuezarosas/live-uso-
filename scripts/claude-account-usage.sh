#!/bin/bash
# Reads Claude account-level rate limits (5h/7d) from Anthropic's undocumented
# OAuth usage endpoint, using the same token Claude Code already stores in
# the macOS Keychain. Cached with a TTL to avoid hammering the endpoint.
CACHE="$HOME/.claude/account-usage-cache.json"
TTL=60
NOW=$(date +%s)

if [ -f "$CACHE" ]; then
  MTIME=$(stat -f "%m" "$CACHE" 2>/dev/null || echo 0)
  AGE=$((NOW - MTIME))
  if [ "$AGE" -le "$TTL" ]; then
    cat "$CACHE"
    exit 0
  fi
fi

TOKEN_JSON=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
if [ -z "$TOKEN_JSON" ]; then
  [ -f "$CACHE" ] && cat "$CACHE" || echo '{"error":"no_token"}'
  exit 0
fi

ACCESS_TOKEN=$(echo "$TOKEN_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["claudeAiOauth"]["accessToken"])' 2>/dev/null)
unset TOKEN_JSON
if [ -z "$ACCESS_TOKEN" ]; then
  [ -f "$CACHE" ] && cat "$CACHE" || echo '{"error":"no_token"}'
  exit 0
fi

RESPONSE=$(curl -s --max-time 8 "https://api.anthropic.com/api/oauth/usage" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "anthropic-beta: oauth-2025-04-20" \
  -H "User-Agent: claude-code/menubar-widget" \
  -H "Content-Type: application/json")
unset ACCESS_TOKEN

if [ -n "$RESPONSE" ] && echo "$RESPONSE" | jq -e '.five_hour' >/dev/null 2>&1; then
  echo "$RESPONSE" > "$CACHE"
  echo "$RESPONSE"
else
  [ -f "$CACHE" ] && cat "$CACHE" || echo '{"error":"request_failed"}'
fi
