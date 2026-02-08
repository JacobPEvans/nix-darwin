# macOS Syslog Forwarding Configuration
#
# Configures macOS built-in syslogd to forward all logs to a remote server.
# Uses /etc/syslog.conf which is the standard BSD syslog configuration.
#
# Log flow: macOS syslogd -> HAProxy (load balancer) -> Cribl Edge -> Splunk
#
# Configuration is centralized in lib/user-config.nix under logging.syslog
# to allow easy modification of the syslog server without editing this module.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  userConfig = import ../../lib/user-config.nix;

  # Build the remote server specification
  # UDP: @server:port
  # TCP: @@server:port
  protocolPrefix = if userConfig.logging.syslog.protocol == "tcp" then "@@" else "@";

  remoteServer = "${protocolPrefix}${userConfig.logging.syslog.server}:${toString userConfig.logging.syslog.port}";
in
{
  # Auto-rename syslog.conf if it has unrecognized content (runs before etc check)
  # This prevents "Unexpected files in /etc" errors during darwin-rebuild
  # See: https://github.com/nix-darwin/nix-darwin/issues/149
  system.activationScripts.preActivation.text = lib.mkBefore ''
    if [[ -f /etc/syslog.conf ]] && [[ ! -L /etc/syslog.conf ]]; then
      # File exists and is not a symlink - check if it's nix-managed
      if ! grep -q "Managed by nix-darwin" /etc/syslog.conf 2>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Backing up /etc/syslog.conf to /etc/syslog.conf.before-nix-darwin"
        /bin/mv /etc/syslog.conf /etc/syslog.conf.before-nix-darwin
      fi
    fi
  '';

  # Create /etc/syslog.conf with remote forwarding configuration
  # The *.* selector matches all facilities and all priorities
  environment.etc."syslog.conf".text = ''
    # macOS Syslog Configuration
    # Managed by nix-darwin - do not edit manually
    #
    # Forward ALL logs to remote syslog server
    # Server: ${userConfig.logging.syslog.server}
    # Port: ${toString userConfig.logging.syslog.port}
    # Protocol: ${userConfig.logging.syslog.protocol}

    # Forward all facilities, all priorities to remote server
    *.*		${remoteServer}

    # Also keep local logging intact (default macOS behavior)
    # These are the default macOS syslog rules
    *.notice;authpriv,remoteauth,ftp,install,internal.none	/var/log/system.log
    auth,authpriv.*;remoteauth.crit			/var/log/system.log
    mail.*						/var/log/mail.log
    install.*					/var/log/install.log
  '';

  # Reload syslogd after configuration changes
  # syslogd re-reads its configuration when it receives SIGHUP
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] ============================================"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Syslog Configuration"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] ============================================"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Remote server: ${userConfig.logging.syslog.server}:${toString userConfig.logging.syslog.port} (${userConfig.logging.syslog.protocol})"

    # Send HUP signal to syslogd to reload configuration
    # syslogd is managed by launchd as com.apple.syslogd
    if /usr/bin/pkill -HUP syslogd 2>/dev/null; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Sent SIGHUP to syslogd - configuration reloaded"
    else
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] Could not signal syslogd (may not be running)" >&2
    fi

    # Verify syslogd is running
    if /bin/launchctl print system/com.apple.syslogd >/dev/null 2>&1; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] syslogd service is running"
    else
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] syslogd service not found in launchd" >&2
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Syslog configuration complete"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] ============================================"
  '';
}
