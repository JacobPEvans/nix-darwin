# Unified AI CLI Allowed Commands
#
# Auto-approved commands organized by category.
# Imported by permissions.nix - do not use directly.

_:

{
  # --- Git Operations ---
  git = {
    read = [
      "git status"
      "git log"
      "git diff"
      "git show"
      "git blame"
      "git shortlog"
      "git describe"
      "git rev-parse"
      "git ls-files"
      "git ls-remote"
      "git ls-tree"
      "git cat-file"
      "git reflog"
      "git for-each-ref"
      "git name-rev"
      "git rev-list"
      "git merge-base"
      "git show-ref"
    ];
    branch = [
      "git branch"
      "git checkout"
      "git switch"
      "git tag"
      "git worktree list"
      "git worktree add"
      "git worktree remove"
      "git worktree prune"
      "git worktree lock"
      "git worktree move"
      "git worktree repair"
      "git worktree unlock"
    ];
    write = [
      "git add"
      "git commit"
      "git stash"
      "git mv"
    ];
    remote = [
      "git push"
      "git pull"
      "git fetch"
      "git remote"
      "git clone"
      "git merge"
      "git rebase"
    ];
    config = [
      "git config"
      "git gc"
      "git prune"
      "git fsck"
    ];
  };

  # --- GitHub CLI ---
  gh = {
    auth = [ "gh auth status" ];
    pr = [
      "gh pr list"
      "gh pr view"
      "gh pr create"
      "gh pr checkout"
      "gh pr merge"
      "gh pr diff"
      "gh pr comment"
      "gh pr checks"
      "gh pr edit"
      "gh pr ready"
    ];
    issue = [
      "gh issue list"
      "gh issue view"
      "gh issue create"
      "gh issue edit"
      "gh issue comment"
    ];
    repo = [
      "gh repo view"
      "gh repo clone"
      "gh repo list"
    ];
    api = [
      "gh api"
      "gh api graphql"
    ];
    ci = [
      "gh run list"
      "gh run view"
      "gh run watch"
      "gh run rerun"
      "gh workflow list"
      "gh workflow view"
    ];
    misc = [
      "gh release list"
      "gh release view"
      "gh search"
      "gh gist view"
      "gh label list"
    ];
  };

  # --- Nix Package Manager ---
  nix = {
    read = [
      "nix --version"
      "nix show-config"
      "nix search"
      "nix search nixpkgs"
      "nix eval"
      "nix path-info"
      "nix why-depends"
      "nix hash"
    ];
    flake = [
      "nix flake update"
      "nix flake metadata"
      "nix flake show"
      "nix flake check"
    ];
    build = [
      "nix build"
      "nix develop"
      "nix shell"
      "nix run"
      "nix repl"
    ];
    store = [
      "nix store ls"
      "nix store path-info"
      "nix store verify"
      "nix store diff-closures"
      "nix-store -q"
      "nix-store --query"
      "nix-store --verify"
      "nix-store --gc"
    ];
    legacy = [
      "nix-env"
      "nix-env -q"
      "nix-env --query"
      "nix profile"
      "nix-shell"
      "nix-instantiate"
      "nix-collect-garbage"
      "nix-prefetch-url"
      "nix-prefetch-git"
      "nix-locate"
      "nix-tree"
      "nix-diff"
    ];
    darwin = [
      "darwin-rebuild switch"
      "darwin-rebuild build"
      "darwin-rebuild --list-generations"
      "darwin-rebuild --rollback"
      "sudo darwin-rebuild"
    ];
    quality = [
      "nixfmt-rfc-style --version"
      "nixfmt"
      "nix fmt"
      "statix check"
      "deadnix"
    ];
  };

  # --- Homebrew ---
  homebrew = [
    "brew list"
    "brew search"
    "brew info"
    "brew --version"
    "brew doctor"
    "brew config"
    "brew outdated"
    "brew deps"
  ];

  # --- File Operations ---
  fileRead = [
    "ls"
    "cat"
    "head"
    "tail"
    "less"
    "more"
    "wc"
    "grep"
    "find"
    "tree"
    "pwd"
    "cd"
    "diff"
    "cut"
    "sort"
    "uniq"
    "jq"
    "yq"
    "file"
    "readlink"
    "sed"
    "awk"
  ];

  fileCreate = [
    "mkdir"
    "touch"
    "ln"
    "ln -s"
    "ln -sf"
  ];

  archive = [
    "tar -tzf"
    "tar -xzf"
    "tar -czf"
    "tar --disable-copyfile"
    "zip"
    "unzip"
    "gzip"
    "gunzip"
  ];

  # --- Modern CLI Tools ---
  modernCli = [
    "bat"
    "delta"
    "eza"
    "fd"
    "fzf"
    "htop"
    "ncdu"
    "tldr"
    "rg"
  ];

  # --- System ---
  system = [
    "whoami"
    "hostname"
    "uname"
    "date"
    "uptime"
    "which"
    "whereis"
    "ps"
    "pgrep"
    "top -l 1"
    "df"
    "du"
    "free"
    "env"
    "printenv"
    "type"
    "time"
    "timeout"
    "hash"
  ];

  macos = [
    "sw_vers"
    "mdls"
    "mdfind"
    "launchctl list"
    "launchctl print"
    "pbcopy"
    "pbpaste"
  ];

  shell = [
    "echo"
    "printf"
    "test"
    "export"
    "alias"
    "history"
    "sleep"
    "true"
    "false"
    "source"
  ];

  # --- Network ---
  network = [
    "curl -s -X GET"
    "curl -s --request GET"
    "curl --silent -X GET"
    "curl --silent --request GET"
    "curl -X GET"
    "curl --request GET"
    "ping -c"
    "nslookup"
    "dig"
    "host"
    "netstat"
    "lsof -i"
    "wget"
  ];

  # --- Languages ---
  python = {
    version = [
      "python --version"
      "python3 --version"
    ];
    run = [
      "python -m"
      "python3 -m"
      "python -m venv"
      "python3 -m venv"
    ];
    pip = [
      "pip list"
      "pip show"
      "pip freeze"
      "pip install"
      "pip install --user"
      "pip3 list"
      "pip3 show"
      "pip3 install"
    ];
    poetry = [
      "poetry --version"
      "poetry run"
      "poetry shell"
      "poetry show"
      "poetry install"
      "poetry add"
      "poetry remove"
      "poetry update"
    ];
    pyenv = [
      "pyenv versions"
      "pyenv global"
      "pyenv local"
      "pyenv install"
    ];
    test = [
      "pytest"
      "pytest -v"
      "pytest --collect-only"
    ];
    venv = [
      "virtualenv"
      "conda info"
      "conda list"
      "conda env list"
      "conda activate"
      "conda deactivate"
      "mamba info"
      "mamba list"
      "mamba env list"
      "micromamba info"
      "micromamba list"
      "micromamba env list"
    ];
  };

  node = {
    version = [
      "node --version"
      "npm --version"
      "yarn --version"
      "pnpm --version"
    ];
    npm = [
      "npm list"
      "npm ls"
      "npm run"
      "npm test"
      "npm run test"
      "npm run build"
      "npm run lint"
      "npm run dev"
      "npm run start"
      "npm outdated"
      "npm audit"
      "npm view"
      "npm install"
      "npm ci"
    ];
    yarn = [
      "yarn run"
      "yarn install"
      "yarn add"
      "yarn remove"
    ];
    pnpm = [
      "pnpm run"
      "pnpm install"
      "pnpm add"
    ];
  };

  rust = {
    cargo = [
      "cargo --version"
      "cargo build"
      "cargo test"
      "cargo run"
      "cargo check"
      "cargo fmt"
      "cargo clippy"
      "cargo clean"
      "cargo update"
      "cargo search"
      "cargo tree"
      "cargo install"
      "cargo uninstall"
    ];
    rustup = [
      "rustc --version"
      "rustup --version"
      "rustup update"
      "rustup show"
      "rustup default"
    ];
  };

  # --- Containers ---
  docker = [
    "docker --version"
    "docker ps"
    "docker images"
    "docker logs"
    "docker inspect"
    "docker start"
    "docker stop"
    "docker restart"
    "docker build"
    "docker pull"
    "docker push"
    "docker tag"
    "docker compose"
    "docker info"
    "docker cp"
    "docker context inspect"
    "docker context ls"
    "docker context show"
    "docker network inspect"
    "docker network ls"
    "docker system df"
    "docker volume inspect"
    "docker volume ls"
  ];

  kubernetes = [
    "kubectl version"
    "kubectl get"
    "kubectl describe"
    "kubectl logs"
    "kubectl port-forward"
    "kubectl config"
    "kubectl rollout"
    "helm version"
    "helm list"
    "helm repo"
    "helm search"
  ];

  # --- Cloud & IaC ---
  aws = [
    "aws --version"
    "aws-vault --version"
    "aws-vault list"
    "aws sts get-caller-identity"
    "aws s3 ls"
    "aws ec2 describe-instances"
    "aws lambda list-functions"
    "aws cloudformation list-stacks"
    "aws cloudformation describe-stacks"
    "aws logs tail"
    "aws dynamodb list-tables"
    "aws dynamodb scan"
    "aws dynamodb describe-table"
  ];

  terraform = [
    "terraform --version"
    "terraform version"
    "terraform init"
    "terraform validate"
    "terraform fmt"
    "terraform plan"
    "terraform show"
    "terraform state list"
    "terraform state show"
    "terraform providers"
    "terraform output"
    "terraform graph"
  ];

  terragrunt = [
    "terragrunt --version"
    "terragrunt version"
    "terragrunt init"
    "terragrunt validate"
    "terragrunt plan"
    "terragrunt show"
    "terragrunt state list"
    "terragrunt state show"
    "terragrunt output"
    "terragrunt graph-dependencies"
    "terragrunt hclfmt"
  ];

  # --- Tools ---
  database = [
    "redis-cli --version"
    "redis-cli ping"
    "redis-cli info"
    "redis-cli get"
  ];

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

  ssh = [
    "ssh-add -l"
    "ssh-add -L"
  ];

  lint = [
    "check-jsonschema"
    "markdownlint-cli2"
    "pre-commit"
    "shellcheck"
  ];

  claude = [
    "claude doctor"
    "claude config list"
    "claude config get"
  ];

  ai = [
    "ollama list"
  ];

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
