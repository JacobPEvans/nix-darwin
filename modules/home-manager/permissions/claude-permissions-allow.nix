# Claude Code Auto-Approved Commands (ALLOW List)
#
# This file defines baseline permissions that Claude can execute without approval.
# Commands are organized by category for easy maintenance.
#
# FILE STRUCTURE:
# - claude-permissions-allow.nix (this file) - Auto-approved commands
# - claude-permissions-ask.nix - Commands requiring user confirmation
# - claude-permissions-deny.nix - Permanently blocked commands
#
# NOTE: These permission lists are kept in sync across Claude, Gemini, and Copilot.
# Currently each AI has separate files. Future improvement: DRY refactor to share
# common command lists across all AI tools.
#
# PRINCIPLE OF LEAST PRIVILEGE:
# - Only include commands with minimal risk in allow list
# - Read-only operations preferred (ls, cat, grep, etc.)
# - No destructive file operations (chmod, rm, cp, mv with wildcards)
# - No arbitrary code execution (osascript, sqlite3, mongosh, npx, docker exec)
# - No cloud infrastructure modification (aws s3 cp/rm, aws ec2 terminate)
# - No Kubernetes cluster modification (kubectl apply/create/delete)
# - Curl limited to GET requests only
# - sed/awk without -i (no in-place file modification)

{ config, ... }:

