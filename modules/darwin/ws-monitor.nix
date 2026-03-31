# WindowServer Performance Monitor
#
# System-level LaunchDaemon that captures WindowServer performance metrics
# to JSONL every 15 seconds. Runs as root to access system-level compositor
# state and GPU metrics.
#
# Log: /var/log/ws-monitor/ws-monitor.jsonl

{ lib, pkgs, ... }:

let
  logDir = "/var/log/ws-monitor";

  monitorScript = pkgs.writeShellApplication {
    name = "ws-monitor";
    runtimeInputs = with pkgs; [ jq ];
    text = builtins.readFile ./scripts/ws-monitor.sh;
  };
in
{
  # Ensure log directory exists with correct permissions before launchd opens stderr
  system.activationScripts.postActivation.text = lib.mkAfter ''
    /bin/mkdir -p "${logDir}"
    /bin/chmod 755 "${logDir}"
  '';

  # System-level LaunchDaemon — runs as root for full system visibility
  launchd.daemons.ws-monitor = {
    serviceConfig = {
      Label = "com.visicore.ws-monitor";
      ProgramArguments = [ "${monitorScript}/bin/ws-monitor" ];
      StartInterval = 15;
      RunAtLoad = true;
      StandardErrorPath = "${logDir}/ws-monitor.err.log";
    };
  };
}
