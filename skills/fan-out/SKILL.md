---
name: fan-out
description: "Decide whether to delegate work to subagents at all, and if so how to split it so the agents do not overlap, contradict each other, or produce results that cannot be merged. Covers the cases where delegation loses money, how to split by artifact rather than by topic, the merge problem, and what to do when two agents disagree. Use when considering parallel subagents, when a task feels too big for one context, or when several agents returned conflicting results. Also use when the user says \"should I parallelize this\", \"run several agents\", \"split this work\", \"the agents contradict each other\". Türkçe: \"paralel ajan çalıştırayım mı\", \"işi böl\", \"birkaç ajana dağıt\", \"ajanlar çelişiyor\", \"devretmeye değer mi\". For writing the brief once the split is decided, see brief-subagent."
license: MIT
metadata:
  version: 1.0.0
  pack: goat-herd
---

# Fan out

Delegation is not free. Each subagent costs a briefing you have to write, a result you have to
read, and a merge you have to perform. Below a certain size, doing the work yourself is cheaper
and more reliable.

This skill decides whether to fan out, and if so, along which seam.

## Before you start

Ask only what is missing:

1. What is the work, and how would you split it if you had to?
2. Do the parts share files, or are they independent?
3. What will you do with the results: read them, merge them, or act on each separately?

## 1. Decide whether to delegate at all

| Delegate | Do it inline |
|---|---|
| The work is genuinely independent across parts | The parts share state or files |
| Reading it all would flood your own context | It fits in your context and you need continuity |
| You want independent perspectives on one question | You want one coherent judgment |
| Each part produces a self-contained artifact | The output only makes sense as a whole |
| The work is mechanical across many items | The work needs a decision per item that only you can make |

Delegation loses money when: the parts touch the same files, the briefing would be longer than
the work, or the results need so much reconciliation that you re-derive everything anyway.

The specific trap: delegating a task that needs one consistent decision to three agents, each of
which makes that decision differently and defensibly. You then have three coherent answers and no
way to merge them.

## 2. Split by artifact, not by topic

A good seam produces parts that can be merged mechanically.

| Seam | Merges cleanly | Use when |
|---|---|---|
| One file or module per agent | Yes, if they do not import each other | Mechanical changes across many files |
| One question per agent | Yes, the answers are separate sections | Research and audits |
| One perspective on one question per agent | Yes, you compare and synthesize | High-stakes decisions |
| One layer of a stack per agent | Rarely, layers have contracts between them | Almost never |
| Half the feature each | No | Never |

If two agents will edit the same file, either give one of them the file or run them in separate
worktrees. Two agents editing one file produces a conflict you resolve by hand, which is the
work you were delegating.

## 3. Prevent overlap explicitly

Each brief carries its own out-of-scope list naming the other agents' territory. Not "focus on
auth" but "auth only, and do not touch `src/api/**`, another agent owns it."

Also give each agent the same shared context: the decisions already made, the conventions, the
definition of done for the whole task. Agents given different context produce results that
disagree for reasons that are your fault.

## 4. Plan the merge before you launch

Write down, before spawning anything:

- What each agent returns, in the same shape as the others.
- How the results combine: concatenated, deduplicated, compared, or reduced.
- What you do when two disagree.

The disagreement rule matters. Options: take the union and verify each item, take the
intersection and lose the tail, or escalate the disagreement to a verification pass. Pick one now
rather than improvising when it happens.

Identical output shape across agents is what makes any of this cheap. Different shapes mean you
merge by reading, which is the cost you were avoiding.

## 5. Cap it

More agents is not more throughput past a point. Each result is a thing you must read, and your
reading is the bottleneck, not their working.

Start with the smallest fan-out that covers the work. Add a second round if the first surfaces
something. A round of three agents whose output you actually read beats twelve whose output you
skim.

## Output format

```
# Fan-out plan: <task>

## Delegate or inline
<verdict> because <the specific reason from the table>

## The seam
<what each agent owns> · Merges by: <mechanism>
Shared files between agents: <none | which, and how it is handled>

## Agents
| # | Owns | Out of scope, other agents' territory | Returns |
(the Returns column is identical in shape across every row)

## Shared context every agent gets
<decisions already made, conventions, definition of done>

## Merge plan
Combine by: <concatenate | dedupe | compare | reduce>
If two disagree: <the rule, decided now>

## Cap
<n> agents this round. Second round only if <condition>.
```

## Definition of done

- [ ] Delegate-or-inline verdict given with the specific reason, not a general preference
- [ ] Seam chosen so results merge mechanically rather than by reading
- [ ] No two agents own the same file, or the collision is handled by separate worktrees
- [ ] Every brief carries an out-of-scope list naming the other agents' territory
- [ ] Every agent gets the same shared context, so disagreements are not an artifact of uneven briefing
- [ ] Return shape identical across agents
- [ ] Merge mechanism decided before launching
- [ ] The disagreement rule decided before launching
- [ ] Fan-out capped, with a stated condition for a second round

## Related skills

- **brief-subagent**: writes each brief once the split is decided
- **goat-tribe/worktree-split**: when agents must edit the same files in parallel
  (requires goat-tribe to be installed)
- **goat-sift/refute-pass**: the verification pass when agents disagree
  (requires goat-sift to be installed)
