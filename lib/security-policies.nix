# Security Policies
#
# Universal security settings that apply to ALL systems (macOS, Linux, Windows).
# These are enforced at the system level and cannot be overridden by users.
#
# Each OS-specific module imports these and writes to the appropriate location:
# - macOS/Linux: /etc/gitconfig
# - Windows: C:\ProgramData\Git\config (when supported)

{
  # ==========================================================================
  # Git Security Policies
  # ==========================================================================
  # These settings enforce security best practices for all git operations.
  # User-specific settings (like which GPG key to use) are in home-manager.

  git = {
    # The actual gitconfig content to write to /etc/gitconfig
    systemConfig = ''
      [commit]
        gpgSign = true
      [tag]
        gpgSign = true
      [transfer]
        fsckObjects = true
      [fetch]
        fsckObjects = true
      [receive]
        fsckObjects = true
    '';
  };
}
