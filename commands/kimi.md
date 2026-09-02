---
description: Delegate a task to Kimi K3 (Moonshot) — the fallback worker when Sol is out of quota
argument-hint: "[--write] [--resume] [--slug <name>] [what Kimi should do]"
allowed-tools: Bash(bash:*)
---

Forward the request below to the Kimi K3 worker runtime with exactly one `Bash`
call, then return its stdout verbatim.

Raw user request:
$ARGUMENTS

Command shape:

```
bash "C:/Users/User/.claude/skills/route/kimi-worker.sh" <mode> <slug> - - "<prompt>"
```

Routing:

- default mode `chat` — read-only, free-form answer
- `--write` → mode `build` (Kimi may edit files)
- `--resume` → mode `resume` (continues the last `build` session for that slug)
- `--slug <name>` sets the slug; otherwise use `adhoc`
- Strip those flags from the prompt text; preserve the user's wording otherwise.
- For a long or open-ended job, run the Bash call in the background.

Do no independent work: do not inspect the repo, plan, draft a solution, or
comment before or after Kimi's output. You are a forwarder here, not the author.

Guards — report the exit code's meaning and stop. Never work around it, never
`cd` elsewhere to evade a block:

- exit 3 — blocked directory (`recht/`, or a `.env` in the tree while the
  `.env` guard is not yet verified by test T4). Kimi runs on Moonshot's servers
  outside the EU and Moonshot does not exclude API content from model training
  by default; the block is the point.
- exit 4 — `C:/Users/User/.claude/.kimi-key` missing or empty. Tell the user;
  do not create it.
- exit 5 — `resume` without a prior `build` session for that slug.

If the user supplied no request, ask what Kimi should do.
