# WindowServer Health Monitor
#
# System-level LaunchDaemon that captures WindowServer health metrics to
# JSONL every 15 seconds. Runs as root to access system-level logs and
# GPU state that user-level agents cannot see.
#
# Key metrics:
#   - Core Animation render sync timeouts (the freeze signal)
#   - WindowServer datagram buffer overflows
#   - Ping timeouts from unresponsive daemons
#   - GPU/IOAccelerator memory
#   - System memory pressure, swap, and event rates
#
# Log: /var/log/ws-monitor/ws-monitor.jsonl
# Query: grep '"severity":"FREEZE"' /var/log/ws-monitor/ws-monitor.jsonl

{ lib, pkgs, ... }:

let
  logDir = "/var/log/ws-monitor";

  monitorScript = pkgs.writeShellApplication {
    name = "ws-monitor";
    runtimeInputs = [ ];
    text = ''
      LOG_DIR="${logDir}"
      LOG_FILE="$LOG_DIR/ws-monitor.jsonl"
      mkdir -p "$LOG_DIR"
      TS=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
      LOCAL_TS=$(date '+%Y-%m-%d %H:%M:%S')

      # Rotate log at 50MB
      if [ -f "$LOG_FILE" ] && [ "$(/usr/bin/stat -f%z "$LOG_FILE" 2>/dev/null || echo 0)" -gt 52428800 ]; then
        mv "$LOG_FILE" "$LOG_FILE.$(date '+%Y%m%d%H%M%S').bak"
      fi

      # === FREEZE DETECTION ===
      SYNC_OUTPUT=$(/usr/bin/log show --last 20s --predicate 'eventMessage contains "synchronize timed out"' --style compact 2>&1 | grep -v "Filtering\|Timestamp")
      SYNC_TIMEOUTS=$(echo "$SYNC_OUTPUT" | grep -c "synchronize timed out" 2>/dev/null || echo 0)
      SYNC_SURFACES=$(echo "$SYNC_OUTPUT" | grep -oE "for [a-f0-9]+" | sort -u | sed 's/for //' | tr '\n' ',' | sed 's/,$//')
      DATAGRAM_CLEARS=$(/usr/bin/log show --last 20s --predicate 'process == "WindowServer" AND eventMessage contains "Clearing datagram buffer"' --style compact 2>&1 | grep -v "Filtering\|Timestamp" | wc -l | tr -d ' ')

      # === WINDOWSERVER HEALTH ===
      PING_OUTPUT=$(/usr/bin/log show --last 20s --predicate 'process == "WindowServer" AND eventMessage contains "ping"' --style compact 2>&1 | grep -v "Filtering\|Timestamp")
      PING_COUNT=$(echo "$PING_OUTPUT" | grep -c "failed to act" 2>/dev/null || echo 0)
      PING_PIDS=$(echo "$PING_OUTPUT" | grep -oE "pid [0-9]+" | sort -u | sed 's/pid //' | tr '\n' ',' | sed 's/,$//')
      WS_TOTAL=$(/usr/bin/log show --last 20s --predicate 'process == "WindowServer"' --style compact 2>&1 | grep -v "Filtering\|Timestamp" | wc -l | tr -d ' ')
      INVALID=$(/usr/bin/log show --last 20s --predicate 'process == "WindowServer" AND eventMessage contains "Invalid window"' --style compact 2>&1 | grep -v "Filtering\|Timestamp" | wc -l | tr -d ' ')

      # === SCREEN CAPTURE ACTIVITY ===
      SHARING=$(/usr/bin/log show --last 20s --predicate 'process == "WindowServer" AND eventMessage contains "Creating sharing"' --style compact 2>&1 | grep -v "Filtering\|Timestamp" | wc -l | tr -d ' ')

      # === GPU & COMPOSITOR ===
      GPU_IOACCELERATOR=$(vm_stat 2>/dev/null | grep "IOAccelerator" | awk '{print $NF}' | tr -d '.')
      if [ -n "$GPU_IOACCELERATOR" ]; then
        GPU_MEM="$((GPU_IOACCELERATOR * 16384 / 1048576)) MB"
      else
        GPU_MEM="unknown"
      fi

      # WindowServer footprint (root can read system process memory)
      WS_PID=$(pgrep -x WindowServer 2>/dev/null | head -1)
      if [ -n "$WS_PID" ]; then
        WS_FOOTPRINT=$(/usr/bin/footprint -p "$WS_PID" 2>/dev/null | grep "phys_footprint:" | grep -oE "[0-9]+ [A-Z]+" | head -1)
      else
        WS_FOOTPRINT="unknown"
      fi

      # === SYSTEM STATE ===
      MEM_FREE=$(memory_pressure 2>/dev/null | grep "free percentage" | grep -oE "[0-9]+%" | head -1)
      SWAP_USED=$(sysctl -n vm.swapusage 2>/dev/null | grep -oE "used = [0-9.]+" | grep -oE "[0-9.]+")
      CONN_DEBUG=$(/usr/bin/log show --last 20s --predicate 'process == "WindowServer" AND eventMessage contains "ConnectionDebug"' --style compact 2>&1 | grep -v "Filtering\|Timestamp" | wc -l | tr -d ' ')
      BRIGHTNESS=$(/usr/bin/log show --last 20s --predicate 'process == "WindowServer" AND eventMessage contains "commitBrightness"' --style compact 2>&1 | grep -v "Filtering\|Timestamp" | wc -l | tr -d ' ')

      # === SEVERITY ===
      SEVERITY="normal"
      if [ "$PING_COUNT" -gt 0 ]; then SEVERITY="degraded"; fi
      if [ "$PING_COUNT" -gt 8 ]; then SEVERITY="critical"; fi
      if [ "$WS_TOTAL" -gt 3000 ]; then SEVERITY="overloaded"; fi
      if [ "$SYNC_TIMEOUTS" -gt 0 ]; then SEVERITY="FREEZE"; fi

      # === EMIT JSONL ===
      printf '{"timestamp":"%s","local_time":"%s","severity":"%s","sync_timeouts":%s,"sync_surfaces":"%s","datagram_clears":%s,"ping_timeouts":%s,"ping_pids":"%s","ws_events_total":%s,"sharing_contexts":%s,"invalid_window":%s,"conn_debug":%s,"brightness":%s,"gpu_mem":"%s","ws_footprint":"%s","mem_free_pct":"%s","swap_used_mb":"%s"}\n' \
        "$TS" "$LOCAL_TS" "$SEVERITY" "$SYNC_TIMEOUTS" "$SYNC_SURFACES" "$DATAGRAM_CLEARS" "$PING_COUNT" "$PING_PIDS" "$WS_TOTAL" "$SHARING" "$INVALID" "$CONN_DEBUG" "$BRIGHTNESS" "$GPU_MEM" "$WS_FOOTPRINT" "$MEM_FREE" "$SWAP_USED" >> "$LOG_FILE"

      if [ "$SEVERITY" != "normal" ]; then
        echo "$LOCAL_TS [$SEVERITY] sync=$SYNC_TIMEOUTS surfaces=$SYNC_SURFACES pings=$PING_COUNT ws=$WS_TOTAL gpu=$GPU_MEM ws_fp=$WS_FOOTPRINT mem=$MEM_FREE" >&2
      fi
    '';
  };
in
{
  # System-level LaunchDaemon — runs as root, sees all system logs and process state
  launchd.daemons.ws-monitor = {
    serviceConfig = {
      Label = "com.visicore.ws-monitor";
      ProgramArguments = [ "${monitorScript}/bin/ws-monitor" ];
      StartInterval = 15;
      RunAtLoad = true;
      StandardErrorPath = "${logDir}/ws-monitor.err.log";
    };
  };
}
