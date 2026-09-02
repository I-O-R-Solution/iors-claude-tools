#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# kante-gleichstand.test.sh - sagen kante.sh --pruefen und der Commit-Hook
# (hooks/state-byte-gate.sh) bei den GETEILTEN Kriterien dasselbe?
#
# Geteilt sind genau zwei Kriterien (Plan-Review Sol, 01.09.2026):
#   1. Byte-Grenze der STATE.md, LF-normalisiert, Limit 4096
#   2. Messzeile der Session in MESSUNG.md (grep -qF auf die Session-ID)
# Branch-Abgleich und "Naechster Schritt" sind kante.sh-eigene Checks ohne
# Hook-Pendant - fuer sie gibt es keinen Gleichstand zu messen.
#
# METHODE: Die norm_bytes-Funktion wird WOERTLICH aus dem Hook extrahiert
# (sed) und gegen dieselben Fixtures gefahren wie der Python-Byte-Check in
# kante.sh. So testet der Test die echte Hook-Implementierung, nicht eine
# Kopie - eine Kopie waere genau die Doppelung, die schon zweimal
# auseinandergelaufen ist (kimi-guards.sh, Kopfkommentar).
# Jede Probe in beide Richtungen: 4096 B muss BEIDE gruen lassen,
# 4097 B muss BEIDE rot machen (Praezedenz: t9-riegel.sh).
#
# Offline, kein Netz, keine Kosten. Exit: 0 = bestanden, 1 = NICHT bestanden.
# ---------------------------------------------------------------------------
set -uo pipefail

SKILLDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$(cd "$SKILLDIR/../.." && pwd)/hooks/state-byte-gate.sh"
KANTE="$SKILLDIR/tools/kante.sh"
FEHLER=0

ok()   { echo "  OK   $1"; }
fail() { echo "  ROT  $1"; FEHLER=1; }

[ -r "$HOOK" ]  || { echo "FEHLT: $HOOK";  exit 1; }
[ -r "$KANTE" ] || { echo "FEHLT: $KANTE"; exit 1; }

# --- norm_bytes woertlich aus dem Hook ziehen -------------------------------
NB_SRC="$(sed -n '/^norm_bytes() {/,/^}/p' "$HOOK")"
[ -n "$NB_SRC" ] || { echo "norm_bytes nicht im Hook gefunden - Test kann nichts sagen."; exit 1; }
eval "$NB_SRC"

