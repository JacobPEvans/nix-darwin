# Contributing

Thanks for considering contributing. It's just me here, so any help is genuinely appreciated.

## The Short Version

1. Fork it
2. Create your feature branch (`git checkout -b feature/cool-thing`)
3. Commit your changes (`git commit -m 'Add some cool thing'`)
4. Push to the branch (`git push origin feature/cool-thing`)
5. Open a Pull Request

That's it. I'm not picky.

## Reporting Issues

Found a bug? Something unclear? Open an issue. Describe what you expected, what happened instead, and any relevant context.

## Pull Requests

### Before You Start

- Check if there's already an issue or PR for what you're planning
- For big changes, maybe open an issue first to discuss

### Code Style

This repo has markdown linting via `markdownlint-cli2`. Run it locally:

```bash
markdownlint-cli2 "**/*.md"
```

For Nix code, follow existing patterns. Comments are encouraged - this config is meant to be educational.

### Commit Messages

Use conventional commits if you remember:

- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `refactor:` for code changes that don't add features or fix bugs

But honestly, as long as your commit message explains what you did, we're good.

## What Gets Accepted

Pretty much anything that:

- Improves the documentation
- Adds useful Nix modules or patterns
- Fixes bugs or typos
- Makes the codebase more maintainable

## What Might Not Get Accepted

- Breaking changes without discussion
- Removing comments (they're there for learning)
- Changes that make the config significantly more complex without clear benefit

## Development Setup

1. Clone the repo
2. Make changes
3. Test with `nix flake check`
4. Commit and push

That's the whole setup. Nix handles the rest.

## Questions?

Open an issue. I'll respond when I can.

---

*Thanks for reading this far. Most people don't.*
