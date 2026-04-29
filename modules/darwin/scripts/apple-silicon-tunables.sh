#!/usr/bin/env bash
#
# Apple Silicon System Tunables — runtime apply
#
# Reads tunables from environment variables passed by the nix-darwin
# activation script. Each step is best-effort: a failure logs a warning
# but does not abort the rest. Native macOS CLIs only — no third-party
# dependencies.

set -uo pipefail

prefix="[apple-silicon-tunables]"
log() { echo "$prefix INFO $*"; }
warn() { echo "$prefix WARN $*" >&2; }

# 1. Wired-memory ceiling for IOGPU.
if /usr/sbin/sysctl -w "iogpu.wired_limit_mb=${WIRED_LIMIT_MB}" >/dev/null; then
    log "iogpu.wired_limit_mb=${WIRED_LIMIT_MB}"
else
    warn "sysctl iogpu.wired_limit_mb failed"
fi

# 2. Low Power Mode off on every power source. Inference workloads stall
#    badly when LPM throttles the SoC.
if /usr/bin/pmset -a lowpowermode 0 >/dev/null 2>&1; then
    log "lowpowermode=0 on all power sources"
else
    warn "pmset -a lowpowermode 0 failed"
fi

# 3. Spotlight indexing off on the HuggingFace volume — every model
#    download otherwise re-indexes hundreds of GB.
if [ -d "${HF_VOLUME}" ]; then
    if /usr/bin/mdutil -i off "${HF_VOLUME}" >/dev/null 2>&1; then
        log "mdutil indexing disabled on ${HF_VOLUME}"
    else
        warn "mdutil -i off ${HF_VOLUME} failed"
    fi
else
    warn "HF volume ${HF_VOLUME} is missing or not mounted; skipping mdutil -i off"
fi

# 4. Time Machine excludes for the AI cache directories. TM_EXCLUDES is a
#    colon-separated list of absolute paths.
if [ -n "${TM_EXCLUDES:-}" ]; then
    IFS=':' read -ra _excludes <<<"${TM_EXCLUDES}"
    for _path in "${_excludes[@]}"; do
        if [ -e "${_path}" ]; then
            if /usr/bin/tmutil addexclusion "${_path}" >/dev/null 2>&1; then
                log "tmutil exclude ${_path}"
            else
                warn "tmutil addexclusion ${_path} failed"
            fi
        else
            warn "tmutil exclusion skipped for missing path ${_path}; rerun activation after it is created"
        fi
    done
fi

# 5. App Nap off for inference daemons. Bundle IDs come in colon-separated.
#    Defaults are per-user, so we shell out as the configured user.
if [ -n "${APPNAP_BUNDLES:-}" ] && [ -n "${USER_NAME:-}" ]; then
    IFS=':' read -ra _bundles <<<"${APPNAP_BUNDLES}"
    for _bundle in "${_bundles[@]}"; do
        if /usr/bin/sudo -u "${USER_NAME}" /usr/bin/defaults write \
            "${_bundle}" NSAppSleepDisabled -bool YES >/dev/null 2>&1; then
            log "NSAppSleepDisabled=YES for ${_bundle}"
        else
            warn "defaults write ${_bundle} NSAppSleepDisabled failed"
        fi
    done
fi

exit 0
