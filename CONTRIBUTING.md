# Contributing

Thanks for considering contributing. It's just me here, so any help is genuinely appreciated.

## The Short Version

1. Fork it
2. Create your feature branch (`git checkout -b feature/cool-thing`)
3. Commit your changes (GPG-signed - see below)
4. Push to the branch (`git push origin feature/cool-thing`)
5. Open a Pull Request

That's it. I'm not picky.

## Organization-Wide Standards

For standards that apply across all JacobPEvans projects, see the
[Organization Contributing Guide](https://github.com/JacobPEvans/.github/blob/main/docs/CONTRIBUTING.md),
which covers:

- **Commit Signing** – All commits must be GPG-signed. The org guide has setup instructions.
- **PR Standards** – Use conventional commit format (`type(scope): description`) and apply type/priority/size labels.
- **Issue Linking** – Connect related issues with "Closes #123" or "Related to #123" in PR descriptions.
- **General Acceptance Criteria** – Improvements to documentation, bug fixes, and code maintainability are welcome.

## Reporting Issues

Found a bug? Something unclear? Open an issue. Describe what you expected, what happened instead, and any relevant context.

## Repository-Specific Guidelines

### Before You Start

- Check if there's already an issue or PR for what you're planning
- For big changes, maybe open an issue first to discuss

### Code Style

**Markdown:** Linted by `markdownlint-cli2` (runs automatically during pre-commit).

**Nix Code:** Follow existing patterns. Comments are encouraged - this config is meant to be
educational. Comments help contributors understand the `nix-darwin` ecosystem.

See [docs/PRECOMMIT.md](docs/PRECOMMIT.md) for all automated checks that run on commit.

### What Might Not Get Accepted

- Removing comments (they're there for learning)
- Changes that make the config significantly more complex without clear benefit

## Development Setup

### Prerequisites

This repository requires:

1. **Nix** (latest, via Determinate installer recommended)
2. **Git** (for committing and pushing)
3. **macOS** (nix-darwin is macOS-specific)

### Initial Setup

```bash
# 1. Clone the repo
git clone <repo-url>
cd nix-config

# 2. Install pre-commit hooks (automatic on rebuild)
pre-commit install

# 3. Make changes to Nix files
# Edit files in modules/, hosts/, etc.

# 4. Test your changes locally
nix flake check

# 5. Commit (hooks run automatically)
git add .
git commit -m "Your change description"

# 6. Push to GitHub
git push origin your-branch
```

### Running Pre-commit Hooks

Before pushing, ensure all checks pass:

```bash
# Run all automatic checks
pre-commit run --all-files

# Run content quality checks (slower, manual stage)
pre-commit run --hook-stage manual

# Both passed? Safe to push
git push
```

For detailed pre-commit documentation, see [docs/PRECOMMIT.md](docs/PRECOMMIT.md), which explains:

- What each tool group does
- How to run hooks manually
- How to troubleshoot common issues
- Tool reference and documentation

### Rebuilding System Configuration

After your changes are committed:

```bash
# Rebuild system with your changes
sudo darwin-rebuild switch --flake ~/.config/nix

# Rollback if something breaks
sudo darwin-rebuild rollback
```

See [RUNBOOK.md](RUNBOOK.md) for more operational procedures.

## Questions?

Open an issue. I'll respond when I can.

---

*Thanks for reading this far. Most people don't.*
