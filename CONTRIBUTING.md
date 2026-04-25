# Contributing

Thanks for your interest. This repo is mirrored from a private monorepo, so contributions need light coordination:

- **Small fixes (typos, copy tweaks):** Open a PR against `main`. We cherry-pick it upstream so the change survives the next sync.
- **New skills or larger changes:** Open an [issue](https://github.com/clamp-sh/analytics-skills/issues) describing the idea first. If accepted, we'll build it upstream with credit.

## Structure

Each skill lives under `skills/<name>/SKILL.md`. See the [Agent Skills spec](https://agentskills.io/) for the file format.

## Style rules

- Front-load the key use case in the skill `description`. The first ~200 characters decide whether Claude loads it.
- Keep `SKILL.md` under 400 lines. Move long reference tables into sibling `.md` files.
- Methodology first, tool names second. A skill that only works with one analytics product is less valuable than one that works everywhere.
- No em dashes.

## Adding a new skill

1. Create `skills/<skill-name>/SKILL.md` with YAML frontmatter. Required: `name` (lowercase with hyphens, matching the directory) and `description`. Optional: `when_to_use`.
2. Keep combined `description` + `when_to_use` under ~1,500 characters. Claude truncates the skill listing at 1,536.
3. Test locally with `claude --plugin-dir .`, then run `/reload-plugins` and check that your skill appears.

## Releases

Versions are bumped by hand in `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (both the `metadata.version` and the plugin entry), and `.codex-plugin/plugin.json`, with a matching `CHANGELOG.md` entry. The sync workflow creates a GitHub release automatically when the version bumps.
