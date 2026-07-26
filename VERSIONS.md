# goat-herd versions

Pack release version lives in `.claude-plugin/plugin.json` and
`.claude-plugin/marketplace.json`. Per-skill versions live in each `SKILL.md` frontmatter and
are mirrored in the table below.

If you have goat-herd installed, compare this table against your local
`.claude/skills/<skill>/SKILL.md` frontmatter to see what changed since you installed.

## Skills

| Skill | Version | Last change |
|---|---|---|
| `brief-subagent` | 1.0.0 | First release |
| `fan-out` | 1.0.0 | First release |

## Changelog

### 2.0.0

Goat Pack Standard v1. The pack gains a `skills/` directory, which is what makes it indexable at all, plus the family contract: bilingual English and Turkish triggers, an explicit Output format, a Definition of done whose every item is verifiable by reading the output, cross-pack handoffs, and three evals per skill including a boundary case where the skill must hand off rather than answer.

The existing guides, templates and scripts stay and are installed to `.claude/goat-herd/` so the skills can reference them.

**Added**

- `brief-subagent`: Writes the briefing that makes a subagent useful: a literal output contract, scope in both directions, the context it cannot see, anti-goals, and self-verification before return
- `fan-out`: Whether to delegate at all, and along which seam. Splits by artifact so results merge mechanically, and settles the disagreement rule before launching
- `.claude-plugin/plugin.json` and `marketplace.json`, so the pack installs via `npx skills add` and as a Claude Code plugin marketplace.
- `AGENTS.md` carrying the standard, and `validate.sh` which gates every commit.
- `install.sh` rewritten with `--list` and selective installation, leaving eval files out of the copy.

### 1.0.0

First release, before the standard existed.
