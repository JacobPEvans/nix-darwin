{ config, pkgs, ... }:

{
  home.stateVersion = "24.05";

  # VS Code configuration
  ### WILL OVERWRITE ANYTHING LOCAL ###
  programs.vscode = {
    enable = true;
    profiles.default.userSettings = {
      "editor.formatOnSave" = true;
    };
  };

  # Shell configuration
  programs.zsh = {
    enable = true;

    ## Environment variables
    #sessionVariables = {
    #  PATH = "/opt/homebrew/opt/python@3.12/bin:$PATH";
    #};

    # Aliases from your .zshrc
    shellAliases = {
      # Everyday shell aliases
      ll = "ls -ahlFG -D '%Y-%m-%d %H:%M:%S'";
      llt = "ls -ahltFG -D '%Y-%m-%d %H:%M:%S'";
      lls = "ls -ahlsFG -D '%Y-%m-%d %H:%M:%S'";

      # Python aliases
      python3 = "eval $(which python3.12)";
      pip3 = "eval $(which pip3.12)";
      python = "eval $(which python3.12)";
      pip = "eval $(which pip3.12)";

      # Tar alias for Mac
      tgz = "tar --disable-copyfile --exclude='.DS_Store' -czf";
    };

    # Init content - source modular shell configuration files
    # Files are sourced in order; session-logging.zsh MUST be last
    initContent = ''
      # Load function libraries
      source ${./zsh/git-functions.zsh}
      source ${./zsh/docker-functions.zsh}

      # macOS-specific setup and cleanup
      source ${./zsh/macos-setup.zsh}

      # Session logging MUST be last (takes over terminal)
      source ${./zsh/session-logging.zsh}
    '';
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
