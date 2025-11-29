# Shell Aliases
#
# Organized by category. Imported by home.nix for programs.zsh.shellAliases
#
# SUDO REQUIREMENTS:
# - Commands that modify system state (darwin-rebuild) REQUIRE sudo
# - Commands that read/inspect (docker ps, git status) do NOT need sudo
# - User config files (~/.config) should NOT use sudo
#
# Platform: macOS (BSD ls flags used)

{
  # ===========================================================================
  # Directory Listing (macOS/BSD ls)
  # ===========================================================================
  # -a: show hidden files
  # -h: human-readable sizes
  # -l: long format
  # -F: append type indicator (/ for dirs, * for executables)
  # -G: colorized output (macOS BSD ls)
  # -D: date format (macOS BSD ls)
  ll = "ls -ahlFG -D '%Y-%m-%d %H:%M:%S'";
  llt = "ls -ahltFG -D '%Y-%m-%d %H:%M:%S'";  # sorted by time
  lls = "ls -ahlsFG -D '%Y-%m-%d %H:%M:%S'";  # show size

  # ===========================================================================
  # Docker (no sudo needed - user in docker group)
  # ===========================================================================
  dps = "docker ps -a";         # List all containers
  dcu = "docker compose up -d"; # Start compose stack detached
  dcd = "docker compose down";  # Stop compose stack

  # ===========================================================================
  # Nix / Darwin
  # ===========================================================================
  # REQUIRES SUDO: darwin-rebuild modifies system-level configurations
  # This activates both system (nix-darwin) and user (home-manager) configs
  d-r = "sudo darwin-rebuild switch --flake ~/.config/nix#default";

  # NO SUDO: These just read/inspect
  # nix-shell, nix develop, nix build - work as user
  # nix flake update - works as user (updates flake.lock)

  # ===========================================================================
  # Python
  # ===========================================================================
  # Use macOS system Python 3 (no sudo needed)
  python = "python3";

  # ===========================================================================
  # Archive (macOS-friendly tar)
  # ===========================================================================
  # --disable-copyfile: don't include macOS resource forks
  # --exclude='.DS_Store': skip Finder metadata files
  tgz = "tar --disable-copyfile --exclude='.DS_Store' -czf";
}
