# CI Workflow Rules

## Nix Caching in GitHub Actions

- **ALWAYS use `nix-community/cache-nix-action@v7`** for Nix store caching — Nix-aware,
  free, uses `actions/cache` backend. Configure with `save: false` on PRs (restore-only)
  and `save: true` on main (upload acceptable there). Use `gc-max-store-size` to keep caches lean.
- **NEVER use `DeterminateSystems/magic-nix-cache-action`** — uploads the full store on every
  run with no restore-only mode, causing a 2.5x CI wall-time regression (9-11min → 24-26min).
  Also relies on reverse-engineered undocumented GitHub APIs (broke Feb 2025, could break again).
- **NEVER use `DeterminateSystems/flakehub-cache-action`** — PAID service.
- **NEVER use raw `actions/cache` to tar `/nix/store`** — causes tar extraction errors
  due to special permissions/hardlinks.
- **ALWAYS set `auto-optimise-store = false`** in Nix CI config to prevent hardlink creation
  that breaks tar-based caching (nix-community/cache-nix-action#170).
- `cache-nix-action` does NOT require `id-token: write` — uses `github.token` only.

## Performance Requirements

- **ALWAYS include timing steps** before and after build/check steps to measure CI performance.
- Cache changes MUST NOT increase CI runtime. Any regression defeats the purpose of caching.
- Compare timing output in CI logs before and after cache changes to verify no regression.
- PR runs should be **restore-only** (no upload). Cache saving happens only on main pushes.
