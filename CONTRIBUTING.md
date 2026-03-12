# Contributing to cogni-works

cogni-works has two types of contributions with different terms. Please read the section that applies to you.

## Contributing to Core Plugins

Core plugins are maintained by cogni-works and licensed under AGPL-3.0:

- cogni-workspace
- cogni-tips
- cogni-narrative
- cogni-claims
- cogni-copywriting
- cogni-obsidian
- cogni-portfolio
- cogni-visual
- cogni-teacher

### CLA Requirement

All contributions to core plugins require signing the [Contributor License Agreement](CLA.md). The CLA grants the project owner broad sublicensing rights to support dual-licensing. On your first pull request, the CLA Assistant bot will prompt you to sign.

### Workflow

1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes
4. Write clear commit messages
5. Open a pull request against `main`
6. Confirm your CLA agreement when prompted by the bot

### PR Requirements

- Describe what you changed and why
- Keep PRs focused -- one feature or fix per PR
- Include relevant documentation updates
- Ensure existing functionality is not broken
- Follow the skill naming convention (see below)

### Skill Naming Convention

**Test:** "If a user types `/skill-name`, would they know which plugin it belongs to?"

| Tier | When | Pattern | Examples |
|------|------|---------|----------|
| A — Domain-unique | Only one plugin would ever own this word | Bare name | `propositions`, `synthesize`, `compete` |
| B — Generic verb/noun | Multiple plugins could have this skill | `{domain}-{verb}` | `portfolio-scan`, `tips-catalog`, `copy-reader` |
| C — Cross-plugin | Skill spans two domains | Descriptive compound | `tips-bridge` |

**Order:** always `domain-verb` (not `verb-domain`). This groups skills alphabetically by plugin domain.

**Generic words that always require a prefix:** `setup`, `scan`, `ingest`, `export`, `dashboard`, `verify`, `bridge`, `catalog`, `reader`, `config`, `status`, `analyze`, `resume`

Run `cogni-workspace/scripts/check-skill-names.sh` to validate naming before submitting a PR.

---

## Publishing a Marketplace Plugin

Anyone can publish a plugin to the cogni-works marketplace. You retain full copyright and all rights to your plugin.

### Requirements

- License your plugin under AGPL-3.0 for the marketplace listing
- Include a README with installation and usage instructions
- Follow semantic versioning
- Meet the quality standards described in [MARKETPLACE_TERMS.md](MARKETPLACE_TERMS.md)

### What You Retain

- Full copyright ownership
- The right to dual-license and sell commercial licenses
- Freedom to distribute your plugin elsewhere
- Control over contribution terms for your own plugin

### Submission Process

1. Ensure your plugin meets the [marketplace quality standards](MARKETPLACE_TERMS.md#5-quality-standards)
2. Include an AGPL-3.0 LICENSE file in your repository
3. Submit your plugin for review via a marketplace listing PR
4. Once approved, your plugin will be listed on the marketplace

### Contribution Terms for Your Plugin

You are encouraged to set up your own CLA or contribution terms for PRs to your plugin. See [community-plugin-contributing-template.md](community-plugin-contributing-template.md) for a template.

---

## Code of Conduct

This project follows the [Contributor Covenant v2.1](CODE_OF_CONDUCT.md). Please read it before participating.

---

## Questions?

Open an issue on the [cogni-works repository](https://github.com/cogni-work/cogni-works/issues) if you have questions about contributing.
