#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# schema-spiegel.test.sh - tragen alle Schema-Spiegel dieselben Felder?
#
# Hard rule in SKILL.md: "Schema mirrors schemas/*.schema.json <-> schemas/kimi/
# stay in sync ... A field added on one side and missed on the other silently
# disables the check for that worker." Die Regel stand bisher NUR als Prosa -
# dieser Test macht sie pruefbar (v2.2, 01.09.2026; seitdem gibt es mit
# schemas/deepseek/ einen zweiten Spiegel und damit doppelte Driftflaeche).
#
# Verglichen wird die MENGE der Feldpfade (properties, rekursiv) plus die
# required-Listen je Ebene. MFJS-Abweichungen (keine Typ-Unionen, null -> "")
# betreffen TYPEN, nie Feldnamen - Typunterschiede sind hier erlaubt.
#
# Offline, keine Kosten. Exit: 0 = synchron, 1 = Drift (Felder benannt).
# ---------------------------------------------------------------------------
set -uo pipefail

SKILLDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FEHLER=0

for BASIS in plan-critique build-report; do
  MASTER="$SKILLDIR/schemas/$BASIS.schema.json"
  for SPIEGEL_DIR in kimi deepseek; do
    SPIEGEL="$SKILLDIR/schemas/$SPIEGEL_DIR/$BASIS.schema.json"
    if [ ! -r "$SPIEGEL" ]; then
      echo "  ROT  $BASIS: Spiegel fehlt ($SPIEGEL_DIR/)"
      FEHLER=1
      continue
    fi
    if AUSGABE="$(python - "$MASTER" "$SPIEGEL" <<'PY'
import json, sys

def feldpfade(schema, praefix=""):
    pfade = set()
    if not isinstance(schema, dict):
        return pfade
    for name, sub in (schema.get("properties") or {}).items():
        pfad = praefix + name
        pfade.add(pfad)
        pfade |= feldpfade(sub, pfad + ".")
        items = sub.get("items") if isinstance(sub, dict) else None
        if isinstance(items, dict):
            pfade |= feldpfade(items, pfad + "[].")
    for r in (schema.get("required") or []):
        pfade.add(praefix + r + " (required)")
    items = schema.get("items")
    if isinstance(items, dict):
        pfade |= feldpfade(items, praefix + "[].")
    return pfade

a = feldpfade(json.load(open(sys.argv[1], encoding="utf-8")))
b = feldpfade(json.load(open(sys.argv[2], encoding="utf-8")))
nur_a = sorted(a - b)
nur_b = sorted(b - a)
for f in nur_a:
    print("nur im Master:  " + f)
for f in nur_b:
    print("nur im Spiegel: " + f)
sys.exit(1 if (nur_a or nur_b) else 0)
PY
)"; then
      echo "  OK   $BASIS: $SPIEGEL_DIR/ synchron"
    else
      echo "  ROT  $BASIS: $SPIEGEL_DIR/ driftet:"
      printf '%s\n' "$AUSGABE" | sed 's/^/         /'
      FEHLER=1
    fi
  done
done

echo ""
if [ "$FEHLER" -eq 0 ]; then
  echo "SCHEMA-SPIEGEL BESTANDEN"
  exit 0
else
  echo "SCHEMA-SPIEGEL NICHT BESTANDEN - fehlende Zwillinge nachziehen (MFJS-Regeln beachten)."
  exit 1
fi
