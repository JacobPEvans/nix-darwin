# Gemini CLI Auto-Approved Commands
#
# This file defines baseline permissions for Gemini CLI using coreTools.
# Commands are organized by category matching Claude Code structure.
#
# GEMINI CLI PERMISSION MODEL:
# - coreTools: List of tools/commands that can be executed (this file)
# - excludeTools: List of blocked tools/commands (excludeList below)
#
# PRINCIPLE OF LEAST PRIVILEGE:
# - Only include commands with minimal risk in coreTools
# - Read-only operations preferred (ReadFileTool, GlobTool, GrepTool)
# - No destructive file operations
# - No arbitrary code execution
# - Shell commands restricted using ShellTool(command) syntax
#
# NOTE: Gemini CLI uses different tool naming:
# - ReadFileTool instead of Read
# - GlobTool instead of Glob
# - GrepTool instead of Grep
# - ShellTool(cmd) for shell commands with restrictions

{ config, ... }:

let
  # Username for sudo commands (from home-manager config)
  username = config.home.username;

  # Core read-only tools (always safe)
  coreReadTools = [
    "ReadFileTool"
    "GlobTool"
    "GrepTool"
  ];

  # Git operations (version control)
  # Format: ShellTool(git subcommand)
  gitCommands = [
    "ShellTool(git status)"
    "ShellTool(git log)"
    "ShellTool(git diff)"
    "ShellTool(git show)"
    "ShellTool(git branch)"
    "ShellTool(git checkout)"
    "ShellTool(git add)"
    "ShellTool(git commit)"
    "ShellTool(git push)"
    "ShellTool(git pull)"
    "ShellTool(git fetch)"
    "ShellTool(git merge)"
    "ShellTool(git rebase)"
    "ShellTool(git stash)"
    "ShellTool(git remote)"
    "ShellTool(git tag)"
    "ShellTool(git config)"
    "ShellTool(git clone)"
  ];

  # GitHub CLI (PR management, issues, etc.)
  githubCommands = [
    "ShellTool(gh auth status)"
    "ShellTool(gh pr list)"
    "ShellTool(gh pr view)"
    "ShellTool(gh pr create)"
    "ShellTool(gh pr checkout)"
    "ShellTool(gh pr merge)"
    "ShellTool(gh pr diff)"
    "ShellTool(gh pr comment)"
    "ShellTool(gh issue list)"
    "ShellTool(gh issue view)"
    "ShellTool(gh issue create)"
    "ShellTool(gh repo view)"
    "ShellTool(gh repo clone)"
    "ShellTool(gh api)"
    "ShellTool(gh workflow list)"
    "ShellTool(gh workflow view)"
    "ShellTool(gh release list)"
    "ShellTool(gh release view)"
  ];

  # Nix package manager and darwin-rebuild
  nixCommands = [
    "ShellTool(nix --version)"
    "ShellTool(nix search)"
    "ShellTool(nix search nixpkgs)"
    "ShellTool(nix flake update)"
    "ShellTool(nix flake metadata)"
    "ShellTool(nix build)"
    "ShellTool(nix develop)"
    "ShellTool(nix shell)"
    "ShellTool(nix run)"
    "ShellTool(nix-env -q)"
    "ShellTool(nix-env --query)"
    "ShellTool(darwin-rebuild switch)"
    "ShellTool(darwin-rebuild build)"
    "ShellTool(darwin-rebuild --list-generations)"
    "ShellTool(darwin-rebuild --rollback)"
  ];

  # Homebrew (fallback package manager)
  homebrewCommands = [
    "ShellTool(brew list)"
    "ShellTool(brew search)"
    "ShellTool(brew info)"
    "ShellTool(brew --version)"
    "ShellTool(brew doctor)"
    "ShellTool(brew config)"
    "ShellTool(brew outdated)"
    "ShellTool(brew deps)"
    "ShellTool(sudo -u ${username} brew list)"
    "ShellTool(sudo -u ${username} brew search)"
    "ShellTool(sudo -u ${username} brew info)"
  ];

  # Python ecosystem
  pythonCommands = [
    "ShellTool(python --version)"
    "ShellTool(python3 --version)"
    "ShellTool(python -m)"
    "ShellTool(python3 -m)"
    "ShellTool(pip list)"
    "ShellTool(pip show)"
    "ShellTool(pip freeze)"
    "ShellTool(pip install)"
    "ShellTool(pip install --user)"
    "ShellTool(pip3 list)"
    "ShellTool(pip3 show)"
    "ShellTool(pip3 install)"
    "ShellTool(poetry --version)"
    "ShellTool(poetry install)"
    "ShellTool(poetry add)"
    "ShellTool(poetry remove)"
    "ShellTool(poetry update)"
    "ShellTool(poetry run)"
    "ShellTool(poetry shell)"
    "ShellTool(poetry show)"
    "ShellTool(pyenv versions)"
    "ShellTool(pyenv install)"
    "ShellTool(pyenv global)"
    "ShellTool(pyenv local)"
    "ShellTool(pytest)"
    "ShellTool(pytest -v)"
    "ShellTool(pytest --collect-only)"
  ];

  # JavaScript/TypeScript ecosystem
  # NOTE: npx excluded - can execute arbitrary packages
  nodeCommands = [
    "ShellTool(node --version)"
    "ShellTool(npm --version)"
    "ShellTool(npm list)"
    "ShellTool(npm ls)"
    "ShellTool(npm install)"
    "ShellTool(npm ci)"
    "ShellTool(npm run)"
    "ShellTool(npm test)"
    "ShellTool(npm run test)"
    "ShellTool(npm run build)"
    "ShellTool(npm run lint)"
    "ShellTool(npm run dev)"
    "ShellTool(npm run start)"
    "ShellTool(npm outdated)"
    "ShellTool(npm audit)"
    "ShellTool(yarn --version)"
    "ShellTool(yarn install)"
    "ShellTool(yarn add)"
    "ShellTool(yarn remove)"
    "ShellTool(yarn run)"
    "ShellTool(pnpm --version)"
    "ShellTool(pnpm install)"
    "ShellTool(pnpm add)"
    "ShellTool(pnpm run)"
  ];

  # Rust ecosystem
  rustCommands = [
    "ShellTool(cargo --version)"
    "ShellTool(cargo build)"
    "ShellTool(cargo test)"
    "ShellTool(cargo run)"
    "ShellTool(cargo check)"
    "ShellTool(cargo fmt)"
    "ShellTool(cargo clippy)"
    "ShellTool(cargo clean)"
    "ShellTool(cargo update)"
    "ShellTool(cargo install)"
    "ShellTool(cargo uninstall)"
    "ShellTool(cargo search)"
    "ShellTool(cargo tree)"
    "ShellTool(rustc --version)"
    "ShellTool(rustup --version)"
    "ShellTool(rustup update)"
    "ShellTool(rustup show)"
    "ShellTool(rustup default)"
  ];

  # Docker commands
  # NOTE: docker exec, docker run excluded - require user approval
  dockerCommands = [
    "ShellTool(docker --version)"
    "ShellTool(docker ps)"
    "ShellTool(docker images)"
    "ShellTool(docker logs)"
    "ShellTool(docker inspect)"
    "ShellTool(docker start)"
    "ShellTool(docker stop)"
    "ShellTool(docker restart)"
    "ShellTool(docker build)"
    "ShellTool(docker pull)"
    "ShellTool(docker push)"
    "ShellTool(docker tag)"
    "ShellTool(docker compose)"
    "ShellTool(docker info)"
  ];

  # Kubernetes commands
  # NOTE: Destructive operations excluded
  kubernetesCommands = [
    "ShellTool(kubectl version)"
    "ShellTool(kubectl get)"
    "ShellTool(kubectl describe)"
    "ShellTool(kubectl logs)"
    "ShellTool(kubectl port-forward)"
    "ShellTool(kubectl config)"
    "ShellTool(kubectl rollout)"
    "ShellTool(helm version)"
    "ShellTool(helm list)"
    "ShellTool(helm repo)"
    "ShellTool(helm search)"
  ];

  # AWS CLI (read-only operations)
  # SECURITY: Credential-returning commands are commented out to prevent
  # accidental secret exposure. AI should not have direct credential access.
  # Future: integrate with secure keystore for temporary credentials.
  awsCommands = [
    "ShellTool(aws --version)"
    "ShellTool(aws sts get-caller-identity)"
    "ShellTool(aws s3 ls)"
    "ShellTool(aws ec2 describe-instances)"
    # "ShellTool(aws ecr get-login-password)"  # Returns ECR auth token
    "ShellTool(aws lambda list-functions)"
    "ShellTool(aws cloudformation list-stacks)"
    "ShellTool(aws cloudformation describe-stacks)"
    "ShellTool(aws logs tail)"
    # "ShellTool(aws ssm get-parameter)"  # Can return secrets from Parameter Store
  ];

  # Database clients (read-focused operations only)
  databaseCommands = [
    "ShellTool(redis-cli --version)"
    "ShellTool(redis-cli ping)"
    "ShellTool(redis-cli info)"
    "ShellTool(redis-cli get)"
  ];

  # File operations and text processing (READ-ONLY)
  # NOTE: Strictly read-only operations - no file creation or modification
  fileReadCommands = [
    "ShellTool(ls)"
    "ShellTool(cat)"
    "ShellTool(head)"
    "ShellTool(tail)"
    "ShellTool(less)"
    "ShellTool(more)"
    "ShellTool(wc)"
    "ShellTool(grep)"
    "ShellTool(find)"
    "ShellTool(tree)"
    "ShellTool(pwd)"
    "ShellTool(cd)"
    "ShellTool(diff)"
    "ShellTool(cut)"
    "ShellTool(sort)"
    "ShellTool(uniq)"
    "ShellTool(jq)"
    "ShellTool(yq)"
  ];

  # Safe file creation commands
  # NOTE: These create new files/directories but do NOT modify existing content
  fileCreationCommands = [
    "ShellTool(mkdir)"
    "ShellTool(touch)"
  ];

  # Text processing tools
  # NOTE: General sed/awk allowed for read-only text processing
  # In-place editing (sed -i) blocked in excludeTools
  textProcessingCommands = [
    "ShellTool(sed)"
    "ShellTool(awk)"
  ];

  # Compression and archiving
  archiveCommands = [
    "ShellTool(tar -tzf)"
    "ShellTool(tar -xzf)"
    "ShellTool(tar -czf)"
    "ShellTool(tar --disable-copyfile)"
    "ShellTool(zip)"
    "ShellTool(unzip)"
    "ShellTool(gzip)"
    "ShellTool(gunzip)"
  ];

  # Network operations (READ-ONLY: GET requests only)
  networkCommands = [
    "ShellTool(curl -s -X GET)"
    "ShellTool(curl -s --request GET)"
    "ShellTool(curl --silent -X GET)"
    "ShellTool(curl --silent --request GET)"
    "ShellTool(curl -X GET)"
    "ShellTool(curl --request GET)"
    "ShellTool(wget)"
    "ShellTool(ping -c)"
    "ShellTool(nslookup)"
    "ShellTool(dig)"
    "ShellTool(host)"
    "ShellTool(netstat)"
    "ShellTool(lsof -i)"
  ];

  # System information (read-only)
  systemCommands = [
    "ShellTool(whoami)"
    "ShellTool(hostname)"
    "ShellTool(uname)"
    "ShellTool(date)"
    "ShellTool(uptime)"
    "ShellTool(which)"
    "ShellTool(whereis)"
    "ShellTool(env)"
    "ShellTool(printenv)"
    "ShellTool(ps)"
    "ShellTool(top -l 1)"
    "ShellTool(df)"
    "ShellTool(du)"
    "ShellTool(free)"
    "ShellTool(launchctl list)"
    "ShellTool(launchctl print)"
  ];

  # Process management (limited)
  processCommands = [
    "ShellTool(echo)"
    "ShellTool(printf)"
    "ShellTool(test)"
    "ShellTool(source)"
    "ShellTool(export)"
    "ShellTool(alias)"
    "ShellTool(history)"
  ];

  # macOS specific
  macosCommands = [
    "ShellTool(sw_vers)"
    "ShellTool(mdls)"
    "ShellTool(mdfind)"
    "ShellTool(pbcopy)"
    "ShellTool(pbpaste)"
  ];

  # Gemini-specific web tools
  geminiWebTools = [
    "WebFetchTool"
  ];

