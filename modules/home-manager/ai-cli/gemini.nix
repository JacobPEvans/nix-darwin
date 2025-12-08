# Gemini CLI Configuration
#
# Returns home.file entries for Google Gemini Code Assist CLI.
# Imported by home.nix for clean separation of AI CLI configs.
#
# Configuration format:
# - coreTools: List of allowed built-in tools and shell commands
# - excludeTools: List of permanently blocked commands
#
# Permission files:
# - gemini-permissions-allow.nix - coreTools (allowed commands)
# - gemini-permissions-deny.nix - excludeTools (blocked commands)
# - gemini-permissions-ask.nix - Reference only (Gemini doesn't support ask mode)

{ config, ... }:

let
  geminiAllow =
    import ../permissions/gemini-permissions-allow.nix { inherit config; };
  geminiDeny = import ../permissions/gemini-permissions-deny.nix { };
in {
  ".gemini/settings.json".text = builtins.toJSON {
    # JSON Schema reference for IDE IntelliSense and validation
    # Official schema from google-gemini/gemini-cli repo
    # NOTE: Gemini CLI has a bug where $schema triggers "not allowed" warning
    # See: https://github.com/google-gemini/gemini-cli/issues/12695
    "$schema" =
      "https://raw.githubusercontent.com/google-gemini/gemini-cli/main/schemas/settings.schema.json";

    # General settings
    general = {
      # Enable preview features (experimental models, features)
      previewFeatures = true;

      # Disable auto-update (managed via Nix)
      disableAutoUpdate = true;
    };

    # Security settings
    # See: https://geminicli.com/docs/cli/trusted-folders/
    security = {
      folderTrust = {
        # Enable folder trust system
        enabled = true;

        # Trusted directories where Gemini can operate without confirmation
        # SECURITY NOTE: Trusting a folder allows Gemini to read/write files
        # and execute commands within that directory without prompts.
        #
        # Trusted:
        # - ~/.config/nix: Nix configuration (this repo)
        # - ~/git: All git repositories (development work)
        #
        # NOT trusted (intentionally):
        # - ~/ (full home): Too broad, includes secrets (.ssh, .gnupg, etc.)
        # - ~/.config: Contains sensitive app configs
        # - /tmp: Potential for symlink attacks
        trustedFolders = [
          "${config.home.homeDirectory}/.config/nix"
          "${config.home.homeDirectory}/git"
        ];
      };
    };

    # Tools configuration (must be nested under "tools" key)
    # See: https://google-gemini.github.io/gemini-cli/docs/get-started/configuration.html
    tools = {
      # Allowed tools (safe, read-focused operations)
      # "allow always" selections are written here
      core = geminiAllow.coreTools;

      # Blocked tools (catastrophic operations)
      exclude = geminiDeny.excludeTools;

      # Sandbox configuration (macOS Seatbelt)
      # Uses permissive-open profile: restricts writes outside project directory
      # CRITICAL: Gemini won't execute commands without sandbox enabled
      # See: https://geminicli.com/docs/cli/sandbox/
      sandbox = true;
    };
  };
}
