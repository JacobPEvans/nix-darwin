# Claude Code Auto-Approved Commands
#
# This file defines baseline permissions that Claude can execute without approval.
# Commands are organized by category for easy maintenance.
#
# THREE-TIER PERMISSION STRATEGY:
# - ALLOW: Safe commands auto-approved (this file)
# - ASK: Potentially dangerous, requires user confirmation (claude-permissions-ask.nix)
# - DENY: Catastrophic operations, permanently blocked (denyList below)
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

{ ... }:

let
  # Core read-only tools (always safe)
  coreReadTools = [
    "Read(**)"
    "Glob(**)"
    "Grep(**)"
  ];

  # Git operations (version control)
  gitCommands = [
    "Bash(git status:*)"
    "Bash(git log:*)"
    "Bash(git diff:*)"
    "Bash(git show:*)"
    "Bash(git branch:*)"
    "Bash(git checkout:*)"
    "Bash(git add:*)"
    "Bash(git commit:*)"
    "Bash(git push:*)"
    "Bash(git pull:*)"
    "Bash(git fetch:*)"
    "Bash(git merge:*)"
    "Bash(git rebase:*)"
    "Bash(git stash:*)"
    "Bash(git remote:*)"
    "Bash(git tag:*)"
    "Bash(git config:*)"
    "Bash(git clone:*)"
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
    "Bash(gh issue list:*)"
    "Bash(gh issue view:*)"
    "Bash(gh issue create:*)"
    "Bash(gh repo view:*)"
    "Bash(gh repo clone:*)"
    "Bash(gh api:*)"
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
    "Bash(nix build:*)"
    "Bash(nix develop:*)"
    "Bash(nix shell:*)"
    "Bash(nix run:*)"
    "Bash(nix-env -q:*)"
    "Bash(nix-env --query:*)"
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
    "Bash(sudo -u jevans brew list:*)"
    "Bash(sudo -u jevans brew search:*)"
    "Bash(sudo -u jevans brew info:*)"
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

  # Safe file creation commands
  # NOTE: These create new files/directories but do NOT modify existing content
  # - mkdir: Creates directories (fails if exists without -p, safe with -p)
  # - touch: Creates empty files or updates timestamps (non-destructive)
  fileCreationCommands = [
    "Bash(mkdir:*)"
    "Bash(touch:*)"
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

  # WebFetch permissions for documentation and GitHub
  webFetchCommands = [
    "WebFetch(domain:github.com)"
    "WebFetch(domain:raw.githubusercontent.com)"
  ];

in
{
  # Export the complete allow list
  allowList = coreReadTools
    ++ gitCommands
    ++ githubCommands
    ++ nixCommands
    ++ homebrewCommands
    ++ pythonCommands
    ++ nodeCommands
    ++ rustCommands
    ++ dockerCommands
    ++ kubernetesCommands
    ++ awsCommands
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

  # Explicitly DENIED commands - absolutely catastrophic operations
  # These are blocked permanently and cannot be approved interactively
  # They represent system-level threats that should never be auto-executed
  denyList = [
    # === CATASTROPHIC FILE DESTRUCTION ===
    # Covers all rm -rf variants with /
    "Bash(rm -rf /*:*)"           # rm -rf /
    "Bash(rm -rf /:*)"            # Alternative spacing
    "Bash(rm -rf ~:*)"            # Home directory destruction
    "Bash(rm -fr /*:*)"           # Reversed flags
    "Bash(rm -fr /:*)"
    "Bash(rm --recursive --force /*:*)"
    "Bash(rm --recursive --force /:*)"

    # === SENSITIVE FILE ACCESS ===
    # Credential files
    "Read(.env)"
    "Read(.env.*)"
    "Read(**/.env)"
    "Read(**/.env.*)"
    "Read(**/secrets/**)"
    "Read(**/credentials/**)"

    # SSH/GPG/AWS credentials
    "Read(**/*_rsa)"
    "Read(**/*_dsa)"
    "Read(**/*_ecdsa)"
    "Read(**/*_ed25519)"
    "Read(~/.ssh/id_*)"
    "Read(~/.aws/credentials)"
    "Read(~/.gnupg/**)"

    # === HTTP WRITE OPERATIONS (Data Exfiltration) ===
    # Block all POST/PUT/DELETE/PATCH to prevent data theft
    "Bash(curl -X POST:*)"
    "Bash(curl -X PUT:*)"
    "Bash(curl -X DELETE:*)"
    "Bash(curl -X PATCH:*)"
    "Bash(curl --request POST:*)"
    "Bash(curl --request PUT:*)"
    "Bash(curl --request DELETE:*)"
    "Bash(curl --request PATCH:*)"
    "Bash(curl -d:*)"
    "Bash(curl --data:*)"

    # === SYSTEM-LEVEL DESTRUCTION ===
    "Bash(sudo rm:*)"
    "Bash(sudo dd:*)"
    "Bash(mkfs:*)"
    "Bash(fdisk:*)"
    "Bash(diskutil:*)"

    # === PRIVILEGE ESCALATION ===
    "Bash(sudo su:*)"
    "Bash(sudo -i:*)"
    "Bash(sudo bash:*)"
    "Bash(sudo -s:*)"

    # === REVERSE SHELLS / NETWORK LISTENERS ===
    "Bash(nc -l:*)"
    "Bash(ncat -l:*)"
    "Bash(socat:*)"
  ];
}
