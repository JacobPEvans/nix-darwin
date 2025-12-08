# Claude Skills Configuration
#
# Manages skills from anthropics/skills repository.
# Skills are reusable capabilities like document generation, analysis, etc.
#
# Strategy:
# 1. Skills are organized by category in the upstream repo
# 2. We copy selected skills to ~/.claude/skills/
# 3. Claude Code auto-discovers skills in this directory
#
# Available skill categories:
# - document-generation: Create structured documents
# - analysis: Data and code analysis capabilities
# - automation: Workflow automation skills

{ config, lib, anthropic-skills, ... }:

let
  # Skills to install from the anthropics/skills repository
  # Each skill provides specific capabilities to Claude Code
  #
  # Available skills (examples - check repo for full list):
  #   - document-generator: Generate well-structured documents
  #   - code-analyzer: Analyze code patterns and quality
  #   - data-processor: Process and transform data
  #
  # Note: The actual skill names depend on the repository structure.
  # This is a template that should be updated based on the actual
  # anthropics/skills repository contents.
  selectedSkills = [
    # Document generation skills
    # "document-generator"

    # Analysis skills
    # "code-analyzer"

    # Automation skills
    # "workflow-automator"
  ];

  # Helper function to create file entries for skills
  # Creates ~/.claude/skills/<skill-name>.md entries
  mkSkillFileEntries = skills:
    builtins.listToAttrs (map (skill: {
      name = ".claude/skills/${skill}.md";
      value = { source = "${anthropic-skills}/skills/${skill}.md"; };
    }) skills);

in {
  # Home-manager file entries for skills
  # These copy skill files from the anthropics/skills repo to ~/.claude/skills/
  #
  # Note: Currently no skills are enabled by default.
  # Uncomment skills in selectedSkills list above to enable them.
  files = mkSkillFileEntries selectedSkills;

  # Expose the skills configuration for potential use by other modules
  skillsConfig = {
    inherit selectedSkills;
    skillsDirectory = ".claude/skills";
  };
}
