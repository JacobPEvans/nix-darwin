# Unified AI CLI Allowed Commands
#
# Auto-approved commands organized by category.
# Imported by permissions.nix - do not use directly.
#
# ORGANIZATION:
# Large permission lists split into category-specific files in allow/ directory.
# This keeps each file under 200 lines and makes it easier to find/update commands.
#
# CATEGORIES:
# - git.nix: Git and GitHub CLI operations
# - nix.nix: Nix package manager and Homebrew
# - languages.nix: Python, Node.js, Rust toolchains
# - containers.nix: Docker and Kubernetes
# - cloud.nix: AWS, Terraform, Terragrunt
# - tools.nix: Database, version managers, dev environments
# - system.nix: File operations, system info, network

_:

let
  # Import all category-specific permission files
  git = import ./allow/git.nix { };
  nix = import ./allow/nix.nix { };
  languages = import ./allow/languages.nix { };
  containers = import ./allow/containers.nix { };
  cloud = import ./allow/cloud.nix { };
  tools = import ./allow/tools.nix { };
  system = import ./allow/system.nix { };
in

# Merge all categories into a single attribute set
git // nix // languages // containers // cloud // tools // system
