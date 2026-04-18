# Cribl Edge Service Management
#
# Manages the Cribl Edge LaunchDaemon declaratively so it survives .pkg upgrades.
# The .pkg installer drops its own plist at /Library/LaunchDaemons/io.cribl.plist
# which gets overwritten on every upgrade — this module removes it and replaces it
# with a Nix-managed service definition.
#
# This module manages: binary installation (via .pkg on every rebuild), LaunchDaemon
# lifecycle, fleet enrollment config (fresh installs only), and pack deployment.
# Cribl Cloud manages all runtime configuration after enrollment.
#
# Service runs as root (temporary — revert user/group to cribl:cribl when ready).

{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.programs.cribl-edge;
  path = cfg.installPath;
  user = "root";
  group = "wheel";
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
      description = "Installation path for Cribl Edge.";
    };

    version = lib.mkOption {
      type = lib.types.str;
      description = "Cribl Edge version string (e.g., '4.17.0-7e952fa7'). Bump to upgrade.";
      example = "4.17.0-7e952fa7";
    };

    cloud = {
      host = lib.mkOption {
        type = lib.types.str;
        description = "Cribl Cloud leader hostname.";
        example = "main-stoic-kaminsky-d9o9i3r.cribl.cloud";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 4200;
        description = "Cribl Cloud leader port.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "default_fleet";
        description = "Fleet group name.";
      };

      tokenCommand = lib.mkOption {
        type = lib.types.str;
        description = "Shell command that outputs the auth token. Only used on fresh installs (when instance.yml does not exist).";
        example = "doppler secrets get CRIBL_TOKEN --plain -p iac-conf-mgmt -c prd";
      };
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
            # ── 1. Download and install the .pkg ──────────────────────────────────────
            _major="${cfg.version}"
            _major="''${_major%%-*}"
            _pkg_url="https://cdn.cribl.io/dl/$_major/cribl-${cfg.version}-darwin-universal.pkg"
            _pkg="/tmp/cribl-${cfg.version}.pkg"

            echo "${ts} [INFO] Installing Cribl Edge ${cfg.version}..."
            if ! curl -Lso "$_pkg" "$_pkg_url"; then
              echo "${ts} [ERROR] Failed to download Cribl Edge .pkg" >&2
              exit 1
            fi
            if curl -Lso "$_pkg.md5" "$_pkg_url.md5"; then
              _expected=$(awk '{print $1}' "$_pkg.md5")
              _actual=$(md5 -q "$_pkg")
              if [ "$_expected" != "$_actual" ]; then
                echo "${ts} [ERROR] Cribl .pkg checksum mismatch (expected=$_expected actual=$_actual)" >&2
                rm -f "$_pkg" "$_pkg.md5"
                exit 1
              fi
            else
              echo "${ts} [WARN] Could not fetch .md5 — skipping checksum verification"
            fi

            # Stop Nix-managed service before installing
            /bin/launchctl bootout system/com.nix-darwin.cribl-edge 2>/dev/null || true

            if ! installer -pkg "$_pkg" -target /; then
              echo "${ts} [ERROR] Cribl .pkg installation failed" >&2
              rm -f "$_pkg" "$_pkg.md5"
              exit 1
            fi

            # Installer auto-starts its own plist — tear it down, Nix manages the service
            /bin/launchctl bootout system/io.cribl 2>/dev/null || true
            rm -f /Library/LaunchDaemons/io.cribl.plist "$_pkg" "$_pkg.md5"
            echo "${ts} [INFO] Cribl Edge ${cfg.version} installed"

            # ── 2. Ownership ──────────────────────────────────────────────────────────
            /usr/sbin/chown -R ${user}:${group} "${path}"

            # ── 3. Remove cribl user/group ────────────────────────────────────────────
            if /usr/bin/dscl . -read /Users/cribl >/dev/null 2>&1; then
              /usr/bin/dscl . -delete /Users/cribl 2>/dev/null || true
              echo "${ts} [INFO] Removed cribl user (service now runs as root)"
            fi
            if /usr/bin/dscl . -read /Groups/cribl >/dev/null 2>&1; then
              /usr/bin/dscl . -delete /Groups/cribl 2>/dev/null || true
              echo "${ts} [INFO] Removed cribl group"
            fi

            # ── 4. Fleet enrollment (fresh installs only) ─────────────────────────────
            _instance_yml="${path}/local/_system/instance.yml"
            if [ ! -f "$_instance_yml" ]; then
              echo "${ts} [INFO] Writing fleet enrollment config..."
              mkdir -p "${path}/local/_system"
              _token=$(eval "${cfg.cloud.tokenCommand}") || {
                echo "${ts} [ERROR] Failed to fetch Cribl auth token" >&2
                exit 1
              }
              cat > "$_instance_yml" <<INSTANCEEOF
      distributed:
        mode: managed-edge
        master:
          host: ${cfg.cloud.host}
          port: ${toString cfg.cloud.port}
          authToken: $_token
          tls:
            disabled: false
        group: ${cfg.cloud.group}
        tags: []
      INSTANCEEOF
              /usr/sbin/chown ${user}:${group} "$_instance_yml"
              echo "${ts} [INFO] Fleet enrollment config written"
            fi

            # ── 5. Clean up stale cribl ACLs (one-time, idempotent) ───────────────────
            _acl="cribl allow read,readattr,readextattr,readsecurity,list,search"
            for _p in /var/log /var/log/asl /var/log/DiagnosticMessages /var/audit /Library/Logs /Library/Logs/DiagnosticReports; do
              if [ -e "$_p" ]; then
                /bin/chmod -a "$_acl" "$_p" 2>/dev/null || true
              fi
            done

            # ── 6. Deploy packs ───────────────────────────────────────────────────────
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
                echo "${ts} [INFO] Packs updated"
              fi
            ''}

            # ── 7. Start service ──────────────────────────────────────────────────────
            /bin/launchctl kickstart system/com.nix-darwin.cribl-edge 2>/dev/null || true
            echo "${ts} [INFO] Cribl Edge service started"
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
