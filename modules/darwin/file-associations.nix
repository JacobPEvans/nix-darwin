# File Type Associations for macOS
#
# Configure custom file extension mappings and default applications.
# Uses duti to register file type handlers with Launch Services.
#
# This module enables macOS to recognize non-standard archive extensions
# (like .spl and .crbl) as compressed tar archives, enabling:
# - Double-click extraction in Finder
# - Proper file type detection
# - Shell autocomplete suggestions
#
# Reference: https://github.com/moretension/duti

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.system.fileAssociations;

  # Convert extension mapping to duti command
  # Example: { extension = "spl"; uti = "public.tar-archive"; } -> duti command
  associationToDutiCommand =
    assoc:
    let
      # Use Archive Utility as the default handler for archives
      # This is the built-in macOS app that handles .tar.gz files
      handler = "com.apple.archiveutility";
      role = "all"; # all = viewer, editor, and shell role
    in
    ''${pkgs.duti}/bin/duti -s ${handler} .${assoc.extension} ${role}'';

  # Generate activation script for all file associations
  activationScript = ''
    echo "Configuring file type associations..."
    ${concatMapStringsSep "\n" associationToDutiCommand cfg.customExtensions}

    # Restart Finder to apply changes immediately
    # (Launch Services database updates may not be visible until restart)
    # NOTE: Uses '|| true' to continue activation even if killall fails.
    # This follows CRITICAL RULES from docs/ACTIVATION-SCRIPTS-RULES.md:
    #   * Never use 'set -e' - errors must not abort the script
    #   * All errors treated as warnings, not fatal failures
    #   * Must reach /run/current-system symlink update (the critical phase)
    /usr/bin/killall Finder 2>/dev/null || true
  '';

in
{
  # ==========================================================================
  # Module Options
  # ==========================================================================
  options.system.fileAssociations = {
    enable = lib.mkEnableOption "custom file type associations" // {
      default = true;
    };

    customExtensions = lib.mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            extension = lib.mkOption {
              type = types.str;
              description = "File extension (without leading dot)";
              example = "spl";
            };

            uti = lib.mkOption {
              type = types.str;
              description = "Uniform Type Identifier for the file type";
              example = "public.tar-archive";
            };

            description = lib.mkOption {
              type = types.str;
              default = "";
              description = "Human-readable description of the file type";
              example = "Splunk archive";
            };
          };
        }
      );

      default = [
        {
          extension = "spl";
          uti = "public.tar-archive";
          description = "Splunk archive (tar.gz)";
        }
        {
          extension = "crbl";
          uti = "public.tar-archive";
          description = "CRBL archive (tar.gz)";
        }
      ];

      description = ''
        List of custom file extensions to associate with specific UTIs.

        Each extension will be registered with macOS Launch Services to enable:
        - Double-click extraction in Finder
        - Proper file type detection
        - Shell autocomplete suggestions

        Common UTIs for archive types:
        - public.tar-archive (for .tar files)
        - org.gnu.gnu-zip-archive (for .gz files)
        - public.zip-archive (for .zip files)

        To find UTIs for existing file types:
          mdls -name kMDItemContentType <filename>
      '';

      example = literalExpression ''
        [
          {
            extension = "spl";
            uti = "public.tar-archive";
            description = "Splunk archive";
          }
          {
            extension = "myarchive";
            uti = "public.tar-archive";
            description = "My custom archive format";
          }
        ]
      '';
    };
  };

  # ==========================================================================
  # Module Implementation
  # ==========================================================================
  config = lib.mkIf cfg.enable {
    # Add duti package for file association management
    environment.systemPackages = [ pkgs.duti ];

    # Register file associations on system activation
    # This runs when: darwin-rebuild switch/activate
    system.activationScripts.fileAssociations.text = activationScript;

    # User instructions displayed after rebuild
    system.activationScripts.postActivation.text = mkAfter ''
      echo ""
      echo "File associations configured for:"
      ${concatMapStringsSep "\n" (
        assoc:
        ''echo "  - .${assoc.extension} → ${assoc.uti}${
          optionalString (assoc.description != "") " (${assoc.description})"
        }"''
      ) cfg.customExtensions}
      echo ""
      echo "To verify associations, run:"
      echo "  duti -x <extension>"
      echo ""
      echo "Example:"
      echo "  duti -x spl"
      echo ""
    '';
  };
}
