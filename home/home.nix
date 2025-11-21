{ config, pkgs, ... }:

{
  home.stateVersion = "24.05";

  # VS Code configuration
  ### WILL OVERWRITE ANYTHING LOCAL ###
  programs.vscode = {
    enable = true;
    userSettings = {
      "editor.formatOnSave" = true;
    }
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

    # Init content - for custom functions and scripts
    initContent = ''
      # Set tabs to 2 spaces
      tabs -2

      # gitmd function - merge and delete branch
      gitmd() {
        # $1 - Target Branch
        # $2 - Source Branch

        # Exit on failure
        set -e

        if [[ "$2" == "main" ]]; then
          echo "ERROR: Cannot delete main branch"
          return 1
        fi

        git checkout "$1"
        git merge "$2"
        git branch -D "$2"
      }

      # Session logging
      if [ -z "$SCRIPT_SESSION" ]; then
        export SCRIPT_SESSION=1
        script -r ~/logs/terminal_$(date +%Y-%m-%d_%H-%M).log
      fi

      # Clean up .DS_Store files
      find ~/.config/  -name ".DS_Store" -depth -exec rm {} \; 2>/dev/null
      find ~/git/      -name ".DS_Store" -depth -exec rm {} \; 2>/dev/null
      find ~/obsidian/ -name ".DS_Store" -depth -exec rm {} \; 2>/dev/null
    '';
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
