# iors-claude-tools

Shared [Claude Code](https://claude.com/claude-code) commands and skills for the I-O-R-Solution team.

## What's inside

### Commands

| Command | Purpose |
|---|---|
| `/claudemd-optimize` | Reviews a `CLAUDE.md` against 9 principles (Cherny + Anthropic + Stulberg). Returns a compact verdict with concrete actions, no auto-fix. Max 80 lines output. |
| `/prepare-session` | Context-Engineer. Generates a copy-ready session prompt for a topic/feature with code context, gap analysis, guardrails. Saves to `.planning/session-prompts/`. |
| `/ende` | Session-end protocol. Reliable slash-command alternative to the `session-ende` skill — same 5 steps. Use when you want a guaranteed trigger or when the natural-language skill doesn't fire. |

### Skills

| Skill | Trigger | Purpose |
|---|---|---|
| `session-ende` | "Schluss" / "Ende" / "Feierabend" | Session-end protocol: memory check, chronicle check, distill check, open items, integrity check. |

## Installation

Copy the files into your local Claude Code config directory:

```bash
# Commands
cp commands/claudemd-optimize.md ~/.claude/commands/
cp commands/prepare-session.md ~/.claude/commands/
cp commands/ende.md ~/.claude/commands/

# Skills
cp -r skills/session-ende ~/.claude/skills/
```

Or clone the repo and symlink the directories:

```bash
git clone https://github.com/I-O-R-Solution/iors-claude-tools.git
ln -s "$PWD/iors-claude-tools/commands/claudemd-optimize.md" ~/.claude/commands/
ln -s "$PWD/iors-claude-tools/commands/prepare-session.md" ~/.claude/commands/
ln -s "$PWD/iors-claude-tools/commands/ende.md" ~/.claude/commands/
ln -s "$PWD/iors-claude-tools/skills/session-ende" ~/.claude/skills/
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

### `/ende`

```bash
/ende                             # runs the 5-step session-end protocol
```

Identical to the `session-ende` skill but as an explicit slash-command. Use when you want a guaranteed trigger.

### `session-ende` skill

Triggers automatically when you say "Schluss", "Ende", "Feierabend" or similar. Runs the same 5-step session-end protocol as `/ende`. If the natural-language trigger ever fails, fall back to `/ende`.

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
