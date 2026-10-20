#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Astra-Sitz fuer /route (Olivers Auftrag 17.10.2026): GPT-6 Astra ueber die
# Codex-CLI, Denkstufe medium. Astra prueft den Plan EINMAL und die
# Ausfuehrung EINMAL, verbessert direkt - oder laesst es, wenn es gut genug ist.
#
# Aufruf (immer aus dem Repo-Root, als einziger Befehl im Bash-Aufruf):
#   astra.sh probe                      Erreichbarkeit pruefen (Exit 0 = Astra antwortet)
#   astra.sh plan <run dir>             Plan-Review: darf NUR <run dir>/PLAN.md aendern
#   astra.sh diff <run dir> <basis-sha> Ausfuehrungs-Review: darf nichts unter .planning/ aendern
#
# Ergebnis: <run dir>/astra-<modus>.json (Schema astra-review.schema.json) und
# <run dir>/astra-<modus>-geaendert.txt (was WIRKLICH auf der Platte geaendert
# wurde - gemessen, nicht Astras Behauptung).
#
# Exit: 0 gruen · 2 Aufruf falsch · 4 Astra nicht erreichbar (Konto/Modell) ·
#       5 Sitz-Verstoss (falsche Datei angefasst ODER Urteil passt nicht zur
#       Platte) · 6 kein gueltiger Bericht.
#
# Overrides: ASTRA_MODEL (Standard gpt-6-astra) - NUR mit Olivers Ja fuer
# diesen Lauf, in STATE.md vermerkt. CODEX_BIN (Standard: codex im PATH).
# ---------------------------------------------------------------------------
set -euo pipefail

# Skill-Ordner aus dem eigenen Ort - laeuft so bei jedem, nicht nur unter C:/Users/User.
SKILLDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && { pwd -W 2>/dev/null || pwd; })"
CODEX_BIN="${CODEX_BIN:-codex}"
ASTRA_MODEL="${ASTRA_MODEL:-gpt-6-astra}"
ASTRA_EFFORT="medium"
SCHEMA="$SKILLDIR/schemas/astra-review.schema.json"
SNAP="$SKILLDIR/tools/astra-snapshot.py"

MODE="${1:-}"
case "$MODE" in
  probe)
    TMP="$(mktemp -d)"
    OUT="$(cd "$TMP" && timeout 240 "$CODEX_BIN" exec --skip-git-repo-check \
      -m "$ASTRA_MODEL" -c model_reasoning_effort="$ASTRA_EFFORT" -s read-only \
      "Reply with exactly: ASTRA-OK" < /dev/null 2>&1 || true)"
    rm -rf "$TMP"
    if printf '%s\n' "$OUT" | grep -qx 'ASTRA-OK'; then
      echo "ASTRA ERREICHBAR: $ASTRA_MODEL · $ASTRA_EFFORT"; exit 0
    fi
    echo "ASTRA NICHT ERREICHBAR: $ASTRA_MODEL" >&2
    printf '%s\n' "$OUT" | grep -m1 -E '"message"|^ERROR' >&2 || printf '%s\n' "$OUT" | tail -3 >&2
    exit 4 ;;
  plan) [ $# -eq 2 ] || { echo "Aufruf: $0 plan <run dir>" >&2; exit 2; } ;;
  diff) [ $# -eq 3 ] || { echo "Aufruf: $0 diff <run dir> <basis-sha>" >&2; exit 2; } ;;
  *) echo "Aufruf: $0 <probe|plan|diff> ..." >&2; exit 2 ;;
esac

RUN="${2%/}"; BASIS="${3:-}"
REPO="$(git rev-parse --show-toplevel)"
[ -f "$RUN/PLAN.md" ] || { echo "FEHLT: $RUN/PLAN.md" >&2; exit 2; }
# PLAN.md so, wie git status ihn nennt (repo-relativ, Schraegstriche).
PLAN_REL="$(python -X utf8 -c "import os,sys;print(os.path.relpath(os.path.abspath(sys.argv[1]),sys.argv[2]).replace(os.sep,'/'))" "$RUN/PLAN.md" "$REPO")"
if [ "$MODE" = diff ]; then
  git cat-file -e "$BASIS^{commit}" 2>/dev/null || { echo "BASIS unbekannt: $BASIS" >&2; exit 2; }
fi

PROMPT="$RUN/astra-$MODE-prompt.md"
REPORT="$RUN/astra-$MODE.json"
LOG="$RUN/astra-$MODE-log.txt"
GEAENDERT="$RUN/astra-$MODE-geaendert.txt"
VORHER="$(mktemp)"
rm -f "$REPORT"

