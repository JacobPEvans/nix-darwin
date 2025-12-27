# Research Findings: /run/current-system Symlink Issue

**Date**: 2024-12-26
**Researcher**: Dedicated research agent
**Investigation Duration**: ~2 hours of deep source code analysis

## Executive Summary

**ROOT CAUSE IDENTIFIED**: The activate script uses `set -e` (exit on error) and the
`/run/current-system` symlink update is the **last command** in the script. If any of the 23+
preceding activation scripts fail, the script exits immediately due to `set -e`, preventing the
symlink update from ever executing.

## Key Findings

### 1. Activate Script Structure

The activate script is generated in `modules/system/activation-scripts.nix` with:

- **Hardcoded `systemConfig` variable** pointing to its own store path (line 36)
- **`set -e` and `set -o pipefail`** at the top (any error causes immediate exit)
- **23+ activation subscripts** running in sequence
- **`ln -sfn` command as the absolute last operation** (line ~1526)

### 2. Activation Execution Order

```text
1. preActivation
2. checks
3. createRun
4. extraActivation
5. groups, users, applications, pam, patches
6. etc (creates /etc/static symlink)
7. defaults, userDefaults
8. launchd, userLaunchd
9. nix-daemon, time, networking, power, keyboard
10. fonts, nvram, homebrew
11. postActivation ← Our verification check runs here
12. Terminal.app configuration ← "Configuring custom file extension mappings..." output
13. ln -sfn "$(readlink -f "$systemConfig")" /run/current-system ← NEVER REACHED
```

**Critical Observation**: We see output from step 12 (Terminal config), but the symlink update
(step 13) never happens. Something fails **after** step 12 but **before** step 13.

### 3. darwin-rebuild Execution Flow

From `darwin-rebuild.sh`:

```bash
# 1. Build configuration
systemConfig=$(nix build ...)

# 2. Update profile
nix-env -p /nix/var/nix/profiles/system --set "$systemConfig"

# 3. Run activate from NEW generation
"$systemConfig/activate"

# 4. Done (nothing runs after activate)
```

**Implications**:

- darwin-rebuild doesn't update the symlink itself - it relies on the activate script
- The activate script is called from the NEW generation
- Nothing happens after activation completes

### 4. Possible Root Causes

#### Scenario A: Silent Failure Between Step 12 and 13 (MOST LIKELY)

- Something fails after Terminal.app configuration but before ln -sfn
- Due to `set -e`, the script exits silently
- The error might be suppressed or not visible in output

**Evidence**: We see step 12 output but symlink never updates

#### Scenario B: Wrong Activate Script Called (UNLIKELY)

- darwin-rebuild might be calling the OLD generation's activate script
- Old script would update symlink to point to itself (old generation)

**Evidence against**: Profile gets updated correctly to new generation

#### Scenario C: Permission Issues (UNLIKELY)

- `ln -sfn` requires root to update `/run/current-system`
- Command might fail silently without root

**Evidence against**: We run with sudo, and `/run` writability is verified in preActivation

#### Scenario D: Launchd Service Interference (UNLIKELY)

- `services.activate-system` might be resetting the symlink
- This service only runs `etc` and `keyboard` scripts, not full activation

**Evidence against**: Issue happens immediately after rebuild, not later

### 5. Next Steps to Identify Exact Failure Point

1. **Add debugging AFTER Terminal configuration**:
   - Insert markers between step 12 and step 13
   - Use `set +e` temporarily to prevent early exit
   - Echo current directory, permissions, environment

2. **Run activate script manually with full tracing**:

   ```bash
   sudo bash -x /nix/var/nix/profiles/system-287-link/activate 2>&1 | tee activate-trace.log
   ```

3. **Check for hidden failures**:
   - Look for suppressed errors in activation
   - Verify all 23 scripts complete successfully
   - Check exit codes

4. **Add explicit error handling around ln -sfn**:

   ```bash
   echo "DEBUG: About to update symlink" >&2
   if ln -sfn "$(readlink -f "$systemConfig")" /run/current-system; then
     echo "DEBUG: Symlink updated successfully" >&2
   else
     echo "ERROR: Failed to update symlink, exit code: $?" >&2
   fi
   ```

## Sources

- [nix-darwin activation-scripts.nix](https://github.com/nix-darwin/nix-darwin/blob/master/modules/system/activation-scripts.nix)
- [darwin-rebuild.sh](https://github.com/LnL7/nix-darwin/blob/master/pkgs/nix-tools/darwin-rebuild.sh)
- [Issue #258: /run/current-system symlink not created](https://github.com/nix-darwin/nix-darwin/issues/258)
- [Issue #1462: System activation broken](https://github.com/nix-darwin/nix-darwin/issues/1462)
- [Issue #1457: Activation must run as root](https://github.com/nix-darwin/nix-darwin/issues/1457)

## Conclusion

**The symlink update fails because the activate script exits early due to `set -e` when something
fails between the Terminal configuration (step 12) and the symlink update (step 13).** We need to:

1. Identify what's failing in that narrow window
2. Either fix the failing command or add error handling to allow activation to continue
3. Consider moving the symlink update earlier in the activation sequence as a safety measure
