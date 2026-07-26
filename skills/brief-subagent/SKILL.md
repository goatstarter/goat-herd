---
name: brief-subagent
description: "Write the briefing that makes a subagent produce usable output instead of a summary you have to redo. Covers the output contract, the scope boundary, what context the subagent cannot see, the anti-goals, and how to state the verification the subagent must perform on itself. Use when delegating work to a subagent or Task, when a subagent returned something vague or wrong-shaped, or when choosing which of the pack's agents to use. Also use when the user says \"delegate this\", \"spawn an agent for\", \"the subagent gave me garbage\", \"how do I brief this\". Türkçe: \"alt ajana ver\", \"bunu devret\", \"alt ajan işe yaramaz döndü\", \"nasıl brief yazayım\", \"hangi ajanı kullanayım\". For deciding whether to delegate at all, see fan-out."
license: MIT
metadata:
  version: 1.0.0
  pack: goat-herd
---

# Brief a subagent

A subagent starts with none of your context and cannot ask a follow-up question mid-task. Every
gap in the briefing gets filled by a guess, and the guess arrives looking confident.

The briefing is the whole job. A vague brief produces output you have to redo, which costs more
than doing the work yourself.

## Before you start

Pick the agent first. The pack ships eight definitions under `agents/`: bug-hunter, dep-updater,
docs-writer, migrator, perf-profiler, repo-researcher, security-checker, test-writer. Each has an
output contract already written. Read the one you are using before writing the brief, because
half of what follows may already be specified.

Then answer, for yourself:

1. What artifact do you want back, and what will you do with it?
2. What does the subagent need that it cannot discover from the repo?
3. What must it not do?

## 1. State the output contract first

The most common failure is a subagent that returns prose when you needed a table, or a summary
when you needed file paths and line numbers.

Write the shape you want, literally:

> Return a markdown table with columns: file, line, finding, concrete failure scenario, severity.
> Nothing else. No preamble, no summary paragraph.

State whether the return value is for a human or for a program. A subagent whose output feeds
another step must be told that, or it will add conversational framing.

## 2. Draw the scope boundary in both directions

- **In scope**: the exact paths, files, or subsystem. Not "the auth code", rather
  `src/auth/**` and `src/middleware/session.ts`.
- **Out of scope**: what it must leave alone. This is the half that gets omitted, and it is why
  subagents wander into refactoring things nobody asked about.
- **Depth**: how far to follow a thread. "Trace callers one level, do not audit the whole
  dependency graph."

## 3. Supply the context it cannot see

The subagent cannot see your conversation. Give it, briefly:

- What was already tried and ruled out, so it does not repeat it.
- Decisions already made that constrain the work, and the reason.
- Local conventions the repository does not state.
- What "done" looks like for the surrounding task, so its output fits.

Keep this short. A brief that pastes your entire session context is a brief nobody reads,
including the model.

## 4. Name the anti-goals

Explicit prohibitions work better than implied ones:

- Do not modify files, this is read-only.
- Do not install anything.
- Do not claim a test passes unless you ran it and can paste the output.
- If you cannot verify something, say UNVERIFIED and why. Do not guess and do not omit it.
- If the task turns out to be impossible as stated, say so and stop. Do not substitute a
  different task.

That last one prevents the most expensive failure mode: a subagent that quietly solves an
adjacent problem and reports success.

## 5. Require self-verification

Tell the subagent what to check before returning:

> Before returning, confirm every file path you cite exists, every line number matches the
> current file, and every claim about behavior was either observed by running something or is
> marked as inferred.

A subagent asked to verify its own output produces materially better results than one asked only
to do the work, and it costs one sentence.

## Output format

The brief itself, in this order:

```
Task: <one sentence>
Return: <the exact artifact shape, literally>
In scope: <paths>
Out of scope: <paths and activities>
Context you cannot see: <already tried, decisions made, local conventions>
Do not: <anti-goals>
Before returning: <self-verification checks>
```

## Definition of done

- [ ] The pack's matching agent definition read first, and its existing output contract reused rather than rewritten
- [ ] Output contract stated as a literal shape, not a description of a shape
- [ ] Stated whether the output is for a human or feeds another step
- [ ] In-scope paths named exactly, not described
- [ ] Out-of-scope paths and activities named, not left implied
- [ ] Depth of investigation bounded
- [ ] What was already tried and ruled out included, so work is not repeated
- [ ] Anti-goals stated explicitly, including the instruction to stop rather than substitute a different task
- [ ] Self-verification checks required before return
- [ ] Brief short enough to be read in full

## Related skills

- **fan-out**: whether to delegate this at all, and how to split it across several agents
- **goat-sift/refute-pass**: verify findings a subagent returns rather than acting on them
  (requires goat-sift to be installed)
