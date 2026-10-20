#!/usr/bin/env bash
# kante-naechster.test.sh - Gegenprobe fuer Check e) von kante.sh --pruefen
# ("## Naechster Schritt": Existenz + Woertlichkeit).
#
# WARUM (Memory-Audit 2026-10-12): Von 10 roten Ampeln in den Transkripten
# (06.-11.10.) waren nur 4 berechtigt (<Liste>, <UUID> 2x, <f>, Byte-Deckel).
# Die anderen 6 kamen aus zwei Defekten der Ampel selbst:
#   1. Umleitung im woertlichen Befehl (`claude -p < prompt.md > out.json`)
#      wurde als Platzhalter gelesen (Muster `<[^>]*>` ueberspannt `< … >`).
#   2. Python-Ausgabe auf Windows-Konsole (cp1252) crashte an Zeichen wie `→`;
#      die Ausgabe blieb leer, die Ampel meldete "Naechster Schritt fehlt".
# Eine Ampel, die meistens falsch Rot zeigt, wird ueberfahren - belegt in
# episodes/2026-10/2026-10-09_{f3a2b595,ec943050}.md (Commit trotz ROT).
#
# Faelle = die REALEN Zeilen aus den Transkripten (gekuerzt, Form erhalten).
# Aufruf: bash ~/.claude/skills/route/tests/kante-naechster.test.sh [kante.sh]
# Optionales Argument: andere kante.sh pruefen (Vorher-Nachweis gegen HEAD).
set -uo pipefail

KANTE="${1:-$HOME/.claude/skills/route/tools/kante.sh}"
# Die reale Fehlerumgebung herstellen: keine UTF-8-Hilfe von aussen.
unset PYTHONUTF8 PYTHONIOENCODING

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"; LAUF="$REPO/.planning/route/probe"
mkdir -p "$LAUF"
git -C "$REPO" init -q -b probe-branch
git -C "$REPO" -c user.name=t -c user.email=t@t commit -q --allow-empty -m basis
BASIS="$(git -C "$REPO" rev-parse --short HEAD)"
export CLAUDE_CODE_SESSION_ID="probe-session-0000"
echo "| $CLAUDE_CODE_SESSION_ID | 100k |" > "$LAUF/MESSUNG.md"

FEHLER=0
fall() { # $1 erwartet (GRUEN|ROT)  $2 Name  $3 Naechster-Schritt-Koerper
  printf 'Abgleich: Branch probe-branch\nBasis: %s\n\n## Nächster Schritt\n%s\n\n## Narben\n-\n' "$BASIS" "$3" > "$LAUF/STATE.md"
  local out rc ist
  out="$(bash "$KANTE" --pruefen "$LAUF" 2>&1)"; rc=$?
  [ "$rc" -eq 0 ] && ist=GRUEN || ist=ROT
  if [ "$ist" = "$1" ]; then echo "  OK   $2 ($ist)"
  else echo "  ROT  $2: erwartet $1, war $ist"; printf '%s\n' "$out" | grep 'KANTE: ROT' | head -2 | sed 's/^/         /'; FEHLER=1; fi
}

echo "Muss ROT bleiben (echte Platzhalter, alle real belegt):"
fall ROT  "<Liste> (1ec5ae9b)"   '"/route" mit Text „webinar-freitag P1-Korrekturen: <Liste>".'
fall ROT  "<UUID> (8496b8d7)"    '`claude -p --resume <UUID> --model claude-opus-5-5`'
fall ROT  "<f> im Pfad (7c1d48dc)" '`claude -p --model claude-opus-5-5 < fix-prompt-<f>.md > out.json`'
fall ROT  "mehrwortig (Korpus 2x)" 'Fix-Delta bauen: `cat crit-header.md <zwei Delta-Befunde> > fix.md`'
fall ROT  "Abschnitt leer"       ''

echo "Muss GRUEN sein (woertliche Befehle):"
fall GRUEN "Umleitung < … > (ec943050)" '`claude -p --model claude-opus-5-5 --output-format json < .planning/route/videokurs-m4-v3/build-prompt-e1.md > .planning/route/videokurs-m4-v3/e1.json`'
fall GRUEN "Pipe + > (Form nach f5e36ce8)"  '`cd .planning/route/demofilm-stufe2 && sed s/ETAPPE/E1/g build-header.md | cat - PLAN.md > build-prompt-e1.md`'
fall GRUEN "Umleitung ohne Leerzeichen" '`claude -p <prompt.md >out.json 2>err.log`'
fall GRUEN "Pfeil → (Encoding)"   'Neue Session → `/route demofilm-stufe2 fortsetzen` → S4 Diff-Review'
fall GRUEN "Umlaute + Gedankenstrich" '`/route videokurs-m4-v3` — Prüfung läuft über Sichtabnahme'

echo ""
if [ "$FEHLER" -eq 0 ]; then echo "KANTE-NAECHSTER BESTANDEN"; exit 0
else echo "KANTE-NAECHSTER ROT"; exit 1; fi
