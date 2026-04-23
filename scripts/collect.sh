#!/bin/bash
# storage-health-check collector
# Outputs structured probes for Claude to parse. Read-only. Completes in under 30 seconds on a typical Mac.

set -u

# --- Free space (instant) ---
df_line=$(df -k / | tail -1)
free_kb=$(awk '{print $4}' <<< "$df_line")
total_kb=$(awk '{print $2}' <<< "$df_line")
used_pct=$(awk '{print $5}' <<< "$df_line" | tr -d '%')
printf "FREE_GB=%.1f\n" "$(bc -l <<< "$free_kb / 1024 / 1024")"
printf "TOTAL_GB=%.0f\n" "$(bc -l <<< "$total_kb / 1024 / 1024")"
echo "USED_PCT=$used_pct"

# --- Trash ---
if [ -d "$HOME/.Trash" ]; then
    trash_kb=$(du -sk "$HOME/.Trash" 2>/dev/null | awk '{print $1}')
    trash_kb=${trash_kb:-0}
else
    trash_kb=0
fi
printf "TRASH_GB=%.2f\n" "$(bc -l <<< "$trash_kb / 1024 / 1024")"

# --- Claude Code CLI processes ---
# Matches "claude-code" in the process path — the Claude Code CLI binary.
# Deliberately does NOT match Claude.app or its MCP extension helpers (those
# live under /Applications/Claude.app/ or .../Claude Extensions/).
claude_procs=$(ps aux | grep "claude-code" | grep -v grep | wc -l | tr -d ' ')
echo "CLAUDE_PROCS=$claude_procs"

# --- Top Caches folders ---
echo "TOP_CACHES_BEGIN"
du -sk "$HOME/Library/Caches"/* 2>/dev/null | sort -rn | head -10 | while read -r kb path; do
    gb=$(bc -l <<< "scale=2; $kb / 1024 / 1024")
    name=$(basename "$path")
    printf "%s|%s|%s\n" "$gb" "$name" "$path"
done
echo "TOP_CACHES_END"

# --- Top Application Support folders ---
echo "TOP_APPSUPPORT_BEGIN"
du -sk "$HOME/Library/Application Support"/* 2>/dev/null | sort -rn | head -10 | while read -r kb path; do
    gb=$(bc -l <<< "scale=2; $kb / 1024 / 1024")
    name=$(basename "$path")
    printf "%s|%s|%s\n" "$gb" "$name" "$path"
done
echo "TOP_APPSUPPORT_END"

echo "DONE"
