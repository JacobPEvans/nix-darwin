# File Extension Mappings Module
#
# Configures macOS Launch Services to recognize custom file extensions
# as specific archive types (e.g., .spl and .crbl as tar.gz).
#
# This enables:
# - Finder to auto-extract archives on double-click
# - Shell autocomplete to recognize these files as archives
# - Correct file type icons and handling
#
# Usage:
#   programs.file-extensions = {
#     enable = true;
#     customMappings = {
#       ".spl" = "public.tar-archive";
#       ".crbl" = "public.tar-archive";
#     };
#   };
#
# Common UTI types:
# - public.tar-archive      (tar, tar.gz, tgz)
# - public.zip-archive      (zip)
# - public.bzip2-archive    (bz2)
# - public.gzip-archive     (gz)
#
# Reference: https://developer.apple.com/documentation/uniformtypeidentifiers

{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.programs.file-extensions;
in
{
  options.programs.file-extensions = {
    enable = lib.mkEnableOption "custom file extension mappings";

    customMappings = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        ".spl" = "public.tar-archive";
        ".crbl" = "public.tar-archive";
      };
      description = ''
        Custom file extension to UTI (Uniform Type Identifier) mappings.
        Extensions should start with a dot (e.g., ".spl").
        UTI values determine how macOS handles the file type.
      '';
      example = {
        ".spl" = "public.tar-archive";
        ".crbl" = "public.tar-archive";
        ".custom" = "public.zip-archive";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Validate that extensions start with a dot
    assertions = [
      {
        assertion = lib.all (ext: lib.hasPrefix "." ext) (lib.attrNames cfg.customMappings);
        message = "All file extensions must start with a dot (e.g., '.spl', not 'spl')";
      }
    ];

    # Install duti for setting file associations
    environment.systemPackages = [ pkgs.duti ];

    # Configure file associations using duti during system activation
    system.activationScripts.postActivation.text = lib.mkAfter ''
      echo "Configuring custom file extension mappings..." >&2

      # Create temporary duti configuration file
      DUTI_CONFIG=$(mktemp)
      trap 'rm -f $DUTI_CONFIG' EXIT

      # Generate duti configuration for each custom extension
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (ext: uti: ''
          # Map ${ext} to ${uti}
          # Format: UTI handler role
          # Role: all = default handler for this type
          echo "${uti} ${ext} all" >> "$DUTI_CONFIG"
        '') cfg.customMappings
      )}

      # Apply the configuration with duti
      # NOTE: Using 'if ... then ... else ...' instead of '|| exit 1' pattern
      # because we follow CRITICAL RULES in docs/ACTIVATION-SCRIPTS-RULES.md:
      #   * Never use constructs that exit early (set -e, || exit, etc.)
      #   * Treat all errors as warnings, not fatal failures
      #   * Must reach /run/current-system symlink update (the critical phase)
      if ${pkgs.duti}/bin/duti "$DUTI_CONFIG" 2>/dev/null; then
        echo "Successfully registered ${toString (lib.length (lib.attrNames cfg.customMappings))} file extension(s)" >&2

        # Rebuild Launch Services database to ensure changes take effect
        # Note: lsregister can fail on some systems, so we add error handling to prevent
        # activation failure. The file mappings still work even if lsregister fails.
        # Again using if/then/else to continue activation on failure (not || exit pattern)
        if /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user 2>&1; then
          echo "Launch Services database rebuilt" >&2
        else
          echo "Warning: Failed to rebuild Launch Services database (file mappings still applied)" >&2
        fi
      else
        echo "Warning: Failed to apply file extension mappings" >&2
      fi

      # Display configured mappings
      echo "Configured mappings:" >&2
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (ext: uti: ''
          echo "  ${ext} → ${uti}" >&2
        '') cfg.customMappings
      )}
    '';

    # Inform user about activation
    system.activationScripts.preActivation.text = lib.mkBefore ''
      echo "Note: Custom file extension mappings will be configured during activation" >&2
      echo "Extensions: ${lib.concatStringsSep ", " (lib.attrNames cfg.customMappings)}" >&2
    '';
  };
}