let
  # Use config.home.username for consistency with other permission files
  username = config.home.username;

  # Core read-only tools (always safe)
  coreReadTools = [
    "Read(**)"
    "Glob(**)"
    "Grep(**)"
  ];

  # Git operations (version control)
  gitCommands = [
    # Status and inspection
    "Bash(git status:*)"
    "Bash(git log:*)"
    "Bash(git diff:*)"
    "Bash(git show:*)"
    "Bash(git blame:*)"
    "Bash(git shortlog:*)"
    "Bash(git describe:*)"
    "Bash(git rev-parse:*)"
    "Bash(git ls-files:*)"
    "Bash(git ls-remote:*)"
    "Bash(git ls-tree:*)"
    "Bash(git cat-file:*)"
    "Bash(git reflog:*)"
    "Bash(git for-each-ref:*)"
    "Bash(git name-rev:*)"
    "Bash(git worktree list:*)"
    # Branch and tag management
    "Bash(git branch:*)"
    "Bash(git checkout:*)"
    "Bash(git switch:*)"
    "Bash(git tag:*)"
    # Staging and committing
    "Bash(git add:*)"
    "Bash(git commit:*)"
    # NOTE: git reset and git restore moved to ask list (potentially destructive)
    # Remote operations
    "Bash(git push:*)"
    "Bash(git pull:*)"
    "Bash(git fetch:*)"
    "Bash(git remote:*)"
    "Bash(git clone:*)"
    # Merging and rebasing
    "Bash(git merge:*)"
    "Bash(git rebase:*)"
    # NOTE: git cherry-pick moved to ask list (can cause conflicts/issues)
    # Stash management
    "Bash(git stash:*)"
    # File operations
    "Bash(git mv:*)"
    # NOTE: git rm moved to ask list (removes files from working tree)
    # Configuration
    "Bash(git config:*)"
    # Maintenance
    "Bash(git gc:*)"
    "Bash(git prune:*)"
    "Bash(git fsck:*)"
  ];

  # GitHub CLI (PR management, issues, etc.)
  githubCommands = [
    "Bash(gh auth status:*)"
    "Bash(gh pr list:*)"
    "Bash(gh pr view:*)"
    "Bash(gh pr create:*)"
    "Bash(gh pr checkout:*)"
    "Bash(gh pr merge:*)"
    "Bash(gh pr diff:*)"
    "Bash(gh pr comment:*)"
    "Bash(gh pr checks:*)"
    "Bash(gh issue list:*)"
    "Bash(gh issue view:*)"
    "Bash(gh issue create:*)"
    "Bash(gh repo view:*)"
    "Bash(gh repo clone:*)"
    "Bash(gh api:*)"
    "Bash(gh api graphql:*)"
    "Bash(gh run list:*)"
    "Bash(gh run view:*)"
    "Bash(gh workflow list:*)"
    "Bash(gh workflow view:*)"
    "Bash(gh release list:*)"
    "Bash(gh release view:*)"
  ];

  # Nix package manager and darwin-rebuild
  nixCommands = [
    "Bash(nix --version:*)"
    "Bash(nix search:*)"
    "Bash(nix search nixpkgs:*)"
    "Bash(nix flake update:*)"
    "Bash(nix flake metadata:*)"
    "Bash(nix flake show:*)"
    "Bash(nix flake check:*)"
    "Bash(nix build:*)"
    "Bash(nix develop:*)"
    "Bash(nix shell:*)"
    "Bash(nix run:*)"
    "Bash(nix eval:*)"
    "Bash(nix-env:*)"
    "Bash(nix-env -q:*)"
    "Bash(nix-env --query:*)"
    "Bash(nix profile:*)"
    "Bash(darwin-rebuild switch:*)"
    "Bash(darwin-rebuild build:*)"
    "Bash(darwin-rebuild --list-generations:*)"
    "Bash(darwin-rebuild --rollback:*)"
  ];

  # Homebrew (fallback package manager)
  homebrewCommands = [
    "Bash(brew list:*)"
    "Bash(brew search:*)"
    "Bash(brew info:*)"
    "Bash(brew --version:*)"
    "Bash(brew doctor:*)"
    "Bash(brew config:*)"
    "Bash(brew outdated:*)"
    "Bash(brew deps:*)"
    "Bash(sudo -u ${username} brew list:*)"
    "Bash(sudo -u ${username} brew search:*)"
    "Bash(sudo -u ${username} brew info:*)"
  ];

  # Modern CLI tools (installed via nixpkgs)
  # These are enhanced alternatives to traditional Unix tools
  modernCliCommands = [
    "Bash(bat:*)"       # Better cat with syntax highlighting
    "Bash(delta:*)"     # Better git diff viewer
    "Bash(eza:*)"       # Modern ls replacement
    "Bash(fd:*)"        # Fast find alternative
    "Bash(fzf:*)"       # Fuzzy finder
    "Bash(htop:*)"      # Interactive process viewer
    "Bash(ncdu:*)"      # NCurses disk usage
    "Bash(tldr:*)"      # Simplified man pages
    "Bash(rg:*)"        # ripgrep (fast grep)
  ];

  # Python ecosystem
  pythonCommands = [
    "Bash(python --version:*)"
    "Bash(python3 --version:*)"
    "Bash(python -m:*)"
    "Bash(python3 -m:*)"
    "Bash(pip list:*)"
    "Bash(pip show:*)"
    "Bash(pip freeze:*)"
    "Bash(pip install:*)"
    "Bash(pip install --user:*)"
    "Bash(pip3 list:*)"
    "Bash(pip3 show:*)"
    "Bash(pip3 install:*)"
    "Bash(poetry --version:*)"
    "Bash(poetry install:*)"
    "Bash(poetry add:*)"
    "Bash(poetry remove:*)"
    "Bash(poetry update:*)"
    "Bash(poetry run:*)"
    "Bash(poetry shell:*)"
    "Bash(poetry show:*)"
    "Bash(pyenv versions:*)"
    "Bash(pyenv install:*)"
    "Bash(pyenv global:*)"
    "Bash(pyenv local:*)"
    "Bash(pytest:*)"
    "Bash(pytest -v:*)"
    "Bash(pytest --collect-only:*)"
  ];

  # JavaScript/TypeScript ecosystem
  # NOTE: npx removed - can execute arbitrary packages from npm registry
  nodeCommands = [
    "Bash(node --version:*)"
    "Bash(npm --version:*)"
    "Bash(npm list:*)"
    "Bash(npm ls:*)"
    "Bash(npm install:*)"
    "Bash(npm ci:*)"
    "Bash(npm run:*)"
    "Bash(npm test:*)"
    "Bash(npm run test:*)"
    "Bash(npm run build:*)"
    "Bash(npm run lint:*)"
    "Bash(npm run dev:*)"
    "Bash(npm run start:*)"
    "Bash(npm outdated:*)"
    "Bash(npm audit:*)"
    "Bash(npm view:*)"
    "Bash(yarn --version:*)"
    "Bash(yarn install:*)"
    "Bash(yarn add:*)"
    "Bash(yarn remove:*)"
    "Bash(yarn run:*)"
    "Bash(pnpm --version:*)"
    "Bash(pnpm install:*)"
    "Bash(pnpm add:*)"
    "Bash(pnpm run:*)"
  ];

  # Rust ecosystem
  rustCommands = [
    "Bash(cargo --version:*)"
    "Bash(cargo build:*)"
    "Bash(cargo test:*)"
    "Bash(cargo run:*)"
    "Bash(cargo check:*)"
    "Bash(cargo fmt:*)"
    "Bash(cargo clippy:*)"
    "Bash(cargo clean:*)"
    "Bash(cargo update:*)"
    "Bash(cargo install:*)"
    "Bash(cargo uninstall:*)"
    "Bash(cargo search:*)"
    "Bash(cargo tree:*)"
    "Bash(rustc --version:*)"
    "Bash(rustup --version:*)"
    "Bash(rustup update:*)"
    "Bash(rustup show:*)"
    "Bash(rustup default:*)"
  ];

  # Docker commands
  # NOTE: Removed docker exec, docker run - these require user approval (in ask list)
  #       These allow arbitrary code execution in containers
  dockerCommands = [
    "Bash(docker --version:*)"
    "Bash(docker ps:*)"
    "Bash(docker images:*)"
    "Bash(docker logs:*)"
    "Bash(docker inspect:*)"
    "Bash(docker start:*)"
    "Bash(docker stop:*)"
    "Bash(docker restart:*)"
    "Bash(docker build:*)"
    "Bash(docker pull:*)"
    "Bash(docker push:*)"
    "Bash(docker tag:*)"
    "Bash(docker compose:*)"
    "Bash(docker info:*)"
    "Bash(docker cp:*)"
  ];

  # Kubernetes commands
  # NOTE: Removed kubectl delete, helm uninstall - these require user approval
  #       These are destructive operations that can break production systems
  kubernetesCommands = [
    "Bash(kubectl version:*)"
    "Bash(kubectl get:*)"
    "Bash(kubectl describe:*)"
    "Bash(kubectl logs:*)"
    "Bash(kubectl port-forward:*)"
    "Bash(kubectl config:*)"
    "Bash(kubectl rollout:*)"
    "Bash(helm version:*)"
    "Bash(helm list:*)"
    "Bash(helm repo:*)"
    "Bash(helm search:*)"
  ];

  # AWS CLI (read-only operations)
  # NOTE: Removed write operations - moved to ask list:
  #       - aws s3 cp/sync (can overwrite files, exfiltrate data)
  #       - aws s3 rm (destructive)
  #       - aws ec2 terminate (destructive)
  #       - aws lambda invoke (can trigger arbitrary Lambda functions)
  # SECURITY: Credential-returning commands are commented out to prevent
  # accidental secret exposure. AI should not have direct credential access.
  # Future: integrate with secure keystore for temporary credentials.
  awsCommands = [
    "Bash(aws --version:*)"
    "Bash(aws sts get-caller-identity:*)"
    "Bash(aws s3 ls:*)"
    "Bash(aws ec2 describe-instances:*)"
    # "Bash(aws ecr get-login-password:*)"  # Returns ECR auth token
    "Bash(aws lambda list-functions:*)"
    "Bash(aws cloudformation list-stacks:*)"
    "Bash(aws cloudformation describe-stacks:*)"
    "Bash(aws logs tail:*)"
    # "Bash(aws ssm get-parameter:*)"  # Can return secrets from Parameter Store
    "Bash(aws dynamodb list-tables:*)"
    "Bash(aws dynamodb scan:*)"
    "Bash(aws dynamodb describe-table:*)"
  ];

  # Terraform (Infrastructure as Code)
  # NOTE: Only read-only and validation commands auto-approved
  # terraform apply/destroy require user approval (in ask list)
  terraformCommands = [
    "Bash(terraform --version:*)"
    "Bash(terraform version:*)"
    "Bash(terraform init:*)"
    "Bash(terraform validate:*)"
    "Bash(terraform fmt:*)"
    "Bash(terraform plan:*)"
    "Bash(terraform show:*)"
    "Bash(terraform state list:*)"
    "Bash(terraform state show:*)"
    "Bash(terraform providers:*)"
    "Bash(terraform output:*)"
    "Bash(terraform graph:*)"
  ];

  # Terragrunt (Terraform wrapper)
  # NOTE: Only read-only and validation commands auto-approved
  # terragrunt apply/destroy require user approval (in ask list)
  terragruntCommands = [
    "Bash(terragrunt --version:*)"
    "Bash(terragrunt version:*)"
    "Bash(terragrunt init:*)"
    "Bash(terragrunt validate:*)"
    "Bash(terragrunt plan:*)"
    "Bash(terragrunt show:*)"
    "Bash(terragrunt state list:*)"
    "Bash(terragrunt state show:*)"
    "Bash(terragrunt output:*)"
    "Bash(terragrunt graph-dependencies:*)"
    "Bash(terragrunt hclfmt:*)"
  ];

  # Database clients (read-focused operations only)
  # NOTE: Removed sqlite3, mongosh - these require user approval for write operations
  #       Keep only read-only commands; full access moved to ask list
  databaseCommands = [
    "Bash(redis-cli --version:*)"
    "Bash(redis-cli ping:*)"
    "Bash(redis-cli info:*)"
    "Bash(redis-cli get:*)"
  ];

  # File operations and text processing (READ-ONLY)
  # NOTE: Strictly read-only operations - no file creation or modification
  # - Removed: chmod, rm, rmdir, cp, mv (require user approval - moved to ask list)
  # - Removed: sed, awk (can modify files with -i flag - moved to ask list)
  # - Removed: mkdir, touch (moved to fileCreationCommands below)
  fileReadCommands = [
    "Bash(ls:*)"
    "Bash(cat:*)"
    "Bash(head:*)"
    "Bash(tail:*)"
    "Bash(less:*)"
    "Bash(more:*)"
    "Bash(wc:*)"
    "Bash(grep:*)"
    "Bash(find:*)"
    "Bash(tree:*)"
    "Bash(pwd:*)"
    "Bash(cd:*)"
    "Bash(diff:*)"
    "Bash(cut:*)"
    "Bash(sort:*)"
    "Bash(uniq:*)"
    "Bash(jq:*)"
    "Bash(yq:*)"
  ];

  # Safe file creation and symlink commands
  # NOTE: These create new files/directories or symlinks
  # - mkdir: Creates directories (fails if exists without -p, safe with -p)
  # - touch: Creates empty files or updates timestamps (non-destructive)
  # - ln: Creates symlinks; ln -sf can overwrite existing symlinks (low risk)
  # - readlink: Read-only, displays symlink target
  fileCreationCommands = [
    "Bash(mkdir:*)"
    "Bash(touch:*)"
    "Bash(ln:*)"
    "Bash(ln -s:*)"
    "Bash(ln -sf:*)"
    "Bash(readlink:*)"
  ];


  # Compression and archiving
  archiveCommands = [
    "Bash(tar -tzf:*)"
    "Bash(tar -xzf:*)"
    "Bash(tar -czf:*)"
    "Bash(tar --disable-copyfile:*)"
    "Bash(zip:*)"
    "Bash(unzip:*)"
    "Bash(gzip:*)"
    "Bash(gunzip:*)"
  ];

  # Network operations (READ-ONLY: GET requests only)
  # NOTE: curl patterns restricted to GET-only to prevent data exfiltration
  # - "curl -s" alone is too permissive (can be followed by -X POST)
  # - Only allow explicit GET patterns
  networkCommands = [
    "Bash(curl -s -X GET:*)"
    "Bash(curl -s --request GET:*)"
    "Bash(curl --silent -X GET:*)"
    "Bash(curl --silent --request GET:*)"
    "Bash(curl -X GET:*)"
    "Bash(curl --request GET:*)"
    "Bash(wget:*)"
    "Bash(ping -c:*)"
    "Bash(nslookup:*)"
    "Bash(dig:*)"
    "Bash(host:*)"
    "Bash(netstat:*)"
    "Bash(lsof -i:*)"
  ];

  # System information (read-only)
  systemCommands = [
    "Bash(whoami:*)"
    "Bash(hostname:*)"
    "Bash(uname:*)"
    "Bash(date:*)"
    "Bash(uptime:*)"
    "Bash(which:*)"
    "Bash(whereis:*)"
    "Bash(env:*)"
    "Bash(printenv:*)"
    "Bash(ps:*)"
    "Bash(top -l 1:*)"
    "Bash(df:*)"
    "Bash(du:*)"
    "Bash(free:*)"
    "Bash(launchctl list:*)"
    "Bash(launchctl print:*)"
  ];

  # Process management (limited)
  processCommands = [
    "Bash(echo:*)"
    "Bash(printf:*)"
    "Bash(test:*)"
    "Bash(source:*)"
    "Bash(export:*)"
    "Bash(alias:*)"
    "Bash(history:*)"
    "Bash(sleep:*)"
    "Bash(true:*)"
    "Bash(false:*)"
  ];

  # macOS specific
  # NOTE: Removed osascript, system_profiler, defaults read to ask list
  #       These pose security risks and are in claude-permissions-ask.nix
  macosCommands = [
    "Bash(sw_vers:*)"
    "Bash(mdls:*)"
    "Bash(mdfind:*)"
    "Bash(pbcopy:*)"
    "Bash(pbpaste:*)"
  ];

  # Claude-specific tools (generally safe)
  claudeTools = [
    "WebSearch"
    "TodoWrite"
    "TodoRead"
  ];

  # WebFetch permissions for documentation and trusted sites
  webFetchCommands = [
    # GitHub and source code
    "WebFetch(domain:github.com)"
    "WebFetch(domain:raw.githubusercontent.com)"
    # Documentation sites
    "WebFetch(domain:docs.orbstack.dev)"
    "WebFetch(domain:docs.github.com)"
    "WebFetch(domain:nix-darwin.github.io)"
    # AI/LLM documentation
    "WebFetch(domain:anthropic.com)"
    "WebFetch(domain:docs.anthropic.com)"
    "WebFetch(domain:google-gemini.github.io)"
    # Infrastructure documentation
    "WebFetch(domain:terraform.io)"
    "WebFetch(domain:developer.hashicorp.com)"
    "WebFetch(domain:proxmox.com)"
    "WebFetch(domain:ubuntu.com)"
    # Development tools
    "WebFetch(domain:graphite.dev)"
    "WebFetch(domain:nixos.org)"
    "WebFetch(domain:nixos.wiki)"
    "WebFetch(domain:www.npmjs.com)"
  ];

in
{
  # Export the complete allow list
  allowList = coreReadTools
    ++ gitCommands
    ++ githubCommands
    ++ nixCommands
    ++ homebrewCommands
    ++ modernCliCommands
    ++ pythonCommands
    ++ nodeCommands
    ++ rustCommands
    ++ dockerCommands
    ++ kubernetesCommands
    ++ awsCommands
    ++ terraformCommands
    ++ terragruntCommands
    ++ databaseCommands
    ++ fileReadCommands
    ++ fileCreationCommands
    ++ archiveCommands
    ++ networkCommands
    ++ systemCommands
    ++ processCommands
    ++ macosCommands
    ++ claudeTools
    ++ webFetchCommands;
}
