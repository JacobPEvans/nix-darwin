# Developer Tools and Utilities
#
# Auto-approved commands for databases, version managers, dev environments, etc.
# Imported by allow.nix - do not use directly.

_:

{
  # --- Database Tools ---
  database = [
    "redis-cli --version"
    "redis-cli ping"
    "redis-cli info"
    "redis-cli get"
  ];

  # --- Version Managers ---
  versionManagers = [
    "asdf --version"
    "asdf list"
    "asdf current"
    "asdf info"
    "asdf where"
    "asdf which"
    "asdf plugin list"
    "mise --version"
    "mise list"
    "mise current"
    "mise doctor"
    "mise env"
    "mise where"
    "mise which"
    "rbenv --version"
    "rbenv versions"
    "rbenv version"
    "rbenv which"
    "nodenv --version"
    "nodenv versions"
    "nodenv version"
    "nodenv which"
    "goenv --version"
    "goenv versions"
    "goenv version"
    "nvm --version"
    "nvm list"
    "nvm ls"
    "nvm current"
    "nvm which"
    "fnm --version"
    "fnm list"
    "fnm current"
    "fnm env"
  ];

  # --- Development Environments ---
  devenv = [
    "direnv status"
    "direnv reload"
    "devbox info"
    "devbox list"
    "devbox version"
    "devenv info"
    "devenv version"
    "cachix list"
  ];

  # --- SSH ---
  ssh = [
    "ssh-add -l"
    "ssh-add -L"
  ];

  # --- Linting and Code Quality ---
  lint = [
    "check-jsonschema"
    "markdownlint-cli2"
    "pre-commit"
  ];

  # --- AI CLI Tools ---
  claude = [
    "claude doctor"
    "claude config list"
    "claude config get"
  ];

  # --- OrbStack ---
  orbstack = [
    "orb --help"
    "orb list"
    "orb info"
    "orbctl --help"
    "orbctl doctor"
    "orbctl info"
    "orbctl config get"
    "orbctl version"
  ];
}
