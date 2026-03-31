#!/bin/bash
# WindowServer Performance Monitor
#
# Captures WindowServer health metrics to JSONL every 15 seconds.
# Runs as a system LaunchDaemon (root) for full visibility into
# compositor state, GPU memory, and system-level logs.
#
# All system commands use absolute paths since writeShellApplication
# only adds jq to PATH.
#
# Log: /var/log/ws-monitor/ws-monitor.jsonl
# Query: jq 'select(.severity != "normal")' /var/log/ws-monitor/ws-monitor.jsonl
set -euo pipefail

LOG_DIR="/var/log/ws-monitor"
LOG_FILE="$LOG_DIR/ws-monitor.jsonl"
/bin/mkdir -p "$LOG_DIR"
TS=$(/bin/date -u '+%Y-%m-%dT%H:%M:%SZ')
LOCAL_TS=$(/bin/date '+%Y-%m-%d %H:%M:%S')

# Rotate log at 50MB
if [ -f "$LOG_FILE" ] && [ "$(/usr/bin/stat -f%z "$LOG_FILE" 2>/dev/null || echo 0)" -gt 52428800 ]; then
  /bin/mv "$LOG_FILE" "$LOG_FILE.$(/bin/date '+%Y%m%d%H%M%S').bak"
fi

# Single log show call — extract all WindowServer events once (16s window for 15s interval)
WS_LOG=$(/usr/bin/log show --last 16s --predicate 'process == "WindowServer"' --style compact 2>&1 | /usr/bin/grep -v "Filtering\|Timestamp" || true)

# Single log show call for sync timeouts (separate predicate for non-WS processes)
SYNC_LOG=$(/usr/bin/log show --last 16s --predicate 'eventMessage contains "synchronize timed out"' --style compact 2>&1 | /usr/bin/grep -v "Filtering\|Timestamp" || true)

# === FREEZE DETECTION ===
SYNC_TIMEOUTS=$(echo "$SYNC_LOG" | /usr/bin/grep -c "synchronize timed out" || echo 0)
SYNC_SURFACES=$(echo "$SYNC_LOG" | /usr/bin/grep -oE "for [a-f0-9]+" | /usr/bin/sort -u | /usr/bin/sed 's/for //' | /usr/bin/tr '\n' ',' | /usr/bin/sed 's/,$//' || true)
DATAGRAM_CLEARS=$(echo "$WS_LOG" | /usr/bin/grep -c "Clearing datagram buffer" || echo 0)

# === WINDOWSERVER HEALTH ===
PING_COUNT=$(echo "$WS_LOG" | /usr/bin/grep -c "failed to act" || echo 0)
PING_PIDS=$(echo "$WS_LOG" | /usr/bin/grep "failed to act" | /usr/bin/grep -oE "pid [0-9]+" | /usr/bin/sort -u | /usr/bin/sed 's/pid //' | /usr/bin/tr '\n' ',' | /usr/bin/sed 's/,$//' || true)
WS_TOTAL=$(echo "$WS_LOG" | /usr/bin/wc -l | /usr/bin/tr -d ' ')
INVALID=$(echo "$WS_LOG" | /usr/bin/grep -c "Invalid window" || echo 0)

# === SCREEN CAPTURE ACTIVITY ===
SHARING=$(echo "$WS_LOG" | /usr/bin/grep -c "Creating sharing" || echo 0)

# === GPU & COMPOSITOR ===
PAGE_SIZE=$(/usr/sbin/sysctl -n hw.pagesize 2>/dev/null || echo 16384)
GPU_PAGES=$(/usr/bin/vm_stat 2>/dev/null | /usr/bin/grep "IOAccelerator" | /usr/bin/awk '{print $NF}' | /usr/bin/tr -d '.' || true)
if [ -n "$GPU_PAGES" ]; then
  GPU_MEM="$((GPU_PAGES * PAGE_SIZE / 1048576)) MB"
else
  GPU_MEM="unknown"
fi

# WindowServer footprint (root can read system process memory)
WS_PID=$(/usr/bin/pgrep -x WindowServer 2>/dev/null | /usr/bin/head -1 || true)
if [ -n "$WS_PID" ]; then
  WS_FOOTPRINT=$(/usr/bin/footprint -p "$WS_PID" 2>/dev/null | /usr/bin/grep "phys_footprint:" | /usr/bin/grep -oE "[0-9]+ [A-Z]+" | /usr/bin/head -1 || echo "unknown")
else
  WS_FOOTPRINT="unknown"
fi

# === SYSTEM STATE ===
MEM_FREE=$(/usr/bin/memory_pressure 2>/dev/null | /usr/bin/grep "free percentage" | /usr/bin/grep -oE "[0-9]+%" | /usr/bin/head -1 || echo "unknown")
SWAP_USED=$(/usr/sbin/sysctl -n vm.swapusage 2>/dev/null | /usr/bin/grep -oE "used = [0-9.]+" | /usr/bin/grep -oE "[0-9.]+" || echo "0")
CONN_DEBUG=$(echo "$WS_LOG" | /usr/bin/grep -c "ConnectionDebug" || echo 0)
BRIGHTNESS=$(echo "$WS_LOG" | /usr/bin/grep -c "commitBrightness" || echo 0)

# === SEVERITY ===
SEVERITY="normal"
if [ "$PING_COUNT" -gt 0 ]; then SEVERITY="degraded"; fi
if [ "$PING_COUNT" -gt 8 ]; then SEVERITY="critical"; fi
if [ "$WS_TOTAL" -gt 3000 ]; then SEVERITY="overloaded"; fi
if [ "$SYNC_TIMEOUTS" -gt 0 ]; then SEVERITY="FREEZE"; fi

# === EMIT JSONL (safe via jq) ===
jq -nc \
  --arg ts "$TS" \
  --arg lt "$LOCAL_TS" \
  --arg sev "$SEVERITY" \
  --argjson sync "$SYNC_TIMEOUTS" \
  --arg surf "$SYNC_SURFACES" \
  --argjson dgram "$DATAGRAM_CLEARS" \
  --argjson pings "$PING_COUNT" \
  --arg ppids "$PING_PIDS" \
  --argjson ws "$WS_TOTAL" \
  --argjson share "$SHARING" \
  --argjson inv "$INVALID" \
  --argjson conn "$CONN_DEBUG" \
  --argjson bright "$BRIGHTNESS" \
  --arg gpu "$GPU_MEM" \
  --arg wsfp "$WS_FOOTPRINT" \
  --arg mem "$MEM_FREE" \
  --arg swap "$SWAP_USED" \
  '{timestamp:$ts,local_time:$lt,severity:$sev,sync_timeouts:$sync,sync_surfaces:$surf,datagram_clears:$dgram,ping_timeouts:$pings,ping_pids:$ppids,ws_events_total:$ws,sharing_contexts:$share,invalid_window:$inv,conn_debug:$conn,brightness:$bright,gpu_mem:$gpu,ws_footprint:$wsfp,mem_free_pct:$mem,swap_used_mb:$swap}' \
  >> "$LOG_FILE"

if [ "$SEVERITY" != "normal" ]; then
  echo "$LOCAL_TS [$SEVERITY] sync=$SYNC_TIMEOUTS surfaces=$SYNC_SURFACES pings=$PING_COUNT ws=$WS_TOTAL gpu=$GPU_MEM ws_fp=$WS_FOOTPRINT mem=$MEM_FREE" >&2
fi
