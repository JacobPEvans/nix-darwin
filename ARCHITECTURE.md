# Architecture

Detailed structure of the nix-darwin configuration.

## Table of Contents

- [Directory Structure](#directory-structure)
- [Module Relationships](#module-relationships)
- [Configuration Layers](#configuration-layers)

---

## Directory Structure

```text
~/.config/nix/
├── flake.nix                      # Main entry point
├── flake.lock                     # Locked dependency versions
│
├── hosts/                         # Host-specific configurations
│   ├── macbook-m4/                # Active: M4 Max MacBook Pro
│   │   ├── default.nix            # Darwin system settings
│   │   └── home.nix               # User environment (Ollama, volumes)
│   ├── ubuntu-server/             # Template: Ubuntu server
│   │   ├── flake.nix              # Standalone flake for this host
│   │   ├── default.nix            # System notes (apt-managed)
│   │   └── home.nix               # home-manager config
│   ├── proxmox/                   # Template: Proxmox server
│   │   └── ...                    # Same structure as ubuntu-server
│   └── windows-workstation/       # Placeholder: awaiting Windows Nix
│       └── ...
│
├── modules/                       # Reusable configuration modules
│   ├── common/
│   │   └── packages.nix           # System-level packages for ALL platforms
│   ├── darwin/
│   │   ├── common.nix             # macOS system packages, homebrew, settings
│   │   ├── dock/                  # Dock configuration
│   │   │   ├── default.nix        # Dock behavior, appearance, hot corners
│   │   │   └── persistent-apps.nix # Dock app order (left & right sides)
│   │   ├── finder.nix             # Finder preferences
│   │   ├── keyboard.nix           # Keyboard settings
│   │   ├── trackpad.nix           # Trackpad gestures
│   │   └── system-ui.nix          # Menu bar, control center, login window
│   ├── linux/
│   │   └── common.nix             # Linux home-manager settings (XDG, packages)
│   └── home-manager/
│       ├── common.nix             # Cross-platform: shell, git, vscode
│       ├── ai-cli/                # AI CLI tool configurations
│       │   ├── claude.nix         # Claude Code settings
│       │   ├── gemini.nix         # Gemini CLI settings
│       │   └── copilot.nix        # GitHub Copilot settings
│       ├── permissions/           # AI CLI permission files
│       │   ├── claude-permissions-allow.nix
│       │   ├── claude-permissions-ask.nix
│       │   ├── claude-permissions-deny.nix
│       │   ├── gemini-permissions-allow.nix
│       │   ├── gemini-permissions-ask.nix
│       │   ├── gemini-permissions-deny.nix
│       │   ├── copilot-permissions-allow.nix
│       │   ├── copilot-permissions-ask.nix
│       │   └── copilot-permissions-deny.nix
│       ├── git/                   # Git aliases and settings
│       │   └── aliases.nix
│       ├── vscode/                # VS Code settings
│       │   ├── extensions.nix     # Extensions list
│       │   ├── settings.nix       # Editor settings
│       │   ├── keybindings.nix    # Keyboard shortcuts
│       │   └── copilot-settings.nix # GitHub Copilot for VS Code
│       └── zsh/                   # Shell configuration
│           ├── aliases.nix        # Command aliases
│           ├── docker-functions.zsh
│           └── ...
│
├── lib/                           # Shared configuration variables
│   ├── user-config.nix            # User info (name, email, GPG key)
│   ├── server-config.nix          # Server hostnames and settings
│   ├── security-policies.nix      # System-level security (git signing, etc.)
│   └── home-manager-defaults.nix  # Shared home-manager settings
│
├── shells/                        # Development environment templates
│   ├── python/                    # Basic Python development
│   ├── python-data/               # Python with pandas, numpy, jupyter
│   ├── js/                        # Node.js development
│   ├── go/                        # Go development
│   └── terraform/                 # Terraform/OpenTofu development
│
├── ARCHITECTURE.md                # This file - detailed structure
├── CHANGELOG.md                   # Completed work history
├── CLAUDE.md                      # AI agent instructions
├── PLANNING.md                    # Future roadmap
├── README.md                      # Project overview
├── REFERENCES.md                  # External documentation links
├── RUNBOOK.md                     # Operational procedures
├── SETUP.md                       # Initial setup guide
└── TROUBLESHOOTING.md             # Common issues and solutions
```

## Module Relationships

```text
flake.nix
    │
    ├── darwinConfigurations.default
    │       │
    │       ├── hosts/macbook-m4/default.nix
    │       │       └── imports: modules/darwin/common.nix
    │       │                       ├── modules/darwin/dock/
    │       │                       ├── modules/darwin/finder.nix
    │       │                       ├── modules/darwin/keyboard.nix
    │       │                       ├── modules/darwin/trackpad.nix
    │       │                       └── modules/darwin/system-ui.nix
    │       │
    │       └── home-manager
    │               └── hosts/macbook-m4/home.nix
    │                       └── imports: modules/home-manager/common.nix
    │                                       ├── modules/home-manager/ai-cli/
    │                                       ├── modules/home-manager/git/
    │                                       ├── modules/home-manager/vscode/
    │                                       └── modules/home-manager/zsh/
    │
    └── devShells
            ├── python      → shells/python/
            ├── python-data → shells/python-data/
            ├── js          → shells/js/
            ├── go          → shells/go/
            └── terraform   → shells/terraform/
```

## Configuration Layers

| Layer | Scope | Location | Managed By |
|-------|-------|----------|------------|
| System | macOS settings, packages | `modules/darwin/` | nix-darwin |
| User | Shell, git, apps | `modules/home-manager/` | home-manager |
| Host | Machine-specific | `hosts/<name>/` | Both |
| Shared | Variables, policies | `lib/` | Imported |
| Dev | Temporary environments | `shells/` | `nix develop` |
