# Cribl Edge Service Management
#
# Manages the Cribl Edge LaunchDaemon declaratively so it survives .pkg upgrades.
# The .pkg installer drops its own plist at /Library/LaunchDaemons/io.cribl.plist
# which gets overwritten on every upgrade — this module removes it and replaces it
# with a Nix-managed service definition.
#
# Cribl Edge itself is installed externally via .pkg (not in any package manager).
# This module manages: LaunchDaemon lifecycle, ACL-based file permissions, pack deployment.
# Service runs as user 'cribl'; activation scripts run as root. No FDA — ACLs only for monitored paths.
#
# Note: Disabling this module does not automatically remove ACLs from previously
# configured paths. Run `/bin/chmod -a "cribl allow ..." <path>` manually if needed.

{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.programs.cribl-edge;
  path = cfg.installPath;
  user = "cribl";
  group = "cribl";
  aclPerms = "${user} allow read,readattr,readextattr,readsecurity,list,search";
  ts = "$(date '+%Y-%m-%d %H:%M:%S')";

  # Build a deploy script per pack — each invocation is idempotent
  deployPack = pkgs.writeShellApplication {
    name = "cribl-deploy-pack";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      PACK_NAME="$1"
      PACK_SRC="$2"
      CRIBL_PATH="$3"
      STATUS="unchanged"

      # Validate pack name (activation runs as root — prevent directory traversal)
      case "$PACK_NAME" in
        ""|*/*|*..*)
          echo "Invalid pack name '$PACK_NAME': must be a simple basename" >&2
          exit 1
          ;;
      esac

      TARGET="$CRIBL_PATH/default/$PACK_NAME"
      MARKER="$TARGET/.nix-store-path"

      # Deploy if store path changed (stage to tmp dir, then atomic mv)
      if [ ! -f "$MARKER" ] || [ "$(cat "$MARKER" 2>/dev/null)" != "$PACK_SRC" ]; then
        STAGING="''${TARGET}.tmp.$$"
        rm -rf "$STAGING" "$TARGET"
        cp -R "$PACK_SRC" "$STAGING"
        /usr/sbin/chown -R ${user}:${group} "$STAGING"
        mv "$STAGING" "$TARGET"
        echo "$PACK_SRC" > "$MARKER"
        STATUS="deployed"
      fi

      # Register in package.json if missing (uses jq --arg to keep $CRIBL_HOME literal)
      if [ -f "$CRIBL_PATH/package.json" ] && \
         ! jq -e --arg n "$PACK_NAME" '.dependencies[$n]' "$CRIBL_PATH/package.json" >/dev/null 2>&1; then
        jq --arg n "$PACK_NAME" --arg v 'file:$CRIBL_HOME/default/'"$PACK_NAME" \
          '.dependencies |= ((if type == "object" then . else {} end) + {($n): $v})' \
          "$CRIBL_PATH/package.json" > "$CRIBL_PATH/package.json.tmp"
        mv "$CRIBL_PATH/package.json.tmp" "$CRIBL_PATH/package.json"
        /usr/sbin/chown ${user}:${group} "$CRIBL_PATH/package.json"
        if [ "$STATUS" = "unchanged" ]; then
          STATUS="registered"
        else
          STATUS="$STATUS and registered"
        fi
      fi

      echo "$STATUS"
    '';
  };
in
{
  options.programs.cribl-edge = {
    enable = lib.mkEnableOption "Cribl Edge service management";

    installPath = lib.mkOption {
      type = lib.types.str;
      default = "/opt/cribl";
      description = "Installation path for Cribl Edge (set by .pkg installer).";
    };

    acls = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Paths to grant the cribl user read ACL access to.";
      example = [
        "/var/log"
        "/var/audit"
        "/Library/Logs"
        "/Library/Logs/DiagnosticReports"
      ];
    };

    packs = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      default = { };
      description = ''
        Cribl Edge packs to deploy declaratively.
        Key = pack name, value = derivation containing pack files.
        Use fetchzip with extension = "tar.gz" for .crbl files.
      '';
      example = lib.literalExpression ''
        {
          cc-edge-macos-power = pkgs.fetchzip {
            url = "https://github.com/JacobPEvans/cc-edge-macos-power/releases/download/v1.0.0/cc-edge-macos-power-v1.0.0.crbl";
            extension = "tar.gz";
            hash = "sha256-...";
            stripRoot = false;
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Remove .pkg-installed plist — Nix manages the service declaratively
    system.activationScripts.preActivation.text = lib.mkAfter ''
      if [ -f /Library/LaunchDaemons/io.cribl.plist ]; then
        /bin/launchctl bootout system/io.cribl 2>/dev/null || true
        rm -f /Library/LaunchDaemons/io.cribl.plist
        echo "${ts} [INFO] Removed .pkg-installed Cribl plist (Nix manages this service)"
      fi
    '';

    system.activationScripts.postActivation.text = lib.mkAfter ''
      if [ ! -d "${path}/bin" ]; then
        echo "${ts} [WARN] Cribl Edge not found at ${path}"
        echo "  Install via .pkg from https://cribl.io/download/ or Cribl Cloud enrollment"
      else
        # The .pkg installer creates everything as root:wheel but the LaunchDaemon
        # runs as ${user}:${group}. Only chown if ownership has drifted.
        if [ "$(/usr/bin/stat -f '%Su' "${path}")" != "${user}" ]; then
          /usr/sbin/chown -R ${user}:${group} "${path}"
          echo "${ts} [INFO] Fixed Cribl Edge directory ownership → ${user}:${group}"
        fi
      fi

      ${lib.optionalString (cfg.acls != [ ]) ''
        # Remove-then-add ensures idempotency: prevents duplicate ACEs across rebuilds
        _acl_applied=0
        ${lib.concatMapStringsSep "\n" (p: ''
          if [ -e "${p}" ]; then
            /bin/chmod -a "${aclPerms}" "${p}" 2>/dev/null || true
            /bin/chmod +a "${aclPerms}" "${p}" 2>&1 || echo "${ts} [WARN] Failed to set ACL on ${p}"
            _acl_applied=$((_acl_applied + 1))
          fi
        '') cfg.acls}
        echo "${ts} [INFO] Applied Cribl Edge ACLs to $_acl_applied of ${toString (builtins.length cfg.acls)} path(s)"
      ''}

      ${lib.optionalString (cfg.packs != { }) ''
        _packs_changed=0
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: src: ''
            _result=$(${deployPack}/bin/cribl-deploy-pack "${name}" "${src}" "${path}")
            if [ "$_result" != "unchanged" ]; then
              _packs_changed=1
              echo "${ts} [INFO] Cribl Edge pack ${name}: $_result"
            fi
          '') cfg.packs
        )}
        if [ "$_packs_changed" -eq 1 ]; then
          /bin/launchctl kickstart -k system/com.nix-darwin.cribl-edge 2>/dev/null || true
          echo "${ts} [INFO] Restarted Cribl Edge (pack changes detected)"
        fi
      ''}
    '';

    launchd.daemons.cribl-edge = {
      serviceConfig = {
        Label = "com.nix-darwin.cribl-edge";
        ProgramArguments = [
          "${path}/bin/cribl"
          "server"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ThrottleInterval = 10;
        UserName = user;
        GroupName = group;
        WorkingDirectory = path;
        StandardOutPath = "${path}/log/cribl-stdout.log";
        StandardErrorPath = "${path}/log/cribl-stderr.log";
        EnvironmentVariables = {
          CRIBL_HOME = path;
        };
      };
    };
  };
}
