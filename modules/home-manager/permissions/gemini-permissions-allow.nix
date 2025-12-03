# Gemini CLI Auto-Approved Commands (ALLOW List / coreTools)
#
# This file defines baseline permissions for Gemini CLI using coreTools.
# Commands are organized by category matching Claude Code structure.
#
# FILE STRUCTURE:
# - gemini-permissions-allow.nix (this file) - Auto-approved commands (coreTools)
# - gemini-permissions-ask.nix - Commands that would require confirmation (reference only)
# - gemini-permissions-deny.nix - Permanently blocked commands (excludeTools)
#
# NOTE: These permission lists are kept in sync across Claude, Gemini, and Copilot.
# Currently each AI has separate files. Future improvement: DRY refactor to share
# common command lists across all AI tools.
#
# NOTE: Gemini CLI does not have an "ask" mode - commands are either allowed (coreTools)
# or blocked (excludeTools). The gemini-permissions-ask.nix file exists for reference
# to keep sync with Claude/Copilot permission structures.
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
    # Status and inspection
    "ShellTool(git status)"
    "ShellTool(git merge-base)"
    "ShellTool(git log)"
    "ShellTool(git diff)"
    "ShellTool(git show)"
    "ShellTool(git blame)"
    "ShellTool(git shortlog)"
    "ShellTool(git describe)"
    "ShellTool(git rev-parse)"
    "ShellTool(git ls-files)"
    "ShellTool(git ls-remote)"
    "ShellTool(git ls-tree)"
    "ShellTool(git cat-file)"
    "ShellTool(git reflog)"
    "ShellTool(git for-each-ref)"
    "ShellTool(git name-rev)"
    "ShellTool(git worktree list)"
    # Branch and tag management
    "ShellTool(git branch)"
    "ShellTool(git checkout)"
    "ShellTool(git switch)"
    "ShellTool(git tag)"
    # Staging and committing
    "ShellTool(git add)"
    "ShellTool(git commit)"
    # NOTE: git reset/restore excluded (potentially destructive, no ask mode in Gemini)
    # Remote operations
    "ShellTool(git push)"
    "ShellTool(git pull)"
    "ShellTool(git fetch)"
    "ShellTool(git remote)"
    "ShellTool(git clone)"
    # Merging and rebasing
    "ShellTool(git merge)"
    "ShellTool(git rebase)"
    # NOTE: git cherry-pick excluded (can cause conflicts, no ask mode in Gemini)
    # Stash management
    "ShellTool(git stash)"
    # File operations
    "ShellTool(git mv)"
    # NOTE: git rm excluded (removes files, no ask mode in Gemini)
    # Configuration
    "ShellTool(git config)"
    # Maintenance
    "ShellTool(git gc)"
    "ShellTool(git prune)"
    "ShellTool(git fsck)"
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
    "ShellTool(gh pr checks)"
    "ShellTool(gh issue list)"
    "ShellTool(gh issue view)"
    "ShellTool(gh issue create)"
    "ShellTool(gh repo view)"
    "ShellTool(gh repo clone)"
    "ShellTool(gh api)"
    "ShellTool(gh api graphql)"
    "ShellTool(gh run list)"
    "ShellTool(gh run view)"
    "ShellTool(gh workflow list)"
    "ShellTool(gh workflow view)"
    "ShellTool(gh release list)"
    "ShellTool(gh release view)"
    # Search operations
    "ShellTool(gh search)"
    # Gist operations
    "ShellTool(gh gist view)"
    # CI/CD watching
    "ShellTool(gh run watch)"
  ];

  # Nix package manager and darwin-rebuild
  nixCommands = [
    "ShellTool(nix --version)"
    "ShellTool(nix search)"
    "ShellTool(nix search nixpkgs)"
    "ShellTool(nix flake update)"
    "ShellTool(nix flake metadata)"
    "ShellTool(nix flake show)"
    "ShellTool(nix flake check)"
    "ShellTool(nix build)"
    "ShellTool(nix develop)"
    "ShellTool(nix shell)"
    "ShellTool(nix run)"
    "ShellTool(nix eval)"
    "ShellTool(nix-env)"
    "ShellTool(nix-env -q)"
    "ShellTool(nix-env --query)"
    "ShellTool(nix profile)"
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

  # Modern CLI tools (installed via nixpkgs)
  # These are enhanced alternatives to traditional Unix tools
  modernCliCommands = [
    "ShellTool(bat)"       # Better cat with syntax highlighting
    "ShellTool(delta)"     # Better git diff viewer
    "ShellTool(eza)"       # Modern ls replacement
    "ShellTool(fd)"        # Fast find alternative
    "ShellTool(fzf)"       # Fuzzy finder
    "ShellTool(htop)"      # Interactive process viewer
    "ShellTool(ncdu)"      # NCurses disk usage
    "ShellTool(tldr)"      # Simplified man pages
    "ShellTool(rg)"        # ripgrep (fast grep)
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
    "ShellTool(npm view)"
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
    "ShellTool(docker cp)"
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
    "ShellTool(aws dynamodb list-tables)"
    "ShellTool(aws dynamodb scan)"
    "ShellTool(aws dynamodb describe-table)"
  ];

  # Terraform (Infrastructure as Code)
  # NOTE: Only read-only and validation commands auto-approved
  terraformCommands = [
    "ShellTool(terraform --version)"
    "ShellTool(terraform version)"
    "ShellTool(terraform init)"
    "ShellTool(terraform validate)"
    "ShellTool(terraform fmt)"
    "ShellTool(terraform plan)"
    "ShellTool(terraform show)"
    "ShellTool(terraform state list)"
    "ShellTool(terraform state show)"
    "ShellTool(terraform providers)"
    "ShellTool(terraform output)"
    "ShellTool(terraform graph)"
  ];

  # Terragrunt (Terraform wrapper)
  # NOTE: Only read-only and validation commands auto-approved
  terragruntCommands = [
    "ShellTool(terragrunt --version)"
    "ShellTool(terragrunt version)"
    "ShellTool(terragrunt init)"
    "ShellTool(terragrunt validate)"
    "ShellTool(terragrunt plan)"
    "ShellTool(terragrunt show)"
    "ShellTool(terragrunt state list)"
    "ShellTool(terragrunt state show)"
    "ShellTool(terragrunt output)"
    "ShellTool(terragrunt graph-dependencies)"
    "ShellTool(terragrunt hclfmt)"
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
    "ShellTool(ln)"
    "ShellTool(ln -s)"
    "ShellTool(ln -sf)"
    "ShellTool(readlink)"
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
    "ShellTool(sleep)"
    "ShellTool(true)"
    "ShellTool(false)"
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
    ++ textProcessingCommands
    ++ archiveCommands
    ++ networkCommands
    ++ systemCommands
    ++ processCommands
    ++ macosCommands
    ++ geminiWebTools;
}
