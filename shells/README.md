# Development Shell Templates

Per-project development environments using Nix flakes with direnv integration.

## Quick Start

1. Copy desired flake to your project:
   ```bash
   cp ~/.config/nix/shells/python/flake.nix ~/myproject/
   ```

2. Create `.envrc` in your project:
   ```bash
   echo "use flake" > ~/myproject/.envrc
   ```

3. Allow direnv:
   ```bash
   cd ~/myproject && direnv allow
   ```

The environment will now load automatically when you `cd` into the project.

## Available Templates

| Template | Description | Key Packages |
|----------|-------------|--------------|
| `python/` | Basic Python development | Python, pip, venv |
| `python-data/` | Data science / ML | Python, pandas, numpy, jupyter |
| `js/` | Node.js development | Node.js, npm, yarn, pnpm |
| `go/` | Go development | Go, gopls, delve |
| `terraform/` | Infrastructure as Code | Terraform, Terragrunt, OpenTofu, tflint, checkov, tfsec, trivy, infracost |

## Customization

Each `flake.nix` can be customized for your project needs:

- Add packages to `buildInputs`
- Add Python packages to the `withPackages` list
- Set environment variables in `shellHook`

## Updating Dependencies

```bash
# Update flake.lock in your project
nix flake update
```

## Without direnv

You can also use these directly:

```bash
# Enter shell manually
nix develop ~/myproject

# Or run a single command
nix develop ~/myproject -c python --version
```
