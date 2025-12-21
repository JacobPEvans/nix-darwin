# Gemini Custom Commands Adapter
#
# Automatically generates Gemini CLI custom commands from shared Markdown definitions.
# Reads from ai-assistant-instructions/agentsmd/commands/*.md
# Returns home.file entries for ~/.gemini/commands/*.toml
#
# This allows maintaining a single source of truth in agentsmd for both Claude and Gemini.

{ lib, ai-assistant-instructions, ... }:

let
  # Path to shared commands directory in the flake input
  commandsDir = "${ai-assistant-instructions}/agentsmd/commands";

  # Helper to process a single Markdown command file into a Gemini TOML file
  processCommandFile =
    fileName:
    let
      filePath = "${commandsDir}/${fileName}";
      fileContent = builtins.readFile filePath;

      # Basic frontmatter/content splitter
      # Assumes standard Jekyll/Claude style frontmatter:
      # ---
      # key: value
      # ---
      # Content...
      parts = lib.splitString "---" fileContent;

      # indices: [0] = empty before first ---, [1] = frontmatter, [2+] = content
      hasFrontmatter = (builtins.length parts) >= 3;

      frontmatterRaw = if hasFrontmatter then builtins.elemAt parts 1 else "";
      contentRaw =
        if hasFrontmatter then lib.concatStringsSep "---" (lib.drop 2 parts) else fileContent;

      # Extract description from frontmatter
      # Looks for "description: text" line
      descLine = lib.findFirst (l: lib.hasPrefix "description:" (lib.trim l)) null (
        lib.splitString "\n" frontmatterRaw
      );

      description =
        if descLine != null then
          lib.trim (lib.removePrefix "description:" (lib.trim descLine))
        else
          "Custom command generated from ${fileName}";

      # Generate Gemini TOML format
      # We use multi-line string for the command content
      # NOTE: We escape double quotes in description if any (basic)
      safeDescription = lib.replaceStrings [ "\"" ] [ "\\\"" ] description;

      tomlContent = ''
        description = "${safeDescription}"
        command = """
        ${lib.trim contentRaw}
        """
      '';

      # Output filename: replace .md extension with .toml
      outName = lib.replaceStrings [ ".md" ] [ ".toml" ] fileName;
    in
    {
      name = ".gemini/commands/${outName}";
      value = {
        text = tomlContent;
      };
    };

  # Filter for Markdown files in the commands directory
  commandFiles =
    if builtins.pathExists commandsDir then
      builtins.attrNames (
        lib.filterAttrs (n: v: v == "regular" && lib.hasSuffix ".md" n) (
          builtins.readDir commandsDir
        )
      )
    else
      [ ];

in
# Return an attribute set of home.file entries
builtins.listToAttrs (map processCommandFile commandFiles)
