# iors-claude-tools

Shared [Claude Code](https://claude.com/claude-code) commands and skills for the I-O-R-Solution team.

## What's inside

### Commands

| Command | Purpose |
|---|---|
| `/claudemd-optimize` | Reviews a `CLAUDE.md` against 9 principles (Cherny + Anthropic + Stulberg). Returns a compact verdict with concrete actions, no auto-fix. Max 80 lines output. |
| `/prepare-session` | Context-Engineer. Generates a copy-ready session prompt for a topic/feature with code context, gap analysis, guardrails. Saves to `.planning/session-prompts/`. |
| `/ende` | Session-end protocol. Thin pointer to the `session-ende` skill (single source of truth). Use when you want a guaranteed slash-command trigger. |
| `/spark` | Quality-First project bootstrap. Slash-trigger for the `spark` skill — pre-fills Phase 0 from any text passed after the command (project name, migration hint, or rich description). |

### Skills

| Skill | Trigger | Purpose |
|---|---|---|
| `session-ende` | "Schluss" / "Ende" / "Feierabend" | Session-end protocol: memory check, chronicle check, distill check, open items, integrity check. |
| `spark` | "neues Projekt" / "scaffold" / "bootstrap" / "Grundgeruest" / "kick off" | Quality-First project bootstrap. Adaptive input (rich description OR 3-question fallback), Excellence-Anchor (3 sharpening questions), Craft-Principles as Decision-000 ADR, mandatory trio (CLAUDE.md/CONTEXT.md/REFERENCES.md) plus README/.gitignore/decisions/, conditional code-tooling skeleton (Python/Node-TS/Rust/Go), idempotent re-runs, auto-review via `/claudemd-optimize`. |

## Installation

Copy the files into your local Claude Code config directory:

```bash
# Commands
cp commands/claudemd-optimize.md ~/.claude/commands/
cp commands/prepare-session.md ~/.claude/commands/
cp commands/ende.md ~/.claude/commands/
cp commands/spark.md ~/.claude/commands/

# Skills
cp -r skills/session-ende ~/.claude/skills/
cp -r skills/spark ~/.claude/skills/   # includes references/ subfolder
```

Or clone the repo and symlink the directories:

```bash
git clone https://github.com/I-O-R-Solution/iors-claude-tools.git
ln -s "$PWD/iors-claude-tools/commands/claudemd-optimize.md" ~/.claude/commands/
ln -s "$PWD/iors-claude-tools/commands/prepare-session.md" ~/.claude/commands/
ln -s "$PWD/iors-claude-tools/commands/ende.md" ~/.claude/commands/
ln -s "$PWD/iors-claude-tools/commands/spark.md" ~/.claude/commands/
ln -s "$PWD/iors-claude-tools/skills/session-ende" ~/.claude/skills/
ln -s "$PWD/iors-claude-tools/skills/spark" ~/.claude/skills/
```

## Usage

### `/claudemd-optimize`

```
/claudemd-optimize                # reviews ./CLAUDE.md in current directory
/claudemd-optimize global         # reviews ~/.claude/CLAUDE.md
/claudemd-optimize path/to/file   # reviews a specific file
```

### `/prepare-session`

```
/prepare-session <topic>          # generates a session prompt for <topic>
```

Output is saved to `.planning/session-prompts/<topic-slug>-prompt.md`.

### `/spark` and the `spark` skill

Bootstrap a new project with quality forcing-functions at Day 1.

```bash
/spark                                # starts with 3-question fallback
/spark mein-projekt                   # pre-fills project name, asks the rest
/spark <long description of project>  # rich input — skips interview, jumps to Phase 1
/spark migration: /path/to/existing   # adds context files to existing folder, code untouched
```

Or trigger via natural language: "neues Projekt anlegen", "scaffold", "bootstrap", "Grundgeruest fuer ..." (full trigger list in `skills/spark/SKILL.md`).

The skill runs through 5 phases: mode detection → depth check → confirmation → write (with conflict-safe idempotent merge) → quality gates → auto-review of the generated `CLAUDE.md`.

### `/ende` and the `session-ende` skill

The skill is the single source of truth for the protocol. The slash-command is a thin pointer to it.

```bash
/ende                             # explicit slash-command trigger
```

Or trigger via natural language: "Schluss", "Ende", "Feierabend", "Feierabend fuer heute" etc. (full trigger list in `skills/session-ende/SKILL.md`).

If the natural-language trigger ever fails to fire, fall back to `/ende`.

## Conventions

- All instructions are written in German (target audience is the I-O-R-Solution team).
- Technical terms (commands, file paths, code) stay in English.
- Each tool follows the "every line earns its place" principle — minimal, dense, actionable.

## Contributing

Open a PR with the proposed change. Each command/skill should:

- Be self-contained (no dependencies on other tools in this repo)
- Include a clear `description` in frontmatter
- Pass the Golden-Rule-Test: every line should answer "would Claude make a mistake without this line?"

## License

Internal use within I-O-R-Solution.
