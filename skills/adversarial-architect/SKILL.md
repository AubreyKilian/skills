---
name: adversarial-architect
description: Dispatch a fresh reviewer that argues against a design you have just settled, then says whether building it would establish a new convention. Run at the end of a design conversation, before implementation.
disable-model-invocation: true
---

# Adversarial architect

You have just finished a design conversation: an approach is settled, and implementation has not started. This skill dispatches **one fresh, read-only subagent** that argues **against** that design, then answers a second, independent question: would building it establish a new convention in this codebase?

Run it while the design is still cheap to change. It fits any workflow with a design or technical-prep phase — a GitHub issue after refinement, a Jira ticket before a spec is written, a design doc before the first commit.

## Why the reviewer is adversarial, and why it is a subagent

**A reviewer asked "is this design good?" agrees.** It has a concrete, coherent proposal in front of it and the cheapest coherent answer is assent. The output looks like a pass and carries no information.

**A reviewer that saw the design conversation also agrees.** This session's context is saturated with the reasons the design is right — it spent the whole conversation converging on them. So the reviewer must be a fresh agent that receives only the design text and the code, never the conversation.

The prompt therefore requires the reviewer to state the strongest objection it can construct *before* it is allowed to conclude there is no concern. A pass that never objects and a pass that is never run produce the same output; the objection-first structure keeps them distinguishable.

## Phase 1 — assemble the inputs

Fill every `<…>` slot of [`architect-prompt.md`](architect-prompt.md). The template is dispatched **verbatim** — never paraphrased, never abridged.

1. **The design statement.** Write out the design as it now stands, from this conversation, **whole**. Include every resolved clarification. Do not summarise: a summary is a second, weaker statement of the design, and the objections would land on the summary instead of the design.
2. **The work item (optional).** If the user supplied a pointer — a GitHub issue, a Jira ticket, a pasted requirements document — read it and fold anything load-bearing (business intent, stated constraints, technical pointers) into the design statement's context. Absence of a pointer is normal; the conversation is the primary source.
3. **The surfaces.** The file paths the design lands on. Verify each path exists right now — a stale path sends the reviewer to read nothing and report from imagination.
4. **Prior decisions.** Sweep the repository for decision records governing those surfaces: `docs/adr/`, `docs/decisions/`, `ARCHITECTURE.md`, `CONTRIBUTING.md`, `CLAUDE.md`, `AGENTS.md`, and any decision-record home the repo's own instructions name. List what governs the touched surfaces — and explicitly, which surfaces have **no** governing record. That second list is what the convention question is really about. Decisions kept outside the repo (a wiki, Confluence) enter as text the user pastes at the confirmation step.
5. **Code navigation.** If the host repo's instructions configure a code-navigation tool, name it in the prompt's code-nav slot; otherwise state "use Read/Grep/Glob".
6. **The model.** The reviewer's verdict is judgment about conventions — precisely where weaker models rubber-stamp. Request the strongest reasoning model the harness offers for the subagent. If it is unavailable, proceed on the session's model; there is no gate.

## Phase 2 — one pause, four confirmations

Show the user, in one message, before any dispatch:

1. The design statement, in full.
2. The surfaces.
3. The prior-decision findings — what was found, **and where you looked**, so a "we keep ADRs in Confluence" correction can land here.
4. The model the reviewer will run on.

Wait for the user to correct or confirm. Only an explicit go dispatches.

## Phase 3 — dispatch

One fresh **general-purpose** subagent, read-only, with the filled template as its entire prompt. It edits nothing, comments nowhere, and returns only the structured record the template ends with.

## Phase 4 — triage the return

**Validate before believing.** Check each surviving objection's `path:line` citation against the actual code. A confidently-wrong objection burns a real conversation; the citation is what makes the check cheap. An objection whose citation does not hold is dropped.

| Verdict | Meaning | What you do |
|---|---|---|
| `no concern` | The strongest objection available does not survive contact with the code. | Report it and record **nothing** — see the disciplines below. |
| `needs a decision first` | An objection is a call a human must make; design cannot settle it. | Present the question. Offer to draft it as a comment on the work item, shown in full before posting. |
| `here's the shape` | An objection survives and implies a specific correction or constraint. | Fold the constraint into the design statement. Offer to draft it as a comment on the work item, shown in full before posting. |

**The convention answer is triaged separately from the verdict.** If `ESTABLISHES A CONVENTION: yes` and the sweep found a decision-record home (an ADR directory, an architecture doc), offer to draft the record there. `no concern` + `establishes a convention: yes` is a normal and valuable pairing — the design is fine *and* it sets a precedent worth writing down. Do not discard the convention answer along with the verdict; that pairing is the single most likely thing to be lost here.

**Write-back is offered, never automatic.** Every write — issue comment, ticket comment, decision record — is drafted, shown whole, and posted only on the user's yes.

## Disciplines

- **Record nothing on a bare `no concern`.** No "the architect pass ran, no objections" comment — it is bookkeeping, and it teaches the next reader that the pass is a rubber stamp.
- **No fourth verdict, no free-form architecture document.** A standalone design artifact is a new class of rotting document — it describes code, nobody reads it, and it goes stale unnoticed. Surviving text lands on the work item or in the repo's existing decision-record home, nowhere else.
- **If repeated runs keep returning `no concern` on designs with obvious convention impact, the prompt has drifted agreeable — fix the prompt.** That is not a reason to stop running the pass.
