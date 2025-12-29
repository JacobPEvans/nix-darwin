# Crush Configuration
#
# Comprehensive configuration for Crush AI coding agent (by Charmbracelet).
# Imported by home.nix for clean separation of AI CLI configs.
#
# Crush is an open-source, provider-agnostic AI coding agent:
# - Works with Claude, OpenAI, Google, Groq, or local models
# - Terminal-based TUI with multi-model switching mid-session
# - MCP (Model Context Protocol) server support for extensibility
# - LSP integration for code intelligence
# - Agent Skills standard support
# - Cross-platform: macOS, Linux, Windows, FreeBSD, NetBSD, OpenBSD
# - MIT licensed
#
# Configuration file: ~/.config/crush/crush.json
# Reference: https://github.com/charmbracelet/crush
#
# Nix installation:
# - numtide/llm-agents.nix: nix run github:numtide/llm-agents.nix#crush
# - Direct: nix run github:numtide/nix-ai-tools#crush

{
  config,
  lib,
  pkgs,
  ai-assistant-instructions ? null,
  ...
}:

let
  # Crush settings object
  # Full configuration reference: https://github.com/charmbracelet/crush
  # Configuration priority: .crush.json > crush.json > ~/.config/crush/crush.json
  settings = {
    # Theme (auto follows terminal theme, or: "dark", "light")
    theme = "auto";

    # Default provider and model configuration
    # Supports: anthropic, openai, google, groq, openrouter, bedrock, azure, ollama
    # API keys read from environment variables
    providers = {
      anthropic = {
        # ANTHROPIC_API_KEY environment variable
        default_model = "claude-sonnet-4-20250514";
      };
      openai = {
        # OPENAI_API_KEY environment variable
        default_model = "gpt-4.1";
      };
      google = {
        # GOOGLE_API_KEY or GEMINI_API_KEY environment variable
        default_model = "gemini-2.5-flash";
      };
      ollama = {
        # Local Ollama server
        default_model = "llama3.3";
        base_url = "http://localhost:11434";
      };
    };

    # MCP (Model Context Protocol) Servers
    # Extend Crush with external tools and integrations
    # Reference: https://github.com/charmbracelet/crush#mcps
    mcps = {
      # Bitwarden secrets management
      # bitwarden = {
      #   command = "${homeDir}/.npm-packages/bin/mcp-server-bitwarden";
      #   args = [];
      # };

      # Filesystem access (example)
      # filesystem = {
      #   command = "npx";
      #   args = ["-y" "@modelcontextprotocol/server-filesystem" homeDir];
      # };
    };

    # LSP (Language Server Protocol) configuration
    # Provides code context and intelligence
    # Reference: https://github.com/charmbracelet/crush#lsps
    lsps = {
      # Go
      # go = {
      #   command = "gopls";
      #   args = [];
      # };

      # Nix (nil language server)
      # nix = {
      #   command = "nil";
      #   args = [];
      # };

      # TypeScript/JavaScript
      # typescript = {
      #   command = "typescript-language-server";
      #   args = ["--stdio"];
      # };
    };

    # Permission settings
    # Controls what tools can execute without prompting
    permissions = {
      # Allow specific shell commands without prompting
      # shell_allowlist = ["git status" "git diff" "ls" "cat"];

      # Allow all commands (use with caution, or use --yolo flag)
      # yolo = false;
    };

    # Attribution settings for commit messages
    attribution = {
      # Add trailer to commit messages
      enabled = true;
      # Trailer format: "AI-assisted-by: Crush"
      trailer = "AI-assisted-by";
      value = "Crush (charmbracelet.sh)";
    };
  };

  # Generate pretty-printed JSON using a derivation with jq
  settingsJson =
    pkgs.runCommand "crush.json"
      {
        nativeBuildInputs = [ pkgs.jq ];
        json = builtins.toJSON settings;
        passAsFile = [ "json" ];
      }
      ''
        jq '.' "$jsonPath" > $out
      '';
in
{
  # XDG config path: ~/.config/crush/crush.json
  ".config/crush/crush.json".source = settingsJson;
}
