# Plan: Optimize Nix Build GitHub Action Performance

## Context

The Nix Build GitHub Action (`.github/workflows/_nix-build.yml`) currently takes
**\~11 minutes 40 seconds** per run. For a nix-darwin configuration repo, this is
excessive. The build runs on `macos-latest` (Apple M1, 3 cores, 7GB RAM) and
includes quality checks, Home Manager build, and cache operations.

**PR reference**:
[Run 21752105111](https://github.com/JacobPEvans/nix/actions/runs/21752105111/job/62752450815?pr=551)

**Constraint**: No paid services (no Cachix, no FlakeHub). Cache must avoid slow
writes.

### Current Timing Breakdown

| Step | Duration | % |
| --- | --- | --- |
| Install Nix | 1m 8s | 10% |
| Cache Nix Store download | 1m 46s | 15% |
| Magic Nix Cache setup | 12s | 2% |
| `nix flake check` | 15s | 2% |
| **`nix build` (HM package)** | **5m 25s** | **47%** |
| Post Cache upload | **2m 37s** | **22%** |
| Other overhead | \~17s | 2% |

**Top 3 bottlenecks**: Build (47%), Cache Upload (22%), Cache Download (15%)

## Strategy 1: Eliminate Redundant `actions/cache` — Use Magic Nix Cache Only

Estimated savings: 2-4 minutes per run

The workflow uses TWO competing cache mechanisms that both use the GHA Cache API.
`actions/cache@v5` caches the entire `/nix/store` as a tarball (download: 1m 46s,
upload: 2m 37s). `DeterminateSystems/magic-nix-cache-action` is a
content-addressable binary cache also using the GHA Cache API. These **conflict**:
both compete for the 10GB GHA cache limit, and `actions/cache` always runs its
post-step upload (2m 37s) even on PRs where the intent was to skip uploads.

Remove `actions/cache@v5` entirely. Enable Magic Nix Cache on **all** runs (PRs
and main). Magic Nix Cache restores store paths lazily (on-demand during build, no
upfront bulk download), uploads **only newly built paths** (not the entire store),
and handles partial cache hits natively (content-addressable).

### Strategy 1 Changes

**File: `.github/workflows/_nix-build.yml`** — Remove the `use-gha-cache` input
parameter, delete the `Cache Nix Store` step (lines 37-48), change Magic Nix
Cache to always use GHA cache with `use-gha-cache: true`. Remove the
`use-gha-cache` parameter from callers (`ci-gate.yml` line 101, `ci-nix.yml`).

### Strategy 1 Fallback

If Magic Nix Cache's lazy restore makes the build slower than the bulk tarball
approach, fall back to using `actions/cache/restore@v5` (restore-only, no
post-step upload) on PRs, and `actions/cache/save@v5` explicitly only on main.

## Strategy 2: Move Quality Checks from macOS to Linux

Estimated savings: 15-30 seconds wall-clock + cost reduction

The macOS job runs `nix flake check --print-build-logs` (15s) **before** the HM
build. These checks (formatting, statix, deadnix, shellcheck) are cross-platform
— defined in `lib/checks.nix` for all systems including `x86_64-linux`. Running
them on the expensive macOS runner ($0.08/min) is wasteful. Additionally,
`_nix-validate.yml` already runs `nix flake check --no-build` on Linux — but the
`--no-build` flag skips actually running the linters.

Upgrade `_nix-validate.yml` to run `nix flake check` (with builds) instead of
`--no-build`. Remove `nix flake check` from `_nix-build.yml` (macOS only does
`nix build`). Since both jobs run in parallel via `ci-gate.yml`, this removes 15s
from the macOS critical path.

### Strategy 2 Changes

**File: `.github/workflows/_nix-validate.yml`** — Change
`nix flake check --no-build` to `nix flake check --print-build-logs`

**File: `.github/workflows/_nix-build.yml`** — Remove the "Nix quality checks"
step (line 57-60)

### Strategy 2 Tradeoff

The Linux validate job becomes slower (\~1-2 min for check builds), but it
already runs in parallel with macOS. macOS critical path is reduced.

## Strategy 3: Optimize Nix Daemon Settings for CI

Estimated savings: 30 seconds to 1 minute

Default Nix settings are not optimized for CI runners with specific core counts
and network characteristics. Add CI-optimized `extra-conf` to the Nix installer
step.

### Strategy 3 Changes

**File: `.github/workflows/_nix-build.yml`** — Add `extra-conf` to the Install
Nix step with these settings:

| Setting | Value | Effect |
| --- | --- | --- |
| `max-jobs` | `auto` | Build derivations in parallel (match 3 CPU cores) |
| `cores` | `0` | Each build job uses all available cores |
| `http-connections` | `50` | More parallel downloads from binary cache |
| `connect-timeout` | `5` | Fail fast on unreachable substituters |
| `stalled-download-timeout` | `10` | Don't wait long for stalled downloads |
| `narinfo-cache-positive-ttl` | `86400` | Cache positive narinfo lookups 24h |
| `fallback` | `true` | Build locally if substituter fails |

## Strategy 4: Conditional Build Depth Based on Change Type

Estimated savings: Up to 5+ minutes on certain PRs

The CI gate already skips builds for `deps-only` commits. But many other PRs
touch files under `modules/**` (matching the `nix:` filter) that don't actually
affect the Nix build output — markdown files, shell scripts in `agentsmd/`,
Claude agent/skill definitions that are just symlinked.

Add finer-grained change detection that distinguishes **nix-affecting changes**
(`.nix` files, `flake.lock`, `flake.nix` → full `nix build`) from
**content-only changes** (files that are just copied/symlinked → `nix eval` only,
verifies evaluation succeeds, skips full build).

### Strategy 4 Changes

**File: `.github/workflows/ci-gate.yml`** — Add a new `nix-build` filter
category separate from `nix-content`, then conditionally choose build depth.

### Strategy 4 Tradeoff

Evaluation-only misses build-time errors (download failures, compilation errors).
For symlinked content this is acceptable since the Nix expressions themselves have
not changed.

## Strategy 5: Nix Store Garbage Collection Before Cache Save

Estimated savings: 30 seconds to 1 minute on future cache restores

The cached `/nix/store` accumulates build-time-only dependencies (compilers,
build tools) that are not needed at runtime. This inflates cache size, slowing
both download and upload. If Strategy 1's Magic Nix Cache-only approach is not
adopted, add GC before cache save on main by running
`nix-collect-garbage --delete-older-than 1d` after the build completes but before
the cache save step.

**Note**: If Strategy 1 is adopted (Magic Nix Cache only), this is
**unnecessary** — Magic Nix Cache only caches newly built paths, not the entire
store.

## Strategy 6: Use `nix-community/cache-nix-action` as Alternative

Estimated savings: 1-2 minutes (alternative to Strategy 1)

`actions/cache@v5` always saves the full cache on any key mismatch, even if only
a few MB changed. This is the "write amplification" problem. Replace it with
`nix-community/cache-nix-action@v5`, which has built-in `gc-max-store-size`
(auto-GC before save), `save-always` (control when to save), and
`purge` + `purge-max-age` (auto-cleanup old cache entries).

### Strategy 6 Tradeoff

This is a fallback alternative to Strategy 1. Use this if Magic Nix Cache alone
does not provide sufficient caching.

## Implementation Priority

| # | Strategy | Savings | Effort | Risk |
| --- | --- | --- | --- | --- |
| 1 | Remove `actions/cache`, Magic Nix Cache only | 2-4 min | Low | Medium |
| 2 | Move checks to Linux runner | 15-30s | Low | Low |
| 3 | Tune Nix daemon settings | 30s-1m | Low | Low |
| 4 | Conditional build depth | Up to 5m | Medium | Medium |
| 5 | GC before cache save | 30s-1m | Low | Low |
| 6 | `cache-nix-action` (alt to #1) | 1-2m | Low | Low |

**Recommended order**: 1 → 2 → 3 → 4. Strategies 5 and 6 are fallbacks if
Strategy 1 does not work well.

**Best case total savings**: \~4-5 minutes per PR (from \~11m 40s to \~6-7
minutes)

## Files to Modify

- `.github/workflows/_nix-build.yml` — Remove cache step, remove
  `nix flake check`, add Nix tuning
- `.github/workflows/_nix-validate.yml` — Upgrade to full `nix flake check`
  (with builds)
- `.github/workflows/ci-gate.yml` — Refine path filters, remove `use-gha-cache`
  parameter
- `.github/workflows/ci-nix.yml` — Remove `use-gha-cache` parameter

## Verification

1. Create a PR with these changes
2. Compare Nix Build job timing against the baseline (11m 40s)
3. Verify quality checks still run and catch formatting/lint issues
4. Verify cache is populated on main push
5. Verify subsequent PR builds use cached store paths
6. Run a flake.lock update PR to test cache miss scenario
