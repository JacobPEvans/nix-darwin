# GitHub Actions Workflows

CI/CD workflows for this nix-darwin configuration repository.

## Active Workflows

### Claude Code Review (`claude.yml`)

Automated PR review using [anthropics/claude-code-action](https://github.com/anthropics/claude-code-action).

**Triggers**: Pull requests (opened, synchronize)

**Features**:

- AI-powered code review using Claude
- Runs the `/review-code` command
- Posts review comments on PRs

**Setup**: Add `ANTHROPIC_API_KEY` to repository secrets.

### Nix CI (`nix-ci.yml`)

Validates Nix flake configuration using Determinate Systems actions.

**Triggers**: Push/PR on `*.nix` or `flake.lock` changes

**Features**:

- Installs Nix via [DeterminateSystems/nix-installer-action](https://github.com/DeterminateSystems/nix-installer-action)
- Free caching via [DeterminateSystems/magic-nix-cache-action](https://github.com/DeterminateSystems/magic-nix-cache-action)
- Checks flake.lock health via [DeterminateSystems/flake-checker-action](https://github.com/DeterminateSystems/flake-checker-action)
- Runs `nix flake check` validation

### Markdown Lint (`markdownlint.yml`)

Validates markdown file formatting.

**Triggers**: Push/PR on `*.md` or `.markdownlint.*` changes

**Features**:

- Uses [DavidAnson/markdownlint-cli2-action](https://github.com/DavidAnson/markdownlint-cli2-action)
- Enforces consistent markdown style
- Configuration in `.markdownlint.json`

## Configuration

### Required Secrets

| Secret | Description | Required By |
|--------|-------------|-------------|
| `ANTHROPIC_API_KEY` | Anthropic API key for Claude | `claude.yml` |

### Permissions

Workflows use minimal required permissions:

- `contents: read` - Read repository code
- `pull-requests: write` - Post review comments (Claude only)
- `id-token: write` - Determinate Systems authentication

## Related Documentation

- [Claude Code Action](https://github.com/anthropics/claude-code-action)
- [Determinate Systems Actions](https://github.com/DeterminateSystems)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
