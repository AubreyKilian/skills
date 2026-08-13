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

#### Optional: surface it automatically after `/speckit-plan`

If your repo uses [Spec Kit](https://github.com/github/spec-kit), you can have every `/speckit-plan` run end by offering this skill. The completed plan is the natural review target: it is the first artifact that states the technical approach and the files it lands on, and the last moment a surviving objection is cheap — no tasks exist yet to go stale.

Add this entry to `.specify/extensions.yml` under `hooks.after_plan`, after any existing entries (so the git auto-commit hook, if present, commits the plan first and a re-plan has a clean point to return to):

```yaml
hooks:
  after_plan:
  # ... existing entries (e.g. the git extension's auto-commit) ...
  - extension: design-prep
    command: adversarial.architect
    enabled: true
    optional: true
    prompt: "Run the adversarial architect against this plan?"
    description: "Adversarial design review of the completed plan"
    condition: null
```

How it works: Spec Kit command skills read `hooks.after_plan` when they finish and turn each command name into a slash command by replacing dots with hyphens — `adversarial.architect` becomes `/adversarial-architect`. With `optional: true` the agent shows the prompt and **you** type the command, which is exactly what this skill's user-invoked-only design expects.

Two caveats:

- **Keep `optional: true`.** With `optional: false` the agent tries to execute the command itself, and this skill's `disable-model-invocation: true` frontmatter refuses model invocation — the hook would dead-end. Automatic execution requires removing that line from the skill's `SKILL.md` in your installed copy; only do that deliberately, since it also re-opens organic invocation everywhere else.
- **This is a hand-maintained entry, not an installed Spec Kit extension.** The `extension: design-prep` field is display-only here. `specify` CLI extension operations may rewrite `extensions.yml`; re-check the entry after running them.

If a surviving objection changes the plan, feed the constraint back as input to a `/speckit-plan` re-run rather than editing `plan.md` — the plan command blank-slates its file from the template on every run, so hand-edits do not survive regeneration. The durable homes for a finding are the work item (issue or ticket comment) and your decision records.
