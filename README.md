# skills

Shareable [Claude Code](https://claude.com/claude-code) skills, packaged as a plugin marketplace.

## Install

```
/plugin marketplace add AubreyKilian/skills
/plugin install design-prep@aubrey-public-skills
/plugin install engineering@aubrey-public-skills
```

If your environment does not permit external marketplaces, copy a skill directory from `skills/` into your project's `.claude/skills/` instead. Every skill here is self-contained, except those in the `engineering` plugin, which call [Matt Pocock's skills](https://github.com/mattpocock/skills).

## Plugins

| Plugin | Skills | What it does |
|---|---|---|
| `design-prep` | `/adversarial-architect` | Technical-prep skills for the design phase of an issue or ticket. |
| `engineering` | `/implement-issues` | Implementation skills that build on Matt Pocock's engineering skills. |

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

### `/implement-issues`

Implements an ordered list of separately written issues, one after another, on a single integration branch. Each issue gets a fresh implementer subagent in its own worktree, a code review on its own branch, and lands as one squash commit, so a human can review each issue in isolation. At the end it marks one PR ready for review, closing every landed issue.

A sequential variant of Matt Pocock's `/implement-spec`, for issues that are not tickets of one spec. It never reorders the list. An issue that fails, or whose seams cannot be inferred from its acceptance criteria, is skipped together with the issues it blocks, and the run continues.

Requires the [`mattpocock-skills`](https://github.com/mattpocock/skills) plugin (`tdd`, `code-review`, `pr`) and a tracker configured with `/setup-matt-pocock-skills`. User-invoked only:

```
/implement-issues #12 #15 #9
```

## Recipes

Recipes are setup guides written for a Claude Code session to follow, with example code. They are not plugins: each one changes your own config (hooks, status line, settings), so Claude adapts it to your setup instead of installing a fixed copy. To use one, give Claude the link and ask it to set it up.

| Recipe | What it does |
|---|---|
| [`usage-gate`](recipes/usage-gate/README.md) | Blocks subagent spawns when your 5-hour or 7-day usage passes a threshold, then pauses the session until the limit resets (including early resets) and carries on. |
