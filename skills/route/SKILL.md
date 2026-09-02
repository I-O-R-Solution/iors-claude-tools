---
name: route
description: >-
  On-demand one-pass build loop. The boss (this session) interviews, plans
  once and gets ONE adversarial critique; GPT-5.6 Sol (Codex) builds; the boss
  reviews the finished work — findings are fixed at the artefact, never by
  re-polishing the plan. Kimi K3 adds a cross-family second opinion on RISIKO
  and GROSS runs. Trigger ONLY when the user types /route, says "route this", "run the
  route loop", or explicitly asks for the boss-plus-Sol loop. Do NOT use for
  ordinary single-model coding, planning, refactors, or chat.
---

# Route v2: one pass — the plan is attacked once, the work is reviewed

You are the boss. You PLAN and you REVIEW; you never write the implementation —
the worker does (Sol by default). Talk to the user in German; prompts to Sol
are English. Stay silent between tool calls — one sentence when you find
something, change direction, or hit a blocker. Decide micro-choices yourself;
the real gates are never small: every `PERZEPTIV` acceptance, any scope change
or destructive action, every escalation.

**Core law: critique never polishes the plan.** One adversarial round attacks
the plan; every finding below blocker travels WITH the build as a checklist
(the Wächterliste) and is verified at the artefact — diff, tests, screen —
where disputes have a floor. The build itself is reversible (git); the gates
sit before the *irreversible* steps (deploy, migration, send), not before
building. Why (measured 07/2026): round 1 of plan critique caught every real
catastrophe on file; rounds 3–5 found mostly their own prior repairs (severe
findings 2→2→6, four of six self-inflicted; a 101-KB plan, zero lines built).
Critique of a plan argues with text and diverges; critique of a diff measures
facts and converges.

**The boss is the session, not a callable.** Sol and Kimi are started through
the shell; you are the Claude Code session — the only participant with a
shell, the file system, and the user. The boss model is whatever this session
runs; if an open `STATE.md` names a different model for this session, report
the divergence in one German line and let the user decide.

**Model seats (Oliver's standing decision, 25.07./30.07., benchmarks moved
to `SITZPLAN.md` 01.09.):** boss sessions default to **Opus 5**
(`/model claude-opus-5`). **Fable 5** takes exactly the TWO seats where pure
thinking is the whole product: writing the plan (S2) on RISIKO or GROSS runs,
and the RISIKO diff review (S4, already mandated below). Both Fable seats sit
on edges that are hard cuts anyway (S1→S2 and the review session), so they
cost no extra session — the handoff's `Nächster Schritt` names the `/model`
switch verbatim. The BUILDER is never a Claude model: Sol/Kimi build on their
own quota, and a Claude builder would put Claude review on Claude work — the
foreign family is the review asset. Mechanical checks stay on sonnet/haiku
subagents (Delegation). The evidence per seat — benchmark, number, date,
price, re-measure date — lives in `SITZPLAN.md`; a seat change starts there,
never here. (DeepSeek was evaluated and REJECTED as a seat 01.09.2026 —
reasons in `SITZPLAN.md`; the provider-blind worker keeps the door a
one-config-file affair if that ever changes.)

**Precedence when rules collide:** correctness > the user's explicit
instruction > context hygiene. Never skip a verification, a diff read, or an
escalation to save a turn.

**The witness rule:** no claim without its witness, recorded where a later
session can check it. A predicate is "green" only after it has been seen red,
a worker call is "done" only with its validated artefact, a cut carries its
measured context number.

## RISIKO valve — how much machinery this run gets

RISIKO if at least ONE holds: foreign or customer data is touched (loss,
mixing, missending) · DB migration or schema change · contract or legal text
(AGB, Verträge) · live deploy to customer-facing systems · a guard, hook or
security mechanism is the subject of the build.

| | Standard | RISIKO |
| --- | --- | --- |
| Plan critique | Sol, one round | Sol + Kimi in PARALLEL, one round |
| Diff review | boss, in-session | FRESH session on Fable 5 |
| Red witnesses | closing gates | every MACHINE gate |

**GROSS gets the second critique too:** when the build classes GROSS (> 120k,
`KOSTEN.md`), Kimi runs in parallel at Step 3 even on Standard runs — nothing
else upgrades. A failing Kimi preflight is repaired ONCE before skipping is
allowed (a repaired critic found the only real blocker on file); a skip is a
recorded gap in `STATE.md`.

