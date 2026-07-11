# Briefing subagents

A subagent starts with zero knowledge of your session. It has not seen your conversation, your earlier findings, or the file you just edited. Everything it knows arrives in one prompt, and everything it learned leaves in one reply. Most bad subagent results are bad briefs, not bad agents. This guide is the discipline that makes the pack in `agents/` worth its round-trips.

## When to delegate at all

Delegate when at least one of these holds:

- **Context isolation.** The task requires reading far more than the conclusion is worth (mapping a subsystem, sweeping 40 files). The subagent absorbs the reads; you get the distilled result.
- **Independent perspective.** You want a judgment untainted by what you already believe: an audit, a bug hunt, a verification. Your own context is a liability here; the subagent's ignorance of your assumptions is the feature.

If neither holds, do the work directly. A lookup you could resolve with one grep does not justify a round-trip, and a task needing ten turns of back-and-forth judgment fights the one-shot model.

## The 5-part brief

Every delegation prompt should contain these five parts. Skipping one is how you get a confident answer to the wrong question.

### 1. Goal
One sentence: what done looks like. Not the activity ("look at the auth code") but the outcome ("determine whether any endpoint under /api/admin lacks the role check").

### 2. Scope
Where to work and where not to. Directories, files, globs; explicitly exclude what looks relevant but is not (generated code, the deprecated v1 tree, vendored deps). Subagents without scope boundaries wander, and wandering is your token budget.

### 3. Constraints
What it must not do (edit files, install packages, hit external services), which tools or commands to prefer, and any budget ("if this exceeds ~20 files, stop and report the size instead").

### 4. Return format
Say what shape you want back, even when the agent file defines one: which sections you actually need, maximum length, and the escape hatch ("if you cannot complete X, return what you found plus what blocked you" beats a fabricated completion). You will paste this reply into your own reasoning; order what you ask for accordingly.

### 5. Context it cannot discover
The part most often forgotten. The subagent cannot see: what you already tried and ruled out, decisions made earlier in your session, which branch or half-finished state the tree is in, project conventions that live in your head rather than in files, why the task exists. Two or three sentences of this context routinely halve the wasted work.

Bad brief:

> Check the payments module for bugs.

Good brief:

> Goal: find latent defects in the refund flow that could double-refund or strand a refund half-applied.
> Scope: src/payments/refund/ and its direct callers in src/api/; ignore src/payments/legacy/ (dead code, removal pending).
> Constraints: read-only; do not run anything against the live Stripe config, use the test fixtures in tests/fixtures/payments/.
> Return: findings ordered by severity with reproduction sketches; if the area is clean, say what you checked.
> Context: we just migrated this flow from callbacks to async/await on this branch; the old code assumed single-threaded execution, so check-then-act patterns are the prime suspect. The webhook retry behavior is documented in docs/webhooks.md.

## Treat the reply as claims, not facts

A subagent's report is testimony, not ground truth. It read fast, it cannot be cross-examined, and it may have papered over a gap to complete its assignment. Before building on a reply:

- **Spot-check the load-bearing claims.** If the report says "the guard is applied at the router level (router.ts:41)", open router.ts:41 before you rely on it. One or two spot checks per report; pick the claims your next action depends on.
- **Prefer agents that cite.** Every agent in this pack is required to return file:line evidence precisely so spot-checking is cheap. A claim without a citation costs a search to verify; weigh it accordingly.
- **Watch for suspicious completeness.** "All 34 sites transformed, all tests pass" deserves one manual sample. Honest reports usually contain a parked-items or unverified section; a report with no residue at all is either a small task or an incomplete account.
- **Never chain unverified claims.** Building step 3 on a subagent's unchecked step-2 claim compounds the error rate. Verify at the joints.

## One round-trip, priced honestly

Each delegation costs: prompt-writing time, the subagent re-discovering basics your session already knows, and the risk of a misaligned answer that needs a second round. Batch accordingly: one well-scoped brief covering the whole question beats three fragmentary ones, and when two tasks are independent, dispatch them in parallel rather than serially. If you find yourself wanting a dialogue with the subagent, the task probably belonged in your own session.

## Related

For fresh-context verification of finished work and diff review, use the `verifier` and `code-reviewer` agents from [goat-fable](https://github.com/goatstarter/goat-fable); this pack deliberately does not duplicate them. goat-fable's orchestration guide covers when to run agents in parallel and how to sequence dependent ones.
