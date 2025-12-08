---
description: Add a cross-platform package to modules/common/packages.nix
model: sonnet
allowed-tools: Read, Edit, Bash(nix search:*), Bash(git:*), Bash(darwin-rebuild:*), Bash(sudo darwin-rebuild:*), Bash(home-manager:*)
---

# Quick Add Package

Add a package to `modules/common/packages.nix` (works on macOS and Linux).

**Input**: `$ARGUMENTS` = package name (e.g., "grip")

## Steps

1. **Search nixpkgs**: `nix search nixpkgs <pkg>` - find correct attribute name
2. **Read** `modules/common/packages.nix` to see existing sections
3. **Add package** to the appropriate section with a brief comment
4. **Commit**: `git add modules/common/packages.nix && git commit -m "feat(packages): add <pkg>"`
5. **Rebuild**:
   - **macOS**: `sudo darwin-rebuild switch --flake .`
   - **Linux**: `home-manager switch --flake .`
6. **Report** success or failure
