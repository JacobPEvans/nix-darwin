# Specification: Directory-Based Shell Profiles with Visual Context

**Issue**: #41
**Type**: Enhancement / ZSH Configuration
**Labels**: enhancement, quick-win, ready-for-dev, zsh
**Created**: 2025-12-14 by Auto-Claude Orchestrator

## Problem Statement

All directories use the same shell appearance and aliases, making context switching between different project types
(work/personal, different languages) harder to track mentally.

**Current State**:

- direnv enabled with nix-direnv support
- Environment variables per directory via `.envrc`
- Oh-My-Zsh with `robbyrussell` theme
- No per-directory theme/prompt customization
- No directory-specific aliases

**Goal**: Visual and functional context awareness when entering different project directories.

## Solution

Three-layer approach:

1. **Layer 1**: Environment variables (existing - direnv)
2. **Layer 2**: Visual context (new - powerlevel10k theme)
3. **Layer 3**: Directory aliases (new - direnv extension)

## Technical Design

### 1. Theme Replacement: robbyrussell → powerlevel10k

**File**: `modules/home-manager/common.nix`

**Current Configuration**:

```nix
programs.zsh = {
  enable = true;
  oh-my-zsh = {
    enable = true;
    theme = "robbyrussell";
    plugins = [
      "git"
      "macos"
      # ... other plugins
    ];
  };
};
```

**New Configuration**:

```nix
programs.zsh = {
  enable = true;

  oh-my-zsh = {
    enable = true;
    theme = "powerlevel10k/powerlevel10k";  # Changed
    plugins = [
      "git"
      "macos"
      # ... existing plugins
    ];
  };

  # Powerlevel10k instant prompt (fast startup)
  initExtra = ''
    # Enable Powerlevel10k instant prompt
    if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
      source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
    fi

    # Load p10k config if it exists
    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
  '';
};

# Add powerlevel10k package
home.packages = with pkgs; [
  zsh-powerlevel10k
  # ... existing packages
];
```

### 2. Powerlevel10k Configuration

**File**: `modules/home-manager/shell/p10k-config.nix`

Create a new file for powerlevel10k configuration:

```nix
{ config, lib, ... }:

{
  home.file.".p10k.zsh".text = ''
    # Powerlevel10k configuration
    # Instant prompt mode
    typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose

    # Basic prompt elements
    typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
      dir                     # Current directory
      vcs                     # Git status
      direnv                  # direnv status
      context                 # User@host (when relevant)
    )

    typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
      status                  # Exit code
      command_execution_time  # Duration of last command
      background_jobs         # Background jobs indicator
      time                    # Current time
    )

    # Directory-based context indicators
    typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=v3

    # Git/VCS status
    typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND='green'
    typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='yellow'
    typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='cyan'

    # Directory-specific visual indicators
    # These can be customized per project type via .envrc
    typeset -g POWERLEVEL9K_DIR_FOREGROUND=${"${DIRENV_DIR_COLOR:-blue}"}

    # Direnv segment (shows when direnv is active)
    typeset -g POWERLEVEL9K_DIRENV_FOREGROUND='yellow'
    typeset -g POWERLEVEL9K_DIRENV_VISUAL_IDENTIFIER_EXPANSION='📁'

    # Shorten directory paths
    typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_last
    typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
  '';
}
```

**Import in common.nix**:

```nix
imports = [
  # ... existing imports
  ./shell/p10k-config.nix
];
```

### 3. Directory-Specific Aliases via Direnv

**Pattern**: Extend `.envrc` to source `.aliases` if present

**Template .envrc** (for projects):

```bash
# Python project example
use flake

# Load project-specific aliases
if [ -f ".aliases" ]; then
  source_env ".aliases"
fi

# Set visual context (powerlevel10k colors)
export DIRENV_DIR_COLOR="magenta"  # Python projects = magenta
export PROJECT_TYPE="python"
```

**Template .aliases** (for projects):

```bash
# Project-specific aliases
alias test='pytest -v'
alias lint='ruff check .'
alias format='black .'
alias run='python -m myproject'
```

### 4. Project Type Templates

