# skills

Shareable [Claude Code](https://claude.com/claude-code) skills, packaged as a plugin marketplace.

## Install

```
/plugin marketplace add AubreyKilian/skills
/plugin install design-prep@aubrey-public-skills
```

If your environment does not permit external marketplaces, copy a skill directory from `skills/` into your project's `.claude/skills/` instead — every skill here is self-contained by design.

## Plugins

| Plugin | Skills | What it does |
|---|---|---|
| `design-prep` | `/adversarial-architect` | Technical-prep skills for the design phase of an issue or ticket. |

## Skills

### `/adversarial-architect`

Dispatches a fresh, read-only reviewer that argues **against** a design you have just settled, then answers whether building it would establish a new convention in your codebase. Run it at the end of a design conversation, before implementation starts — while the design is still cheap to change.

User-invoked only: it never fires on its own. Repo-agnostic and language-agnostic.