# Prompt ist Shell-Arbeit: Auftrag + Pfade. Die Datei ist das Pruefprotokoll.
{
  cat "$SKILLDIR/prompts/astra-$MODE.md"
  echo
  echo "PLAN: $RUN/PLAN.md"
  [ "$MODE" = diff ] && echo "BASIS: $BASIS"
} > "$PROMPT"

[ "$MODE" = plan ] && cp "$RUN/PLAN.md" "$RUN/PLAN.vor-astra.md"
python -X utf8 "$SNAP" snap "$REPO" "$VORHER"

set +e
"$CODEX_BIN" -C "$REPO" exec -m "$ASTRA_MODEL" \
  -c model_reasoning_effort="$ASTRA_EFFORT" -s workspace-write \
  --output-schema "$SCHEMA" -o "$REPORT" - < "$PROMPT" > "$LOG" 2>&1
RC=$?
set -e

# Kein unbegrenzter Strom im Lauf-Ordner: nur das Ende bleibt.
tail -n 200 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"

if grep -q 'not supported when using Codex' "$LOG"; then
  echo "ASTRA NICHT ERREICHBAR ($ASTRA_MODEL) - Konto-Sperre bei OpenAI, siehe $LOG" >&2
  rm -f "$VORHER"; exit 4
fi
grep -m1 '^workdir:' "$LOG" || true

# Was hat Astra wirklich angefasst? Eigene Lauf-Artefakte zaehlen nicht.
python -X utf8 "$SNAP" diff "$REPO" "$VORHER" \
  | grep -v -F -e "astra-$MODE" -e "PLAN.vor-astra.md" > "$GEAENDERT" || true
rm -f "$VORHER"
if [ "$MODE" = plan ] && ! cmp -s "$RUN/PLAN.md" "$RUN/PLAN.vor-astra.md"; then
  # PLAN.md kann gitignored sein - dann meldet git status ihn nicht.
  grep -qxF "$PLAN_REL" "$GEAENDERT" 2>/dev/null || echo "$PLAN_REL" >> "$GEAENDERT"
fi

# Bericht vorhanden und gueltig?
python -X utf8 - "$REPORT" "$SCHEMA" <<'PY' || { echo "KEIN GUELTIGER BERICHT (codex exit $RC) - $LOG" >&2; exit 6; }
import json, sys
r = json.load(open(sys.argv[1], encoding="utf-8"))
s = json.load(open(sys.argv[2], encoding="utf-8"))
missing = [k for k in s["required"] if k not in r]
assert not missing, missing
assert r["verdict"] in ("GUT_GENUG", "VERBESSERT", "BLOCKER")
PY

# Sitz-Regeln gegen die Platte.
VERDIKT="$(python -X utf8 -c "import json,sys;print(json.load(open(sys.argv[1],encoding='utf-8'))['verdict'])" "$REPORT")"
NCHANGES="$(python -X utf8 -c "import json,sys;print(len(json.load(open(sys.argv[1],encoding='utf-8'))['changes']))" "$REPORT")"
NDATEIEN="$(grep -c . "$GEAENDERT" || true)"
VERSTOSS=""
if [ "$MODE" = plan ]; then
  FREMD="$(grep -v -xF "$PLAN_REL" "$GEAENDERT" || true)"
  [ -n "$FREMD" ] && VERSTOSS="Plan-Review hat andere Dateien als PLAN.md angefasst: $(echo $FREMD)"
else
  FREMD="$(grep -E '(^|/)\.planning/' "$GEAENDERT" || true)"
  [ -n "$FREMD" ] && VERSTOSS="Diff-Review hat .planning/ angefasst: $(echo $FREMD)"
fi
[ "$VERDIKT" = GUT_GENUG ] && [ "$NDATEIEN" -gt 0 ] && VERSTOSS="${VERSTOSS:+$VERSTOSS; }GUT_GENUG, aber $NDATEIEN Datei(en) geaendert"
[ "$VERDIKT" = VERBESSERT ] && { [ "$NDATEIEN" -eq 0 ] || [ "$NCHANGES" -eq 0 ]; } && VERSTOSS="${VERSTOSS:+$VERSTOSS; }VERBESSERT, aber Dateien=$NDATEIEN changes=$NCHANGES"

echo "ASTRA $MODE: $VERDIKT · changes $NCHANGES · Dateien $NDATEIEN · $ASTRA_MODEL $ASTRA_EFFORT"
if [ -n "$VERSTOSS" ]; then
  echo "SITZ-VERSTOSS: $VERSTOSS" >&2
  exit 5
fi
exit 0
