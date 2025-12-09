# Claude Code Components
#
# Manages commands, agents, and skills from various sources:
# - Flake inputs (immutable, from Nix store)
# - Local files (direct symlinks)
# - Live repos (mkOutOfStoreSymlink for updates without rebuild)
{ config, lib, ... }:

let
  cfg = config.programs.claude;

  # Helper to create file entries from component list
  mkComponentFiles = type: components:
    builtins.listToAttrs (map (c: {
      name = ".claude/${type}s/${c.name}.md";
      value = { source = c.source; };
    }) components);

  # Helper for live repo symlinks
  mkLiveRepoSymlinks = type: repo: names:
    if repo == null then
      { }
    else
      builtins.listToAttrs (map (name: {
        name = ".claude/${type}s/${name}.md";
        value = {
          source = config.lib.file.mkOutOfStoreSymlink
            "${repo}/.ai-instructions/${type}s/${name}.md";
        };
      }) names);

  # Helper for local file symlinks
  mkLocalSymlinks = type: locals:
    lib.mapAttrs' (name: path:
      lib.nameValuePair ".claude/${type}s/${name}.md" { source = path; })
    locals;

in {
  config = lib.mkIf cfg.enable {
    home.file =
      # Commands
      mkComponentFiles "command" cfg.commands.fromFlakeInputs
      // mkLocalSymlinks "command" cfg.commands.local
      // mkLiveRepoSymlinks "command" cfg.commands.fromLiveRepo
      cfg.commands.liveRepoCommands
      # Agents
      // mkComponentFiles "agent" cfg.agents.fromFlakeInputs
      // mkLocalSymlinks "agent" cfg.agents.local
      # Skills
      // mkComponentFiles "skill" cfg.skills.fromFlakeInputs
      // mkLocalSymlinks "skill" cfg.skills.local;
  };
}