in
{
  # Export coreTools list (allowed commands)
  coreTools = coreReadTools
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
    ++ textProcessingCommands
    ++ archiveCommands
    ++ networkCommands
    ++ systemCommands
    ++ processCommands
    ++ macosCommands
    ++ geminiWebTools;

  # Explicitly EXCLUDED commands - catastrophic operations
  # These are blocked permanently using excludeTools
  excludeTools = [
    # === CATASTROPHIC FILE DESTRUCTION ===
    "ShellTool(rm -rf /)"
    "ShellTool(rm -rf /*)"
    "ShellTool(rm -rf ~)"
    "ShellTool(rm -fr /)"
    "ShellTool(rm -fr /*)"
    "ShellTool(rm --recursive --force /)"
    "ShellTool(rm --recursive --force /*)"

    # === HTTP WRITE OPERATIONS (Data Exfiltration) ===
    "ShellTool(curl -X POST)"
    "ShellTool(curl -X PUT)"
    "ShellTool(curl -X DELETE)"
    "ShellTool(curl -X PATCH)"
    "ShellTool(curl --request POST)"
    "ShellTool(curl --request PUT)"
    "ShellTool(curl --request DELETE)"
    "ShellTool(curl --request PATCH)"
    "ShellTool(curl -d)"
    "ShellTool(curl --data)"

    # === SYSTEM-LEVEL DESTRUCTION ===
    "ShellTool(sudo rm)"
    "ShellTool(sudo dd)"
    "ShellTool(mkfs)"
    "ShellTool(fdisk)"
    "ShellTool(diskutil)"

    # === PRIVILEGE ESCALATION ===
    "ShellTool(sudo su)"
    "ShellTool(sudo -i)"
    "ShellTool(sudo bash)"
    "ShellTool(sudo -s)"

    # === REVERSE SHELLS / NETWORK LISTENERS ===
    "ShellTool(nc -l)"
    "ShellTool(ncat -l)"
    "ShellTool(socat)"

    # === ARBITRARY CODE EXECUTION ===
    "ShellTool(npx)"
    "ShellTool(docker exec)"
    "ShellTool(docker run)"
    "ShellTool(osascript)"
    "ShellTool(sqlite3)"
    "ShellTool(mongosh)"

    # === DESTRUCTIVE FILE OPERATIONS ===
    "ShellTool(chmod)"
    "ShellTool(rm)"
    "ShellTool(rmdir)"
    "ShellTool(cp)"
    "ShellTool(mv)"

    # === IN-PLACE FILE MODIFICATION ===
    # sed/awk general use allowed in coreTools for text processing
    # Only block the destructive in-place editing variants
    "ShellTool(sed -i)"
    "ShellTool(sed --in-place)"

    # === CLOUD INFRASTRUCTURE DESTRUCTION ===
    "ShellTool(aws s3 cp)"
    "ShellTool(aws s3 sync)"
    "ShellTool(aws s3 rm)"
    "ShellTool(aws ec2 run-instances)"
    "ShellTool(aws ec2 terminate-instances)"
    "ShellTool(aws lambda invoke)"
    "ShellTool(aws cloudformation delete-stack)"

    # === KUBERNETES CLUSTER MODIFICATION ===
    "ShellTool(kubectl apply)"
    "ShellTool(kubectl create)"
    "ShellTool(kubectl delete)"
    "ShellTool(kubectl set)"
    "ShellTool(kubectl patch)"
    "ShellTool(helm install)"
    "ShellTool(helm upgrade)"
    "ShellTool(helm uninstall)"
  ];
}
