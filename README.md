# iors-claude-tools

Shared [Claude Code](https://claude.com/claude-code) commands and skills for the I-O-R-Solution team.

## What's inside

### Commands

| Command | Purpose |
|---|---|
| `/einrichtung` | Onboarding for beginners: builds a personal **global** `~/.claude/CLAUDE.md` through a 4-question interview (language/tone, role, hard no-gos, working style). Max 20 lines output, never overwrites an existing file, ends with the `/context` verification step. |
| `/check` | Multi-dimensional code review across Stabilitaet, Nachhaltigkeit, Effektivitaet, Staerke. Mandatory reuse-grep, severity-classified findings (KRITISCH/WICHTIG/KLEIN), controlled fix-flow — auto-fix only for KLEIN after explicit `j`, never for WICHTIG/KRITISCH. |
| `/claudemd-optimize` | Reviews a `CLAUDE.md` against 9 principles (Cherny + Anthropic + Stulberg). Works on both levels: `global` argument reviews `~/.claude/CLAUDE.md`, a path argument reviews a project file. Returns a compact verdict with concrete actions, no auto-fix. Max 80 lines output. |
| `/prepare-session` | Context-Engineer. Generates a copy-ready session prompt for a topic/feature with code context, gap analysis, guardrails. Saves to `.planning/session-prompts/`. |
| `/prompt` | Turns a free, unsorted brain-dump into one commissioning prompt using Anthropic's four-block template (THE JOB / THE WHY / THE GUARDRAILS / DONE MEANS). Reads the repo and memory first, then asks at most five single questions — one per turn, only about gaps reading could not close. Runs eight greppable self-checks on the draft (no bare prohibitions, no ALL-CAPS emphasis, no self-verification instructions, a measurable exit criterion) and prints the prompt copy-ready in the chat. Self-contained; hands existing prompt files to `/prompt-audit` if you have it. |
| `/spark` | Quality-First project bootstrap. Slash-trigger for the `spark` skill — pre-fills Phase 0 from any text passed after the command (project name, migration hint, or rich description). |

### Skills

| Skill | Trigger | Purpose |
|---|---|---|
| `spark` | "neues Projekt" / "scaffold" / "bootstrap" / "Grundgeruest" / "kick off" | Quality-First project bootstrap. Adaptive input (rich description OR 3-question fallback), Excellence-Anchor (3 sharpening questions), Craft-Principles as Decision-000 ADR, mandatory trio (CLAUDE.md/CONTEXT.md/REFERENCES.md) plus README/.gitignore/decisions/, conditional code-tooling skeleton (Python/Node-TS/Rust/Go), idempotent re-runs, auto-review via `/claudemd-optimize`. |
| `route` | `/route` / "route this" / "run the route loop" | One-pass build loop across two model families: an Opus 5.5 boss session interviews and plans; GPT-6 Astra (Codex CLI) reviews the plan ONCE and improves it (or leaves it when good enough); a headless Opus 5.5 worker builds; Astra reviews the execution ONCE; the boss verifies with machine predicates and a full diff read, then commits. A short review circle, never a loop. **Not part of the starter package** — see [Installing `/route`](#installing-route) for requirements and hooks. |

## Installation fuer Einsteiger (Windows, PowerShell)

Der Weg fuer Coaching-Teilnehmer und neue Teammitglieder. Voraussetzung: Git ist
installiert (unter Windows: [Git for Windows](https://git-scm.com/downloads/win)).
Alle Befehle in ein **PowerShell**-Terminal (Zeile beginnt mit `PS C:\`):

```powershell
# 1. Repo holen
git clone https://github.com/I-O-R-Solution/iors-claude-tools.git
cd iors-claude-tools

# 2. Zielordner sicherstellen
New-Item -ItemType Directory -Force "$HOME\.claude\commands", "$HOME\.claude\skills" | Out-Null

# 3. Starter-Paket kopieren
Copy-Item commands\einrichtung.md        "$HOME\.claude\commands\"
Copy-Item commands\spark.md              "$HOME\.claude\commands\"
Copy-Item commands\prepare-session.md    "$HOME\.claude\commands\"
Copy-Item commands\claudemd-optimize.md  "$HOME\.claude\commands\"
Copy-Item -Recurse -Force skills\spark   "$HOME\.claude\skills\"
# optional, nur fuer den route-Loop: siehe Abschnitt "Installing /route"
```

Danach Claude Code neu starten und mit `/einrichtung` beginnen.

**Das Starter-Paket in Kurzform:**

| Reihenfolge | Werkzeug | Wofuer |
|---|---|---|
| 1 | `/einrichtung` | die eigene globale `CLAUDE.md` — wer du bist, wie Claude antworten soll |
| 2 | `/spark` | pro Projekt einen Ordner mit eigener Instruktionsdatei anlegen |
| 3 | `/prepare-session` | laufende Arbeit an eine frische Session uebergeben |
| 4 | `/claudemd-optimize` | beide Dateisorten pruefen — wird von `spark` automatisch mitbenutzt (deshalb Pflicht) |

**Empfohlene Ergaenzung — Gedaechtnis:** [claude-mem](https://github.com/thedotmack/claude-mem)
(Community-Projekt, nicht von Anthropic). Braucht Node.js 20+ (`nodejs.org`, LTS):

```powershell
npx claude-mem install
```

Danach Claude Code neu starten. Hinweis: `npm install -g claude-mem` reicht laut
Projekt-Doku nicht — es registriert die Hooks nicht.

## Installation (macOS/Linux, bash)

Same starter package as above:

```bash
git clone https://github.com/I-O-R-Solution/iors-claude-tools.git
cd iors-claude-tools
mkdir -p ~/.claude/commands ~/.claude/skills

cp commands/einrichtung.md       ~/.claude/commands/
cp commands/spark.md             ~/.claude/commands/
cp commands/prepare-session.md   ~/.claude/commands/
cp commands/claudemd-optimize.md ~/.claude/commands/
cp -r skills/spark               ~/.claude/skills/   # includes references/ and scripts/
# optional, route loop only: see "Installing /route" below
```

Restart Claude Code, then start with `/einrichtung`.

**Beyond the starter package** — only if you know you want them:

```bash
cp commands/check.md ~/.claude/commands/          # code review, self-contained
cp commands/prompt.md ~/.claude/commands/         # brain-dump -> commissioning prompt, self-contained
```

## Usage

### `/einrichtung`

Builds your personal global `~/.claude/CLAUDE.md` — the file Claude Code loads in
**every** session, regardless of project. Four questions, max 20 lines of output.

```
/einrichtung                      # interview → global CLAUDE.md → /context check
```

Division of labour: `/einrichtung` describes the **person** (language, role, hard
no-gos), `/spark` describes the **project** (house rules, workflows, structure).
Never put project rules into the global file.

### `/check`

Multi-dimensional code review with controlled fix-flow. Default scope is `git diff HEAD` — call it after each finished slice of work.

```
/check                            # reviews uncommitted changes (git diff HEAD)
/check src/feature.ts             # reviews a single file
/check src/components/            # reviews up to 20 files in a folder
/check "auth flow"                # topic mode — greps for keywords, reviews top 8 matches
```

The four dimensions: **Stabilitaet** (error-handling, race-conditions, edge-cases, security), **Nachhaltigkeit** (naming, nesting, hidden coupling), **Effektivitaet** (does it achieve its goal, root-cause vs symptom), **Staerke** (mandatory reuse-grep — duplication check).

Findings are classified KRITISCH / WICHTIG / KLEIN. After the report, the command asks once whether to auto-fix the KLEIN ones (`j` to confirm). WICHTIG and KRITISCH are discussed one by one, never auto-fixed.

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

### `/route` and the `route` skill

```
/route                                # boss interviews, plans, Astra reviews the plan once, Opus worker builds, Astra reviews once, boss verifies
```

Runtime lives in `skills/route/`: `astra.sh` (the only way the review seats call Codex; model and effort are fixed there), `prompts/` and `schemas/` (Astra review, plan critique, build report), `tools/` (context-zone meter, edge check `kante.sh`, run measurement), `tests/`. `SITZPLAN.md` holds the model line-up with its evidence, `STATE-TEMPLATE.md` the cross-session note format. `LESSONS.md` and `KOSTEN.md` ship as starters and grow with your own runs. Read `skills/route/SKILL.md` first; it is the single source of truth for the loop.

#### Installing `/route`

Requirements:

- Claude Code with access to Opus 5.5 (boss and worker run `--effort medium`).
- [Codex CLI](https://github.com/openai/codex) on the `PATH`, logged in, with access to `gpt-6-astra`. If your account cannot reach Astra, `astra.sh probe` exits 4 and the skill asks you once per run whether to use a stand-in (`ASTRA_MODEL=gpt-5.6-terra`). Astra reads the repo through OpenAI.
- Bash (Git Bash on Windows) and Python 3.

```bash
cp -r skills/route ~/.claude/skills/
mkdir -p ~/.claude/hooks && cp hooks/state-byte-gate.sh ~/.claude/hooks/
```

Then register two hooks in `~/.claude/settings.json` (merge into existing `hooks`):

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "bash ~/.claude/hooks/state-byte-gate.sh", "timeout": 10 }] }
    ],
    "PostToolUse": [
      { "hooks": [{ "type": "command", "command": "bash ~/.claude/skills/route/tools/zonen-melder.sh", "timeout": 10 }] }
    ]
  }
}
```

`state-byte-gate.sh` blocks a commit whose route `STATE.md` exceeds its 4096-byte budget; `zonen-melder.sh` announces context-zone changes during a run (fail-open). Self-tests: `bash hooks/state-byte-gate.test.sh` and `for t in skills/route/tests/*.sh; do bash "$t"; done`.

### Session end and memory: merkwerk

The session-end protocol (`session-ende` skill, slash command) lives in [merkwerk](https://github.com/I-O-R-Solution/merkwerk), the memory engine for Claude Code. It ships the skill together with the memory setup it needs, so it is no longer kept here.

```bash
claude plugin marketplace add I-O-R-Solution/merkwerk
claude plugin install merkwerk@merkwerk
```

Then run the one-time `install.sh` from the merkwerk README and restart Claude Code. The command is `/merkwerk:ende`; "Schluss", "Ende" or "Feierabend" trigger it as well.

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

Free to use and adapt for I-O-R-Solution team members, coaching participants and
their companies. No warranty — these are working tools, not a product.
