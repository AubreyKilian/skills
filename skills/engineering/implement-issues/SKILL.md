---
name: implement-issues
description: "Implement an ordered list of separate issues, one after another, each landing as one commit on a single integration branch."
disable-model-invocation: true
---

You have been provided an ordered list of issues: issue references, or a pointer to a file or parent issue that lists them. The issues were written separately; there is no spec. **The order is authoritative.** Never reorder, regroup or drop an issue.

The issue tracker should have been provided to you. If not, tell the user to run `/setup-matt-pocock-skills`.

The goal is a single **integration branch** with **one commit per landed issue**, so a human can review each issue in isolation.

You are the **orchestrator**: you implement nothing yourself. Every implementation, review and fix runs in a fresh subagent. Communicate with subagents through **context pointers**: the issue reference, branch names, the run notes, and earlier commits. Don't duplicate information already available via pointers.

The run is strictly **sequential**. The next issue starts only after the current one has landed, been skipped, or failed.

## Run state

Keep two files in `<git-common-dir>/implement-issues/<integration-branch>/` (from `git rev-parse --git-common-dir`). Git never tracks them, and every worktree can reach them.

- `progress.md`: every issue in order, with its branch, its status (`pending`, `in-progress`, `landed`, `skipped`, `failed`), and the reason for any `skipped` or `failed`. Update it on every status change.
- `notes.md`: anything an implementer reports that later issues need to know. Point every later subagent at it.

If `progress.md` already exists, resume the run: delete the worktree of any `in-progress` issue and restart that issue from the current integration tip.

## Steps

1. **Pre-flight.** Fetch every issue with its state, labels and blocking relationships. Stop and ask the user when:
   - an issue is closed or missing;
   - an issue is not marked ready for an agent (the `ready-for-agent` triage role, when the tracker configures one);
   - an issue is blocked by a later issue in the list, or by an open issue outside the list.

2. Cut the integration branch from the tip of the default branch. Write `progress.md`.

3. For each issue, in order:

   1. **Blocked.** If one of its blockers was skipped or failed in this run, mark it `skipped` ("blocked by <ref>") and go to the next issue.
   2. **Branch.** Cut an issue branch from the integration tip, in its own worktree.
   3. **Implement.** A fresh implementer subagent works in that worktree. It calls the Skill tool with `tdd` to build the issue, taking the issue's acceptance criteria as the agreed seams: it has no user to confirm seams with. Every commit message carries the issue reference. It reports one of:
      - `done`, plus any notes later issues need;
      - `skip`, when it cannot infer a seam from the acceptance criteria;
      - `failed`, with the reason.

      On `skip` or `failed`, record the status and reason, keep the worktree for inspection, and go to the next issue.
   4. **Review.** A fresh review subagent calls the Skill tool with `code-review` in the issue worktree. The fixed point is the integration tip the issue branch was cut from.
   5. **Fix.** If the review raised findings, one fresh implementer subagent fixes all of them in the issue worktree.
   6. **Check.** A fresh review subagent calls `code-review` with the last pre-fix commit as the fixed point, so it checks the fixes only.
   7. **Gate.** The issue passes when the full test suite is green and the check raises no hard violation and no Spec finding. On a fail, mark it `skipped` with the remaining findings as the reason, keep the worktree, and go to the next issue. There is no second fix round.
   8. **Land.** Squash-merge the issue branch into the integration branch as one commit titled `<issue title> (<ref>)`. Mark it `landed`, append its notes to `notes.md`, then delete its worktree and branch.
   9. **Push.** Push the integration branch. If the tracker closes work through PRs, or the user asks for one, open a draft PR after the first landing; later pushes update it.

4. **Finish.** If a draft PR exists, write its body by calling the Skill tool with `pr`: a closing keyword for each landed issue, in order, then each skipped or failed issue with its reason. Mark the PR ready for review. Otherwise, resolve each landed issue the way the tracker closes work, and report the integration branch.

5. Report every issue's final status and reason, and list the worktrees kept for inspection.
