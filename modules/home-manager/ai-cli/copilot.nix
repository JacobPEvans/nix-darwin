# GitHub Copilot CLI Configuration
#
# Returns home.file entries for GitHub Copilot CLI.
# Imported by home.nix for clean separation of AI CLI configs.
#
# Strategy: Directory trust model with runtime permission flags
#
# Configuration format:
# - config.json: Contains trusted_folders array
# - CLI flags: --allow-tool and --deny-tool (runtime only)
#
# Note: Unlike Claude/Gemini, Copilot's permission system is primarily
# CLI-flag based. The config file only manages directory trust.

{ config, ... }:

let
  copilotAllow =
    import ../permissions/copilot-permissions-allow.nix { inherit config; };
in {
  ".copilot/config.json".text = builtins.toJSON {
    # Trusted directories where Copilot can operate without confirmation
    trusted_folders = copilotAllow.trusted_folders;

    # Additional Copilot CLI settings can be added here
    # Note: Tool-level permissions require CLI flags, not config settings
  };
}
