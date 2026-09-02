#!/usr/bin/env bash
# Aktueller Kontextstand der laufenden Boss-Session plus Zone (route Context law).
#
# Warum das Werkzeug existiert: die 200k-Regel stand ab 2026-07-17 im Skill und
# blieb wirkungslos, weil im Loop nichts messt — eine Session lief blind auf 365k
# (gemessen 25.07.2026, Session 16d493a7). Eine Regel ohne Messgeraet ist Deko.
#
# Liest NUR die Hauptdatei, absichtlich: Subagenten-Kontext liegt nicht im
# Boss-Fenster und darf die Schnitt-Entscheidung nicht beschoenigen. Die
# Abschluss-Messung in Schritt 8 zaehlt Subagenten dagegen mit.
set -u

if [ -z "${CLAUDE_CODE_SESSION_ID:-}" ]; then
  echo "KONTEXT unbekannt - CLAUDE_CODE_SESSION_ID ist nicht gesetzt" >&2
  exit 1
fi

transkript="$(ls ~/.claude/projects/*/"$CLAUDE_CODE_SESSION_ID".jsonl 2>/dev/null | head -1)"
if [ -z "$transkript" ]; then
  echo "KONTEXT unbekannt - kein Transkript fuer $CLAUDE_CODE_SESSION_ID" >&2
  exit 1
fi

python ~/.claude/skills/route/tools/measure-run.py "$transkript" --json 2>/dev/null | python -c "
import json, sys
try:
    k = json.load(sys.stdin)['kontext_hauptdatei']
except Exception:
    print('KONTEXT unbekannt - measure-run.py lieferte kein JSON'); raise SystemExit(1)
z = k['ende']
zone = ('ARBEITEN' if z < 200_000 else
        'PLANEN'   if z < 300_000 else
        'LANDEN'   if z < 400_000 else
        'HALTEPUNKT')   # ZWEITE STELLE: Namen UND Schwellen stehen auch in
                        # tools/zonen-melder.py:38-52 - zwei Namen fuer dieselbe
                        # Zone waren am 25.07. schon einmal drin. Die Doppelung
                        # bleibt bewusst (der Hook dort ist abhaengigkeitsfrei
                        # gebaut); den Gleichstand sichert an allen sechs
                        # Grenzwerten tests/zonen-gleichstand.test.sh. Wer hier
                        # eine Zahl aendert, aendert sie dort mit und faehrt
                        # den Test.
print(f\"KONTEXT {z//1000}k  ZONE {zone}  max {k['maximum']//1000}k  Mittel {k['mittel']//1000}k\")
"
