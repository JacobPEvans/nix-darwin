# Claude Cookbook Patterns Reference
#
# Documents available patterns from anthropics/claude-cookbooks.
# These are reference patterns for agent workflows, not installed files.
#
# The cookbook contains Jupyter notebooks demonstrating various
# agent patterns and workflows. This file provides a convenient
# reference to what's available.
#
# Source: https://github.com/anthropics/claude-cookbooks

{ config, lib, claude-cookbooks, ... }:

let
  # Agent workflow patterns available in the cookbook
  # Location: patterns/agents/ in the claude-cookbooks repository
  agentPatterns = {
    # Basic workflow patterns
    # Source: patterns/agents/basic_workflows.ipynb
    prompt-chaining = {
      description =
        "Sequential prompts where output of one becomes input to next";
      notebook = "patterns/agents/basic_workflows.ipynb";
      useCase = "Multi-step analysis, document processing pipelines";
    };

    parallelization = {
      description = "Execute multiple independent tasks concurrently";
      notebook = "patterns/agents/basic_workflows.ipynb";
      useCase = "Batch processing, concurrent API calls, data gathering";
    };

    routing = {
      description = "Direct requests to specialized agents based on task type";
      notebook = "patterns/agents/basic_workflows.ipynb";
      useCase = "Task classification, specialized tool selection";
    };

    # Advanced orchestration patterns
    # Source: patterns/agents/orchestrator_workers.ipynb
    orchestrator-workers = {
      description =
        "Coordinator agent manages multiple specialized worker agents";
      notebook = "patterns/agents/orchestrator_workers.ipynb";
      useCase = "Complex workflows, task delegation, result aggregation";
    };

    evaluator-optimizer = {
      description = "Agent evaluates work and iteratively improves results";
      notebook = "patterns/agents/orchestrator_workers.ipynb";
      useCase = "Quality improvement, iterative refinement, optimization";
    };
  };

  # Skills patterns available in the cookbook
  # Location: skills/ in the claude-cookbooks repository
  skillsPatterns = {
    # Skills are reusable capabilities demonstrated in the cookbook
    # Refer to anthropic-skills repository for production-ready skills
    document-generation = {
      description = "Generate structured documents from templates or data";
      location = "skills/document-generation/";
      related = "See anthropic-skills repository for production skills";
    };

    code-analysis = {
      description = "Analyze code quality, patterns, and potential issues";
      location = "skills/code-analysis/";
      related = "See code-review plugin for production implementation";
    };
  };

  # Commands and agents patterns
  # Location: .claude/ in the claude-cookbooks repository
  commandAgentPatterns = {
    review-workflows = {
      description = "PR and issue review workflows with confidence scoring";
      commands = [ "review-pr" "review-pr-ci" "review-issue" ];
      agents = [ "code-reviewer" ];
    };

    notebook-workflows = {
      description = "Jupyter notebook review and validation";
      commands = [ "notebook-review" ];
    };

    validation-workflows = {
      description = "Model and link validation workflows";
      commands = [ "model-check" "link-review" ];
    };
  };

in {
  # Expose pattern documentation for reference
  # This is metadata only - actual notebooks live in claude-cookbooks input
  patterns = {
    inherit agentPatterns skillsPatterns commandAgentPatterns;

    # Helper to get full path to a pattern notebook
    getNotebookPath = pattern: "${claude-cookbooks}/${pattern}";

    # Documentation string for easy reference
    documentation = ''
      Claude Cookbook Patterns Available:

      Agent Patterns:
      ${lib.concatStringsSep "\n"
      (lib.mapAttrsToList (name: pattern: "  - ${name}: ${pattern.description}")
        agentPatterns)}

      Skills Patterns:
      ${lib.concatStringsSep "\n"
      (lib.mapAttrsToList (name: pattern: "  - ${name}: ${pattern.description}")
        skillsPatterns)}

      Command/Agent Patterns:
      ${lib.concatStringsSep "\n"
      (lib.mapAttrsToList (name: pattern: "  - ${name}: ${pattern.description}")
        commandAgentPatterns)}
    '';
  };
}