**Location**: `docs/shell-profiles/` (new directory)

Template pattern for `.envrc`:

```bash
use flake
[ -f ".aliases" ] && source_env ".aliases"
export DIRENV_DIR_COLOR="<color>"  # magenta=Python, green=Node, blue=Nix
export PROJECT_TYPE="<type>"
```

Template pattern for `.aliases`:

```bash
alias test='<test-command>'
alias lint='<lint-command>'
alias build='<build-command>'
```

### 5. Documentation

**File**: `docs/SHELL-PROFILES.md` (new)

```markdown
# Directory-Based Shell Profiles

Customize your shell appearance and aliases per project directory.

## Quick Start

1. Copy template files to your project:

   ```bash
   cp ~/.config/nix/docs/shell-profiles/python.envrc .envrc
   cp ~/.config/nix/docs/shell-profiles/python.aliases .aliases
   ```

1. Allow direnv:

   ```bash
   direnv allow
   ```

1. Enter directory - prompt changes and aliases load automatically

## Available Templates

- `python.{envrc,aliases}` - Python projects (magenta)
- `node.{envrc,aliases}` - Node.js projects (green)
- `nix.{envrc,aliases}` - Nix projects (blue)

## Custom Profiles

### Visual Indicators

Set directory color in `.envrc`:

```bash
export DIRENV_DIR_COLOR="cyan"  # blue, green, magenta, cyan, yellow, red
```

### Project-Specific Aliases

Create `.aliases` file:

```bash
alias build='custom-build-command'
alias test='custom-test-command'
```

### Environment Variables

Standard direnv patterns work:

```bash
export API_KEY=dev-key
export DATABASE_URL=postgres://localhost/dev
```

## Examples

### Work Project

```bash
# .envrc
use flake
export DIRENV_DIR_COLOR="red"
export PROJECT_TYPE="work"
```

### Personal Project

```bash
# .envrc
use flake
export DIRENV_DIR_COLOR="green"
export PROJECT_TYPE="personal"
```

## Files to Create/Modify

### Create

1. **`modules/home-manager/shell/p10k-config.nix`** - Powerlevel10k configuration
2. **`docs/SHELL-PROFILES.md`** - User documentation
3. **`docs/shell-profiles/python.envrc`** - Python template
4. **`docs/shell-profiles/python.aliases`** - Python aliases template
5. **`docs/shell-profiles/node.envrc`** - Node.js template
6. **`docs/shell-profiles/node.aliases`** - Node.js aliases template
7. **`docs/shell-profiles/nix.envrc`** - Nix template
8. **`docs/shell-profiles/nix.aliases`** - Nix aliases template
9. **`docs/shell-profiles/README.md`** - Template documentation

### Modify

1. **`modules/home-manager/common.nix`**
   - Change theme to powerlevel10k
   - Add `initExtra` for instant prompt
   - Import p10k-config.nix

2. **`flake.nix`** (if needed)
   - Ensure zsh-powerlevel10k is available in nixpkgs

## Implementation Notes

### Powerlevel10k Benefits

- **Instant prompt**: Fast shell startup (renders prompt immediately)
- **Rich segments**: Git status, time, exit codes, etc.
- **Directory awareness**: Built-in support for context-based customization
- **Performance**: Written in C, much faster than pure shell themes

### Direnv Integration

Direnv's `source_env` function:

- Loads files in direnv's context
- Environment is cleaned up when leaving directory
- Aliases are properly scoped to directory

### Color Options

Powerlevel10k supports these color names:

- `black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`
- Also supports numeric colors: `001`-`255`

### Instant Prompt Mode

Powerlevel10k's instant prompt:

1. Renders prompt immediately on shell start
2. Captures slow command output in background
3. Re-renders prompt once initialization complete
4. Result: Shell feels instant even with slow `.zshrc`

## Out of Scope

- Custom profile management system (use existing direnv)
- Automatic profile detection (require explicit `.envrc`)
- Complex theming system (use powerlevel10k defaults)
- Per-user profile sync (manual setup per machine)
- IDE/editor integration (shell-only)

## Success Criteria

- [ ] Powerlevel10k installed and configured
- [ ] Instant prompt works (fast shell startup)
- [ ] Entering directory with `.envrc` changes prompt color
- [ ] Directory-specific aliases load automatically
- [ ] Templates provided for Python, Node, Nix projects
- [ ] Documentation explains how to create custom profiles
- [ ] No performance regression (instant prompt maintains speed)

## Testing Plan

### Test Case 1: Theme Installation

```bash
# After darwin-rebuild
echo $ZSH_THEME
# Expected: powerlevel10k/powerlevel10k

