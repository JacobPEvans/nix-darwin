---
applyTo:
  - "**/*.nix"
  - "flake.nix"
  - "flake.lock"
---

# Nix-Specific Code Review Instructions

## Critical Nix Requirements (Always Enforce)

### 1. Flakes-Only Configuration

**NEVER suggest**:

- `nix-env` commands
- `nix-channel` operations
- Non-flake package management
- Imperative package installation

**DO suggest**:

- Adding packages to `modules/darwin/packages.nix` or similar
- Using `nix search nixpkgs <package>` to find packages
- Committing changes before rebuild

### 2. Determinate Nix Compatibility

**NEVER suggest**:

- Enabling `nix.enable = true` in nix-darwin
- Letting nix-darwin manage the Nix daemon
- Any nix-darwin Nix management options

**Context**: This system uses Determinate Nix installer, which manages the daemon itself.
nix-darwin's Nix management must stay disabled.

### 3. Nixpkgs First Policy

**NEVER suggest**:

- Using Homebrew for packages available in nixpkgs
- "Just install with brew" for standard packages

**DO suggest**:

- Searching nixpkgs first: `nix search nixpkgs <package>`
- Only using Homebrew if nixpkgs version is severely outdated or missing
- Documenting why Homebrew was necessary if used

## Nix Code Quality

### Focus On

- **Deprecated options** - Flag options marked deprecated in nixpkgs
- **Type errors** - Incorrect types passed to options (string vs list, etc)
- **Missing required options** - Options marked as required but not set
- **Incorrect option paths** - Typos in option names (hard to catch without testing)
- **Flake input mismatches** - Inputs declared but not used, or used but not declared
- **Home-manager specific issues**:
  - Using deprecated `programs.vscode.userSettings` instead of `programs.vscode.profiles.default.userSettings`
  - Incorrect special args handling
  - Module import path errors

### Don't Focus On

- **Formatting** - nixfmt handles this automatically
- **Personal preferences** - There are many valid ways to structure Nix code
- **Learning-oriented verbosity** - User is learning, extra comments are intentional
- **Splitting files** - Unless file is 500+ lines, don't suggest splitting

## Nix-Specific Antipatterns

### ❌ Bad: Suggesting Channels

```markdown
You could add this package with:
`nix-channel --add https://... && nix-channel --update`
```

**Why bad**: This repo uses flakes only, no channels

### ✅ Good: Flakes Approach

```markdown
Add this package to `modules/darwin/packages.nix`:
```nix
environment.systemPackages = with pkgs; [
  existing-package
  new-package
];
```

Then rebuild: `sudo darwin-rebuild switch --flake .`

**Why good**: Shows flakes-based approach for adding packages

### ❌ Bad: Enabling Nix Management

```markdown
Enable nix-darwin's Nix management for better integration:

\`\`\`nix
nix.enable = true;
\`\`\`
```

**Why bad**: Conflicts with Determinate Nix, breaks the system

### ✅ Good: Respecting Determinate Nix

```markdown
Note: This system uses Determinate Nix, so nix.enable must stay false.
For Nix daemon settings, use nix.extraOptions instead.
```

## Nix Security Issues (High Priority)

- **Secrets in Nix store** - Any secrets (API keys, tokens) in `.nix` files will be world-readable
- **Insecure fetchurl without hash** - `fetchurl` without sha256 is non-reproducible
- **allowUnfree without reasoning** - Flag if enabled globally without explanation
- **Untrusted substituters** - Adding binary caches without verification

## Common Nix Gotchas

### Path vs String

```nix
# ❌ Wrong - this is a string, not a path
home.file.".config/foo".source = "~/config/foo.txt";

# ✅ Right - use path type
home.file.".config/foo".source = ./config/foo.txt;
```

### String Interpolation in Derivations

```nix
# ❌ Wrong - shell variable won't expand in Nix context
home.file.".bashrc".text = ''
  export FOO=$HOME/.local/foo
'';

# ✅ Right - use ${config.home.homeDirectory} for user's home
home.file.".bashrc".text = ''
  export FOO=${config.home.homeDirectory}/.local/foo
'';
```

### Lists vs Attribute Sets

```nix
# ❌ Wrong - packages expects a list
environment.systemPackages = {
  pkg1 = pkgs.vim;
  pkg2 = pkgs.git;
};

# ✅ Right - use a list
environment.systemPackages = with pkgs; [
  vim
  git
];
```

## Review Examples

### ✅ Good Nix Review

```markdown
Line 45: `programs.vscode.userSettings` is deprecated.

Use `programs.vscode.profiles.default.userSettings` instead:

\`\`\`nix
programs.vscode.profiles.default.userSettings = {
  "editor.fontSize" = 14;
};
\`\`\`

See: <https://github.com/nix-community/home-manager/pull/4671>
```

**Why good**: Identifies deprecated API, provides specific fix, includes reference

### ❌ Bad Nix Review

```markdown
This Nix code could be more elegant
```

**Why bad**: Vague, no specifics, "elegant" is subjective
