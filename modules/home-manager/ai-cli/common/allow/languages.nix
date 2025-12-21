# Programming Language Commands
#
# Auto-approved commands for Python, Node.js, Rust, and their toolchains.
# Imported by allow.nix - do not use directly.

_:

{
  # --- Python ---
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

  # --- Node.js ---
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

  # --- Rust ---
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
}