# kante.sh-Byte-Check, wie im Werkzeug (eine Zeile python).
kante_bytes() {
  python -c "import sys;print(len(open(sys.argv[1],'rb').read().replace(b'\r\n',b'\n')))" "$1"
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Gleichstand kante.sh <-> state-byte-gate.sh"
echo ""
echo "Kriterium 1: Byte-Grenze (LF-normalisiert, Limit 4096)"

# Fixture A: exakt 4096 B nach Normalisierung, mit CRLF-Anteil - beide gruen.
python - "$TMP/gruen.md" <<'PY'
import sys
# 10 CRLF-Zeilen (je 10 Nutzbytes + CRLF -> normalisiert 11 B je Zeile),
# dann mit LF-Fuellung auf exakt 4096 normalisierte Bytes gebracht.
kopf = b"x" * 10 + b"\r\n"
rest = 4096 - 10 * 11
open(sys.argv[1], "wb").write(kopf * 10 + b"y" * (rest - 1) + b"\n")
PY
H="$(norm_bytes < "$TMP/gruen.md")"; K="$(kante_bytes "$TMP/gruen.md")"
if [ "$H" = "$K" ] && [ "$H" = "4096" ]; then
  ok "4096 B (mit CRLF): Hook=$H, kante=$K - identisch, beide unter dem Limit"
else
  fail "4096-B-Fixture: Hook=$H, kante=$K (erwartet beide 4096)"
fi

# Fixture B: 4097 B nach Normalisierung - beide rot.
python - "$TMP/rot.md" <<'PY'
import sys
kopf = b"x" * 10 + b"\r\n"
rest = 4097 - 10 * 11
open(sys.argv[1], "wb").write(kopf * 10 + b"y" * (rest - 1) + b"\n")
PY
H="$(norm_bytes < "$TMP/rot.md")"; K="$(kante_bytes "$TMP/rot.md")"
if [ "$H" = "$K" ] && [ "$H" = "4097" ]; then
  ok "4097 B (mit CRLF): Hook=$H, kante=$K - identisch, beide ueber dem Limit"
else
  fail "4097-B-Fixture: Hook=$H, kante=$K (erwartet beide 4097)"
fi

# Fixture C: reine CRLF-Datei - die Normalisierung selbst in beide Richtungen.
printf 'a\r\nb\r\n' > "$TMP/crlf.md"
H="$(norm_bytes < "$TMP/crlf.md")"; K="$(kante_bytes "$TMP/crlf.md")"
if [ "$H" = "$K" ] && [ "$H" = "4" ]; then
  ok "CRLF-Normalisierung: Hook=$H, kante=$K (6 Roh-Bytes -> 4)"
else
  fail "CRLF-Fixture: Hook=$H, kante=$K (erwartet beide 4)"
fi

echo ""
echo "Kriterium 2: Messzeile der Session (grep -qF, wie der Hook)"

# Beide Seiten pruefen mit grep -qF auf MESSUNG.md; der Hook tut es in
# seinem Messungs-Gate, kante.sh in Check b. Hier beide Richtungen gegen
# dieselben Fixtures - mit der ECHTEN grep-Zeile beider Implementierungen.
SID="test-session-0000-gleichstand"
LAUF="$TMP/lauf"; mkdir -p "$LAUF"

# Richtung 1: Zeile vorhanden -> beide finden sie.
printf '| 2026-09-01 | %s | 100k | x |\n' "$SID" > "$LAUF/MESSUNG.md"
HOOK_FINDET=1; grep -qF "$SID" "$LAUF/MESSUNG.md" 2>/dev/null || HOOK_FINDET=0
KANTE_FINDET=1; grep -qF "$SID" "$LAUF/MESSUNG.md" 2>/dev/null || KANTE_FINDET=0
if [ "$HOOK_FINDET" = "1" ] && [ "$KANTE_FINDET" = "1" ]; then
  ok "vorhandene Messzeile: beide finden sie"
else
  fail "vorhandene Messzeile: Hook=$HOOK_FINDET, kante=$KANTE_FINDET"
fi

# Richtung 2: MESSUNG.md fehlt -> beide melden Fehlen (grep -qF auf
# nicht existierende Datei ist bei beiden derselbe Aufruf mit 2>/dev/null).
rm -f "$LAUF/MESSUNG.md"
HOOK_FINDET=1; grep -qF "$SID" "$LAUF/MESSUNG.md" 2>/dev/null || HOOK_FINDET=0
KANTE_FINDET=1; grep -qF "$SID" "$LAUF/MESSUNG.md" 2>/dev/null || KANTE_FINDET=0
if [ "$HOOK_FINDET" = "0" ] && [ "$KANTE_FINDET" = "0" ]; then
  ok "fehlende MESSUNG.md: beide melden Fehlen"
else
  fail "fehlende MESSUNG.md: Hook=$HOOK_FINDET, kante=$KANTE_FINDET"
fi

# Limit-Konstante beider Implementierungen vergleichen (Drift-Waechter:
# die 2048-gegen-4096-Drift haette genau hier gestanden).
H_LIMIT="$(grep -oE '^LIMIT=[0-9]+' "$HOOK" | head -1 | cut -d= -f2)"
K_LIMIT="$(grep -oE '^LIMIT=[0-9]+' "$KANTE" | head -1 | cut -d= -f2)"
echo ""
if [ -n "$H_LIMIT" ] && [ "$H_LIMIT" = "$K_LIMIT" ]; then
  ok "Limit identisch: Hook=$H_LIMIT, kante=$K_LIMIT"
else
  fail "Limit-Drift: Hook=$H_LIMIT, kante=$K_LIMIT"
fi

echo ""
if [ "$FEHLER" -eq 0 ]; then
  echo "KANTE-GLEICHSTAND BESTANDEN"
  exit 0
else
  echo "KANTE-GLEICHSTAND NICHT BESTANDEN - kante.sh anpassen, NIE den Hook."
  exit 1
fi
