# Critical Rules for Darwin Activation Scripts

**Status**: ENFORCED - All activation scripts MUST follow these rules without exception.

## Why These Rules Exist

nix-darwin's `activate` script uses `set -e` (exit on any error). Without proper
handling, any command returning a non-zero exit code causes the entire script to
abort **BEFORE** `/run/current-system` is updated.

**Result**: Silent partial deployments where:

- Home-manager activates successfully
- System outputs "activation succeeded"
- But `/run/current-system` symlink never updates
- User's system stays on old generation

This is worse than failing loudly - it's a silent failure that looks like success.

## Rule 1: NEVER USE 'set -e'

**Inherited from nix-darwin**: The activate script uses `set -e`, which means any command returning non-zero immediately terminates.

**Problem**:

- Commands can return non-zero on success (e.g., `launchctl asuser` returns 2)
- Even warnings cause script termination
- Symlink update never happens

**Solution**:

- Add `set +e` at the start of `preActivation`
- This disables the inherited `set -e` behavior
- Non-zero exit codes are ignored

**Example**:

```bash
preActivation.text = ''
  set +e  # CRITICAL: Disable inherited 'set -e'
  # Now non-zero exits don't abort the script
  some-command-that-returns-2
  echo "Continued despite exit code 2" >&2
''
```

## Rule 2: NEVER Use Early-Exit Constructs

**Forbidden patterns**:

- ❌ `|| exit 1` - Will abort the entire script
- ❌ `set -e` or `set -o pipefail` - Will abort on errors
- ❌ Unhandled command failures - Will be caught by inherited `set -e`
- ❌ `exit 1` statements (except in trap handlers or preflight checks for fatal preconditions)

**Note on preflight checks**: Fatal precondition checks (like verifying `/run` is writable) that occur **before** any activation work begins are
allowed to use `exit 1`. These must check conditions that would make the entire activation impossible, not just individual phase failures.

**Allowed patterns**:

- ✅ `if ... then ... else warn ... fi` - Continues on failure
- ✅ `|| true` - Ignores exit codes
- ✅ `|| echo "warning"` - Logs warning and continues
- ✅ `&& echo "success"` - Only logs if succeeds

## Rule 3: TREAT ALL ERRORS AS WARNINGS

**Philosophy**: Partial deployment is better than no deployment.

**What this means**:

- If a phase fails, log it with `[WARN]` or `[ERROR]` but **CONTINUE**
- Don't try to fix or rollback - just warn the user
- The symlink update is the CRITICAL phase - it must never be skipped

**Example**:

```bash
if duti-command-fails; then
  echo "Warning: File mappings failed (not critical)" >&2
fi
# Continue to next phase regardless
```

## Rule 4: SYMLINK UPDATE IS CRITICAL

The `/run/current-system` symlink update is the final command in the activate script. This makes the entire rebuild effective.

**Never allow anything to prevent this**:

- Don't use `set -e` before it
- Don't use `|| exit` in any earlier phase
- All errors in earlier phases must be non-fatal

## Rule 5: DOCUMENT THE WHY

Future maintainers must understand why we can't use standard error handling.

**Always include comments**:

- Why we use `if/then/else` instead of `|| exit`
- Reference to this document
- Explanation of the symlink criticality

**Example**:

```bash
# NOTE: Using 'if ... then ... else' instead of '|| exit'
# because we follow CRITICAL RULES in docs/ACTIVATION-SCRIPTS-RULES.md:
#   * Never use constructs that exit early (set -e, || exit, etc.)
#   * Treat all errors as warnings, not fatal failures
#   * Must reach /run/current-system symlink update (the critical phase)
if some-command; then
  echo "Success" >&2
else
  echo "Warning: Failed but continuing" >&2
fi
```

## Common Patterns

### Pattern: Conditional with Fallback

```bash
if /usr/libexec/PlistBuddy -c "Set key value" "$PLIST" 2>/dev/null; then
  echo "Success" >&2
elif /usr/libexec/PlistBuddy -c "Add key value" "$PLIST" 2>/dev/null; then
  echo "Created and set" >&2
else
  echo "Warning: Failed to set key (non-critical)" >&2
fi
# Continues regardless of outcome
```

### Pattern: Ignore Failure

```bash
# This will continue even if killall fails
/usr/bin/killall Finder 2>/dev/null || true
```

### Pattern: Warning on Failure

```bash
if command-that-might-fail; then
  echo "Success: X happened" >&2
else
  echo "Warning: X failed but continuing (not critical)" >&2
fi
```

### Pattern: Critical Error (Only for Signals)

```bash
cleanup() {
  echo "Error: Interrupted" >&2
  exit 1  # OK to exit here - in a trap handler for critical failure
}
trap cleanup INT TERM
```

## History

- **PR #307**: Added diagnostic infrastructure that revealed exit code 2 issue
- **PR #306**: Removed premature verification checks that gave false warnings
- **PR #298**: Fixed lsregister error handling (PR #299 reference)
- **This PR**: Implemented `set +e` bypass and documented critical rules

## See Also

- `docs/ACTIVATION-EXIT-CODES.md` - Exit code meanings and diagnostics
- `modules/darwin/common.nix` - Where `set +e` is implemented
- `modules/darwin/activation-error-tracking.nix` - Phase tracking system
