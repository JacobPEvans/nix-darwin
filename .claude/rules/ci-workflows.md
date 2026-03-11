# CI Workflow Rules

## Nix Caching in GitHub Actions

- **NEVER use `DeterminateSystems/flakehub-cache-action`** — it is a PAID service. We cannot afford it.
- **NEVER use raw `actions/cache` to tar `/nix/store`** — causes tar extraction errors due to special permissions/hardlinks.
- **ALWAYS use a versioned `DeterminateSystems/magic-nix-cache-action@vX`** for Nix store caching — free, zero-config, uses GitHub Actions built-in cache.
- `magic-nix-cache-action` requires `id-token: write` permission. This should be scoped to individual jobs, not the entire workflow.

## Performance Requirements

- **ALWAYS include timing steps** before and after build/check steps to measure CI performance.
- Cache changes MUST NOT increase CI runtime. Any regression defeats the purpose of caching.
- Compare timing output in CI logs before and after cache changes to verify no regression.
