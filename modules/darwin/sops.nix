# sops-nix Secret Management
#
# Decrypts age-encrypted secrets from secrets/ to root-only files in /run/secrets
# at activation time. Root reads the age private key from the primary user's
# ~/.config/sops/age/keys.txt — root can access this path on macOS regardless of
# the 0600 mode because DAC does not restrict root.
#
# Key file:  ~/.config/sops/age/keys.txt  (generated once per machine, never committed)
# Public key in .sops.yaml                (committed to git)
# Encrypted secrets in secrets/           (committed to git, safe to be public)
# Decrypted secrets in /run/secrets/      (ephemeral, root:wheel 0400)

{ config, ... }:

let
  userConfig = import ../../lib/user-config.nix;
  rootOnly = {
    owner = "root";
    group = "wheel";
    mode = "0400";
  };
in
{
  sops = {
    age = {
      # Absolute path — expands at Nix eval time, not shell time, so root finds it
      keyFile = "${userConfig.user.homeDir}/.config/sops/age/keys.txt";
      generateKey = false;
      sshKeyPaths = [ ];
    };

    # Age-only. Disable GPG/SSH fallback to fail fast on misconfiguration.
    gnupg.sshKeyPaths = [ ];

    # Individual secret files — each decrypts to /run/secrets/<name>, root:wheel 0400
    secrets = {
      # Cribl Edge enrollment credentials
      # Source: secrets/cribl-edge.yaml (age-encrypted, committed to git)
      CRIBL_ORG_ID = rootOnly // {
        sopsFile = ../../secrets/cribl-edge.yaml;
      };
      CRIBL_WORKSPACE_ID = rootOnly // {
        sopsFile = ../../secrets/cribl-edge.yaml;
      };
      CRIBL_TOKEN = rootOnly // {
        sopsFile = ../../secrets/cribl-edge.yaml;
      };
    };

    # Rendered template: assembles individual secrets into a single KEY=value file
    # consumed by the cribl-edge activation script via awk (no shell eval).
    templates."cribl-edge.env" = rootOnly // {
      content = ''
        CRIBL_ORG_ID=${config.sops.placeholder."CRIBL_ORG_ID"}
        CRIBL_WORKSPACE_ID=${config.sops.placeholder."CRIBL_WORKSPACE_ID"}
        CRIBL_TOKEN=${config.sops.placeholder."CRIBL_TOKEN"}
      '';
    };
  };
}