# Check p10k config exists
ls ~/.p10k.zsh
# Expected: File exists
```

### Test Case 2: Directory Context Change

```bash
# Create test directory with .envrc
mkdir /tmp/test-python
cd /tmp/test-python

cat > .envrc << 'EOF'
export DIRENV_DIR_COLOR="magenta"
EOF

direnv allow

# Expected: Prompt changes color (visual inspection)
```

### Test Case 3: Directory Aliases

```bash
# Create test directory with aliases
mkdir /tmp/test-aliases
cd /tmp/test-aliases

cat > .envrc << 'EOF'
[ -f ".aliases" ] && source_env ".aliases"
EOF

cat > .aliases << 'EOF'
alias testcmd='echo "Test alias works"'
EOF

direnv allow

# Test alias
testcmd
# Expected: "Test alias works"

# Leave directory
cd ~

# Test alias (should not exist)
testcmd
# Expected: command not found
```

### Test Case 4: Instant Prompt Performance

```bash
# Measure shell startup time
time zsh -i -c exit

# Expected: < 100ms (instant prompt should make it fast)
```

### Test Case 5: Template Usage

```bash
# Copy Python template
cp ~/.config/nix/docs/shell-profiles/python.envrc ~/my-project/.envrc
cp ~/.config/nix/docs/shell-profiles/python.aliases ~/my-project/.aliases

cd ~/my-project
direnv allow

# Test Python aliases
test  # Should map to 'pytest -v'
```

## Migration Path

### Current State

- Oh-My-Zsh with robbyrussell theme
- direnv for environment variables only
- No visual context switching

### Migration Steps

1. **Install powerlevel10k**

   ```bash
   # Update modules/home-manager/common.nix
   # Add zsh-powerlevel10k to packages
   # Change theme to powerlevel10k
   ```

2. **Test build**

   ```bash
   nix flake check
   darwin-rebuild switch --flake ~/.config/nix
   ```

3. **Configure p10k**

   ```bash
   # On first run, p10k may offer configuration wizard
   # Or use pre-configured .p10k.zsh from Nix
   ```

4. **Create template files**

   ```bash
   # Create docs/shell-profiles/ directory
   # Add .envrc and .aliases templates
   ```

5. **Test with sample project**

   ```bash
   mkdir ~/test-profile
   cp docs/shell-profiles/python.* ~/test-profile/
   cd ~/test-profile
   direnv allow
   ```

### Rollback Plan

```bash
# Revert theme change in common.nix
programs.zsh.oh-my-zsh.theme = "robbyrussell";

# Remove powerlevel10k package
# Remove p10k-config.nix import

# Rebuild
darwin-rebuild switch --flake ~/.config/nix
```

## References

- Issue #41: <https://github.com/JacobPEvans/nix/issues/41>
- Powerlevel10k: <https://github.com/romkatv/powerlevel10k>
- direnv: <https://direnv.net/>
- Oh-My-Zsh: <https://ohmyz.sh/>
- Powerlevel10k Documentation: <https://github.com/romkatv/powerlevel10k#readme>
- direnv source_env: <https://github.com/direnv/direnv/wiki/PS1>

## Dependencies

- `zsh` (already installed)
- `oh-my-zsh` (already configured)
- `direnv` (already enabled)
- `zsh-powerlevel10k` package (from nixpkgs)
- `nix-direnv` (already installed)

## Future Enhancements

- Integrate with project templates in agent-os
- Add more project type templates (Rust, Go, Java, etc.)
- Create slash command to generate .envrc/.aliases from templates
- Add project type detection and suggestion
- Visual indicator for AI CLI tool contexts (Claude, Gemini, Copilot)