Upgrading to RISIKO is always allowed — state the reason in `PLAN.md`.
Downgrading is not. When in doubt, it is RISIKO. Record the class and the
matching criterion in `PLAN.md` line 1 at Step 0.

## Context zones — the spine

Measure at every safe boundary (after each commit, after every worker return,
before starting any unit):
`bash ~/.claude/skills/route/tools/kontext-jetzt.sh`. A PostToolUse hook
(`tools/zonen-melder.py`) announces zone changes unasked, but it is fail-open —
a silent hook and a low context look identical; after a long stretch with no
zone line, run the command.

- **< 200k ARBEITEN:** start any unit. A finished phase does not force a cut.
- **200–300k PLANEN:** start only what you expect to finish under 300k.
- **300–400k LANDEN:** start nothing new — finish, verify, commit, `STATE.md`,
  cut.
- **≥ 400k:** land at the NEXT checkpoint (worker report validated + own
  verification recorded + commit; or spec written; or critique JSON on disk).
  Work in flight is never thrown away.
- The number is a FLOOR: measured drift is 10–30k per turn — subtract a turn's
  worth before deciding, and never let a boundary hang on less than 30k.
- **START GATE:** before any unit, runway = 400k − measured − 40k landing
  reserve. Look the unit's class up in `KOSTEN.md` (KLEIN < 40k · MITTEL
  40–120k · GROSS > 120k). Class does not fit → do not start it; land, and let
  a fresh session do it from the 64–80k socket band. `KOSTEN.md` is frozen
  (01.09.2026) — look the class up, append nothing; re-open it only if the
  start gate misjudges twice (criterion in `KOSTEN.md`'s head).
- One route run per session. Pause > 1 h → cut, as the default. One
  verification round = one batched turn. Long builds run in the background —
  the harness notifies you; no polling.
- `.planning/route/<slug>/` holds artefacts. They are evidence, not context —
  never re-read them to catch up. Rehydration reads ONLY `SKILL.md` +
  `STATE.md` + `PLAN.md`.
- Two edges cut regardless of zone: between plan critique and build (merged
  plan+build sessions balloon past 400k, three lessons on file), and a RISIKO
  diff review never runs in the session that watched the build.

## S1 — Setup and interview

**Step 0.** Look for open runs FIRST: `.planning/route/*/STATE.md` **and**
`.planning/route-opus/*/STATE.md`. Line 1 not ABGESCHLOSSEN/ABGEBROCHEN →
this `/route` is a continuation: reconcile (see "Cutting and resuming"), then
continue at its `Nächster Schritt`. Two open runs → ask the user which one.
*v1 compat:* a run started under the old skill continues at whatever its
`STATE.md` names — even a v1-only step such as a critique round ≥ 2; the
Zettel is the contract for the immediate step. From the next phase edge on,
v2 applies: no further critique rounds, findings triage as below.

New run: check `git status` and `git branch --show-current` — unrelated
uncommitted changes → warn the user before Sol writes anything (parallel
sessions). Record `git rev-parse --short HEAD` as the run's **base SHA** into
`STATE.md` (`Basis:`), never condensed away — the diff review runs against it
— and the BRANCH into the `Abgleich:` line (an unrecorded branch once cost
three verified etappen to a foreign branch). Decide Standard/RISIKO.

**Step 1 — Interview.** Extract a complete, unambiguous spec. AskUserQuestion,
up to 4 related questions per round; stop only at zero material gaps. **Write
the agreed spec VERBATIM into `.planning/route/<slug>/PLAN.md` under
`## Spec`** — decisions, rejected alternatives, open user gates — before any
cut. `STATE.md` has no room for it and rehydration reads nothing else.

**EDGE → STATE.md, fresh session.**

## S2 — Plan and the one critique

**Step 2 — Plan.** Read `~/.claude/skills/route/LESSONS.md` and copy the
lessons that bear on THIS build into `PLAN.md` — build sessions rehydrate from
`PLAN.md` alone. `PLAN.md` is a marching route, not a contract: spec,
constraints, files to touch, etappe breakdown, verification commands,
out-of-scope list.

**Cut by repo and surface — never one run per etappe** (Oliver, 31.07.2026):
etappen covered by the SAME verification-script set belong in ONE run; plan,
counter-critique and verification tooling are paid again per run. A plan that
needs a second, disjoint script set is two runs. A project with a human
approval halt in its middle (recording, legal sign-off) runs OUTSIDE `/route` —
the loop is built for one pass without a halt. Measured: six plan-etappen
became three runs plus one manual stretch (art50).

Keep it small; if the plan will not say itself in ~25 KB, the scope is too big
for one run — offer the user a split AND record their answer in `PLAN.md`
line 1 (`Split abgelehnt <Datum>`, or the new slug). Measured 08/2026: all four
audited plans broke the limit (28,0 / 33,9 / 34,8 / 57,7 KB) and no split was
ever offered. An unrecorded offer evaporates; the byte count already rides in
every `Kante:` line, so the number was never the missing part.

Acceptance criteria, two types only. **`MACHINE`:** exact command, its cwd,
input identity, a non-empty subject precondition, measured value vs target —
and its **red witness**: the one mutation that must turn it red (element
deleted, golden corrupted, wrong cwd, invented path). A red witness needs a
green run-up (the same check seen green on the intact fixture first) and
attribution — the pass/block names WHICH rule fired: five of six probes once
died at an older guard and reported green. Satisfiable by a printed literal,
or exit-masked by a trailing `echo`, is no witness. Absence/grep predicates
need a positive anchor (places that MUST match). A numeric target becomes a
gate only after its IST value was measured once — unmeasured thresholds
certify instead of protecting (plan said ≥12, reality 92) or sit permanently
red and stop being looked at. A criterion that cannot name its red witness is
not a predicate — label it `PERZEPTIV`. Missing input, an empty subject set,
a stale baseline, or an oracle consuming its own output is RED, never
zero-success. **`PERZEPTIV`:** exact state, viewport, observable failure,
evidence path — the user decides it; falsify the capture method itself before
any verdict (a full-page screenshot without scrolling showed an "empty" page
that wasn't). "Looks right" without a number or the PERZEPTIV label is a plan
defect.

**Step 3 — ONE adversarial critique (read-only).** Prompt assembly is shell
work, never model work — from the run directory:
`cat ~/.claude/skills/route/prompts/critique-header.md PLAN.md ~/.claude/skills/route/prompts/critique-tail.md > prompt-1.md`
— the plan stays INLINE (the prompt file is the audit record of what was
criticised). Then:

    codex exec -s read-only \
      --output-schema ~/.claude/skills/route/schemas/plan-critique.schema.json \
      -o .planning/route/<slug>/critique-1.json - < prompt-1.md

Call via stdin, never as an argument. The header orders the critic into the
repository — verify every claim the plan makes about existing code or live
state, cite `file:line` — and the schema demands anchors plus a coverage
record (paths inspected AND high-risk surfaces not inspected).

**RISIKO: run Kimi in PARALLEL** — same round, background, not a second
round. Foreign-provider rule (generalised 01.09.): ask ONCE per run whether
the foreign provider is cleared for export; declined or gate-blocked = skip
and state the gap in `STATE.md`. Two hard conditions — preflight exit 0 AND
that clearance:

    bash ~/.claude/skills/route/preflight.sh kimi --quiet
    bash ~/.claude/skills/route/kimi-worker.sh critique <slug> \
      ~/.claude/skills/route/schemas/kimi/plan-critique.schema.json \
      .planning/route/<slug>/critique-kimi-1.json "<critique prompt>"

**Triage — the only handling of findings; there is no second round:**

- **Foundation blocker** (the spec contradicts itself; a base assumption about
  data, repo or live state is wrong): back to the USER in German with the
  finding and its anchors. A wrong spec is the user's decision, not a critique
  loop's.
- **BLOCKER:** fix the plan ONCE, via `Edit` on the affected sections — never
  rewrite `PLAN.md` whole. No re-critique of the fix: it becomes a NAMED item
  on the Wächterliste and is verified at the artefact.
- **Everything else (major/minor):** goes VERBATIM onto the **Wächterliste** —
  a numbered list under `## Wächterliste` in `PLAN.md`, injected into every
  build prompt, checked off item by item in the diff review. It never changes
  the plan.

Record in `STATE.md`: `Kritik: <blocker>/<major>/<minor> · Wächter <n>`.

**EDGE → STATE.md, fresh session (hard — never plan and build in one
session).**

## S3 — Build (one loop per etappe)

**Worker choice.** Default Sol — pass no `-m` flag and never set model or
reasoning effort (the user's config already runs max). UI-/frontend-heavy
etappen (visual layout, styling, HTML/CSS/animation): offer **Kimi K3** via
one AskUserQuestion (Frontend Arena 07/2026 put it ahead of Fable and Sol in
exactly this discipline; not measured against Opus — the `PERZEPTIV`
acceptance decides). Same two Kimi conditions as Step 3; choose per etappe,
not per run; note `Worker: Kimi` in `STATE.md`. An etappe whose work is
*running* guards is a bad Kimi fit — it has no shell.

**Build call:**

    codex exec -s workspace-write \
      --output-schema ~/.claude/skills/route/schemas/build-report.schema.json \
      -o .planning/route/<slug>/build-report-<e>.json - < build-prompt-<e>.md

- Open the session `workspace-write` from the FIRST call — `codex exec resume`
  accepts no `-s` and inherits the session sandbox.
- Etappe protocol, stated in the prompt: Sol issues **no git write commands**
  (its sandbox cannot write `.git` on Windows) and stops after each etappe.
  The boss verifies and commits, then resumes.
- Record the Codex session UUID into `STATE.md` the moment `codex exec` prints
  it. Resume by UUID, never `resume --last` — a parallel session may be the
  newest. Resume is ALWAYS `codex -C <repo> exec resume <UUID>` — the global
  `-C` BEFORE the subcommand; resume does not inherit the session's workdir,
  it takes the caller's — and ALWAYS the only command in its Bash call:
  combining it with anything swallows the prompt silently. After every codex
  start, check the log's `workdir:` line against the target repo. Resume also
  inherits neither `--output-schema` nor `-o` — both go on every resume call,
  see S5.
- The build prompt carries the Wächterliste and instructs Sol to run the
  plan's verification commands itself and fill `checks[]`: predicate, cwd,
  measured, target, `red_witness`, `fired_rule` (WHICH rule produced the
  pass/block), `green_first` (the same check seen green on the intact fixture
  before the mutation), `red_before` (what the check measured against the
  UNTOUCHED state before THIS build — it must be RED there; a preservation
  predicate that legitimately starts green carries `ERHALTUNG: <reason>`
  instead) — the schema rejects a green without a witnessed red.
  Why `red_before` is a field and not a reminder (measured 08/2026): the red
  first measurement is the cheapest witness there is, 8 of 21 plan blockers
  were reachable with it alone — and it stood as prose in `LESSONS.md` AND
  verbatim in a run's own `PLAN.md` and was ignored at both. Twice overlooked
  becomes enforced.
- Prompts to Sol follow the `gpt-5-4-prompting` skill's XML block recipes.
- **Sol unavailable** (quota, outage): never switch silently. Offer Kimi as
  replacement worker (preflight gate as above); a Codex session cannot cross
  providers — Kimi starts FRESH from `PLAN.md` + `STATE.md`, so write both
  first. Declined or blocked → `STATE.md` and stop.

**Artefact handshake — after every worker or reviewer call, before you
interpret success.** The target file exists, is fresh for THIS call, parses,
validates against its schema, carries a terminal status — exit 0 and stdout
prove none of these. Conversely a non-zero exit does not erase valid output:
complete structured output plus a validator failure is **POSTPROCESSOR-RED** —
preserve it, repair the validator, promote it. Call it a crash only when no
structured output exists, and record exit code + last stderr lines. Never keep
an unbounded stdout stream in the run directory: on failure byte count,
SHA-256 and the last 200 lines; `build-log-*.txt` belongs in `.gitignore`.

**SAFE BOUNDARY after every etappe → verify, commit, measure. ARBEITEN: next
etappe here. PLANEN and above: `STATE.md` and cut.**

**New user requirement mid-run:** say in German that it changes the plan.
Touches a RISIKO criterion → add it to `## Spec` and run ONE delta critique of
the new part only. Otherwise → note it under `## Offen` for after this run.
Never build it unplanned, never silently defer it.

## S4 — Verification and diff review (the gate)

**Verify.** Re-run the plan's verification commands yourself — all checks in
ONE batched turn. Delegate every check that HAS a machine predicate to a
subagent (sonnet/haiku): it returns measured value plus target, YOU compare;
on deviation it quotes the ≤ 40 failing lines verbatim. A check that cannot be
delegated because it has no predicate is a PLAN DEFECT — add the predicate,
never hand over the judgement. Red witnesses: run each required probe once
against its named mutation, restore, record `PROBES E<n> <passed>/<required>`
in `STATE.md` — RISIKO: every MACHINE gate; Standard: the closing gates. A
missing or failed required probe makes `Kante: ROT` and forbids the commit.
One exception: the USER may explicitly waive a red MACHINE gate — the measured
value stays recorded, the Kante carries `GEWAIVT — <gate> <messwert>`, the
commit is allowed. Gates protecting a RISIKO criterion (data loss, missending,
migration, guard efficacy) are never waivable.

**Diff review (indivisible).** Read the FULL diff against the base SHA —
`git diff <basis>..HEAD` — never only the last etappe. Correctness, edge
cases, security, spec compliance, and the Wächterliste checked off item by
item. *Violated if* any agent, model or filter reads the diff and hands you a
summary in its place — a pre-filter can withhold a finding without you
noticing, and an absent finding is unreviewable. Extra reviewers only ADD,
never replace or prioritise: `/codex:review` is Sol reviewing Sol's own code;
Kimi is the foreign family, gated as above. **RISIKO: this step runs in a
FRESH session on Fable 5** — `STATE.md`'s `Nächster Schritt` names the model
switch verbatim (`/model claude-fable-5`, then `/route`), and a model boundary
is always a cut. Standard: you read it yourself, here.

Findings → S5. None → S6.

## S5 — Fix rounds (max 3 per finding)

    codex -C <repo> exec resume <UUID> \
      --output-schema ~/.claude/skills/route/schemas/build-report.schema.json \
      -o .planning/route/<slug>/build-report-<f>.json \
      "<delta findings only — do not restate the plan>"

**The two flags are not optional on resume.** `resume` accepts both (verified
against the CLI 17.08.2026) but inherits NEITHER from the session that was
resumed. Drop them and the fix round returns prose instead of a validated
report — no `checks[]`, no `red_before`, no witnessed red, and the artefact
handshake below has nothing to validate. Measured 08/2026: fix rounds are 22 of
47 worker calls, so an unvalidated resume is the majority case, not the edge.

Kimi-built etappe: `kimi-worker.sh resume <slug> …` — its T8 gate decides;
blocked (exit 6) → fresh `build` call carrying the delta. Worker exit map:
2 usage/schema · 3 guard riegel · 4 key file · 5 no build session · 6 T8 ·
7 env scan — treat 3/4/7 as environment problems, never as a build failure.

- **Fix the class, not the instance.** A critic's quote is a sample, not the
  census. Before closing any finding, grep for siblings of the same statement,
  pattern or promise; record the count in the fix note. Repairing only the
  quoted line writes the next round yourself.
- Verify every fix round — its own predicates plus the touched Wächter items.
  An unverified fix has moved the defect, not fixed it.
- **Divergence stop:** a fix diff that OPENS more severe findings than it
  closes → stop immediately, give the user the per-round numbers in German,
  await the decision. Never run another round just to use up attempts.
- **UNENTSCHEIDBAR is a valid exit:** when the measurement confirms a limit
  the plan itself named in advance, the honest verdict closes the finding —
  no fix round, no loosening of the threshold (that is the reward hack).
- After 2 failed rounds on the SAME finding: cross-family diagnosis BEFORE the
  third try — Sol-built → `kimi-worker.sh critique` (conditions as in Step 3);
  Kimi-built → Sol `codex exec -s read-only`. Hand over the finding, the
  failing predicate (measured vs target) and the fixes already tried. After 3
  failed rounds: stop and escalate to the user (their global rule), diagnosis
  attached.
- Zone check after every round; ARBEITEN → next round here.

## S6 — Close

Report in German: the agreed spec, what was built, findings and their fates,
verification results, any skipped second opinion plus reason — and EVERY line
still standing under `## Offen`, `## Offene Minors` and `## Gates Oliver` as
an explicit handover block; a closed run whose known bugs live only in a file
marked ABGESCHLOSSEN has lost them. Then:

1. Set `STATE.md` line 1 to `ABGESCHLOSSEN <Datum>` (byte-check again).
2. Measure the run:
   `python ~/.claude/skills/route/tools/kanten-messung.py <run dir> --bericht`
   — it aggregates the line each session wrote at its own cut, so a rotated or
   mislisted transcript costs nothing. It NAMES every session that is missing
   a line and withholds the total; close a gap by measuring that session, never
   by dropping it. Targets: mean ≤ 200k, peak ≤ 400k. `measure-run.py --lauf
   <session .jsonl …>` still reads transcripts directly when they all exist.
3. Append to `LESSONS.md` as a dated heading — `## JJJJ-MM-TT — <slug>
   (Anfragen, Spitze, Mittel, Kosten, Boss-Sitze)` — plus at most 3 lessons,
   each written as an invariant, never as an incident; prune past ~50 entries. **`LESSONS.md` is an
   ARCHIVE:** it informs future plans (Step 2) — it never changes this skill.
   `SKILL.md` changes only on the user's explicit order, never as part of
   closing a run.
4. Sweep session litter from the skill dir: delete `.zone-*` and
   `.kimi-raw-*`; keep `.kimi-session-*` and `.kimi-t4/t8-passed` (gate
   markers).

## Cutting and resuming (every edge)

**Cut — two commands (v2.2):** FIRST
`bash ~/.claude/skills/route/tools/kante.sh --messen <run dir>` — it runs
`kontext-jetzt.sh` (the number for the `Kante:` line) and writes this
session's edge measurement into `MESSUNG.md`. THEN fill
`~/.claude/skills/route/STATE-TEMPLATE.md` into the RUN'S OWN directory — a
run living under `.planning/route-opus/<slug>/` keeps that path; writing the
literal `route/` path silently splits the run. Read the template again before
every write — the writing rules live only there. Filling the Zettel (Narben,
Selbsttest, `Nächster Schritt`) is judgement and stays model work. **≤ 4096
bytes**, LF-normalised, comment blocks deleted. LAST, before the commit:
`bash ~/.claude/skills/route/tools/kante.sh --pruefen <run dir>` — one
traffic light over byte limit, this session's measurement line, branch
against the `Abgleich:` line (never against `Basis:` — that stays frozen for
the S4 diff review, checked only as ancestor of HEAD), and the existence of
a verbatim `Nächster Schritt` command (quoted, never generated). RED forbids
the cut. The commit gate stays the last instance and refuses a `STATE.md`
without this session's line — measured at the edge, the number survives both
transcript cleanup and a mistyped session list.

Overwrite `STATE.md` at each edge — git history is the archive. Put the
measured context into the `Kante:` line (`· KONTEXT <n>k`) at the moment you
decide to cut. `Narben` empty after a build etappe is almost always wrong.
Before stopping, read your own `STATE.md` once as a stranger: can you name the
next command without guessing? If not, fix it now — it is the only bridge.

**Resume:** reconcile before acting — `STATE.md` describes the world as it
was. `git log -1` matches the recorded SHA? `git branch --show-current`
matches the recorded branch? Working tree clean? Named artefacts exist? Any
mismatch: **stop and tell the user in German what diverged.** Never "repair" a state you did not witness. Verification red at an
edge with nothing committed → record the failing predicate (measured vs
target) and that no commit happened; the next session resumes at S5, not S6.
Abandoning a run: `STATE.md` line 1 `ABGEBROCHEN <Datum> — <Grund>`.

**"Just keep going" from the user** outranks the hygiene rules: comply, batch
every check, say once in German where you actually are (past 400k the harness
may summarise mid-work, which loses more than a cut), and write `STATE.md`
anyway.

## Delegation limits

Delegate generously where it keeps raw output out of the boss window — wide
searches, multi-file reads, log digs; the subagent absorbs the dumps and
returns ten lines. Floor: a one-or-two-file lookup you read yourself.
Exploration (sonnet): path + line range + verbatim quote, never paraphrase —
every factual claim reaching `PLAN.md` you re-read at the quoted location.
Verification: only with a machine predicate; measured value plus target, never
"pass". **Never delegable:** the diff read, anything `PERZEPTIV`, any check
without a predicate. Subagent context lands outside this transcript — count it
in when measuring; moving work sideways is not saving.

## Hard rules

- The boss never writes the implementation. Sol (or a designated Kimi etappe)
  builds; you plan, verify, review, commit.
- Plan critique runs `-s read-only`; only the build runs `-s workspace-write`.
- Never enable the plugin's stop-review-gate during a route run (double loop,
  drains usage limits).
- Schema mirrors `schemas/*.schema.json` ↔ `schemas/kimi/` stay in sync
  (MFJS: no type unions, `null` becomes `""`). A field added on one side and
  missed on the other silently disables the check for that worker.
- Never shorten an enforcing rule in this file to save bytes — and never grow
  this file from a run's lessons. Both directions of drift are documented
  failure modes; changes to this file are their own user-ordered task.
