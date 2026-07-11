🇬🇧 English · [🇹🇷 Türkçe](README.tr.md)

# goat-herd

Eight production Claude Code subagents, each a specialist with a strict output contract.

## Honest framing

A subagent is not free parallelism. Each delegation costs a round-trip, and the agent starts knowing nothing about your session: not your conversation, not your earlier findings, not why the task exists. This pack is built on one design principle: a subagent earns its existence by either **isolating context** (absorbing big reads that would pollute your main session) or bringing an **independent perspective** (auditing without your assumptions). Anything that fails both tests belongs in your main session, not here. Because the brief carries everything the agent will ever know, the pack's briefing conventions ([guides/briefing.md](guides/briefing.md)) matter as much as the agents themselves. And treat every reply as claims, not facts: spot-check the load-bearing ones before building on them.

Fresh-context verification and code review agents live in [goat-fable](https://github.com/goatstarter/goat-fable) (`verifier`, `code-reviewer`); this pack does not duplicate them.

## The agents

| Agent | Give it | Get back |
|---|---|---|
| [repo-researcher](agents/repo-researcher.md) | A "how does X work here" question + any hints | Structured map: entry points, data flow, conventions, file:line refs. Never raw file dumps |
| [migrator](agents/migrator.md) | A mechanical transformation spec + scope | Per-site status table, including sites it could not safely transform |
| [test-writer](agents/test-writer.md) | Code paths + intent + how to run tests | Tests in the project's own idiom, each proven able to fail, plus a coverage summary of gaps |
| [docs-writer](agents/docs-writer.md) | A change or module + where docs live | Docs in the project's doc voice, every claim verified against code, stale neighbors flagged |
| [security-checker](agents/security-checker.md) | Target area + how requests reach it | Severity-ranked findings that survived refutation, with file:line evidence |
| [perf-profiler](agents/perf-profiler.md) | A named slow path + reproduction steps | Measured baseline, dominant cost with evidence, ranked fixes with expected impact. Changes nothing |
| [dep-updater](agents/dep-updater.md) | Manifest(s) + dependencies in scope | A plan, not an execution: each update classified with changelog evidence, ordered, with per-step verification |
| [bug-hunter](agents/bug-hunter.md) | A target area + what it is supposed to guarantee | Only defects that survived self-refutation, each with a reproduction sketch |

Common contract across all eight: cite file:line for every claim, report what was *not* done as prominently as what was, and never return a confident answer built on an unverified assumption without labeling it.

## Contents

| Path | What it gives you |
|---|---|
| `agents/` | The 8 subagent definitions, ready for `.claude/agents/` |
| `guides/briefing.md` | The 5-part brief (goal, scope, constraints, return format, undiscoverable context) and how to treat subagent output |
| `install.sh` | Idempotent installer, all agents or a selection |

## Quickstart

```bash
git clone https://github.com/goatstarter/goat-herd
cd goat-herd
./install.sh /path/to/your-project                 # all 8
./install.sh /path/to/your-project bug-hunter      # or just what you need
```

Then read [guides/briefing.md](guides/briefing.md) before your first delegation. Claude Code picks agents up from `.claude/agents/` automatically; each installed agent's description costs a little context, so install only what you will use.

## When not to use this

Single-fact lookups you could answer with one grep; tasks that need interactive back-and-forth judgment; anything where you would immediately re-read everything the agent read anyway. Delegation has a floor cost; below it, work directly.

---

Part of the Goatstarter pack family · [goat-fable](https://github.com/goatstarter/goat-fable) · [@esadcom](https://github.com/esadcom)

MIT licensed. See [LICENSE](LICENSE).
