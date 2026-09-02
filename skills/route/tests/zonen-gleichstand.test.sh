#!/usr/bin/env bash
# Gegenprobe fuer die beiden Kontext-Messwerkzeuge des route-Loops:
#   tools/kontext-jetzt.sh   (auf Zuruf, misst ueber measure-run.py)
#   tools/zonen-melder.py    (PostToolUse-Hook, misst selbst per Tail-Parse)
#
# WARUM ES DIESEN TEST GIBT
# Beide melden dieselbe Groesse und pflegen ihre Zonen-Schwellen GETRENNT
# (kontext-jetzt.sh inline, zonen-melder.py als Konstanten). Am 25.07.2026 waren
# schon einmal zwei verschiedene NAMEN fuer dieselbe Zone im Umlauf; die Zahlen
# koennen genauso auseinanderlaufen. Ein falscher Wert ist hier teurer als ein
# Absturz: meldet der Hook ARBEITEN, waehrend die Sitzung real bei 400k liegt,
# schweigt er genau dann, wenn er sprechen muesste - und die Zonen-Regel ist
# wieder Deko, unsichtbar.
#
# Deshalb wird an den GRENZWERTEN geprueft, nicht in der Mitte der Zonen: eine
# Off-by-one-Divergenz zwischen den beiden Implementierungen faellt nur dort auf.
#
# ZWEI STOLPERSTEINE, die beim Bau eine halbe Stunde gekostet haben:
# 1. `Path.home()` folgt auf Windows USERPROFILE, NICHT HOME. Bash-`~` folgt HOME.
#    Fuer einen Wegwerf-Heimatpfad muessen also BEIDE Variablen gesetzt werden,
#    USERPROFILE zusaetzlich im Windows-Format (cygpath -w).
# 2. Der Melder schweigt, wenn die Zone dieselbe ist wie beim letzten Aufruf.
#    Die Marke .zone-<uuid> muss vor jedem Fall geloescht werden, sonst misst
#    man die Wiederholungs-Logik statt der Zonen-Zuordnung.
#
# Aufruf: bash ~/.claude/skills/route/tests/zonen-gleichstand.test.sh

set -u
ECHT="$HOME/.claude/skills/route/tools"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
U="11111111-2222-3333-4444-555555555555"

ok()  { PASS=$((PASS+1)); printf '  OK   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s  -- %s\n' "$1" "$2"; }

# Wegwerf-Heimatpfad mit frischen Kopien beider Werkzeuge. Kopiert wird bei jedem
# Lauf, damit der Test immer den AKTUELLEN Stand prueft und die Sabotage-Probe
# unten das Original nie anfasst.
FAKE="$TMP/home"
mkdir -p "$FAKE/.claude/projects/ws" "$FAKE/.claude/skills/route/tools"
cp "$ECHT/zonen-melder.py" "$ECHT/kontext-jetzt.sh" "$ECHT/measure-run.py" \
   "$FAKE/.claude/skills/route/tools/" 2>/dev/null || {
     echo "  FAIL Aufbau -- Werkzeuge nicht unter $ECHT gefunden"; exit 1; }
FAKE_WIN=$(cygpath -w "$FAKE" 2>/dev/null || echo "$FAKE")

# Schreibt ein Transkript, dessen usage-Summe genau $1 ergibt.
# Format wie im echten Transkript: measure-run.py verlangt type=="assistant"
# UND message.usage; zonen-melder.py akzeptiert zusaetzlich usage auf oberster
# Ebene. Wir liefern die strengere Form, sonst prueft der Test nur eines der zwei.
fixture() {
  local summe="$1" rest=$(( $1 - 100000 - 50000 ))
  printf '%s\n' "{\"type\":\"assistant\",\"timestamp\":\"2026-07-25T10:00:00.000Z\",\"message\":{\"model\":\"claude-opus-4\",\"usage\":{\"input_tokens\":100000,\"output_tokens\":500,\"cache_creation_input_tokens\":50000,\"cache_read_input_tokens\":${rest}}}}" \
    > "$FAKE/.claude/projects/ws/$U.jsonl"
  rm -f "$FAKE/.claude/skills/route/.zone-$U"   # Stolperstein 2
}

lauf_melder()  { HOME="$FAKE" USERPROFILE="$FAKE_WIN" CLAUDE_CODE_SESSION_ID="$U" \
                 python "$FAKE/.claude/skills/route/tools/zonen-melder.py" 2>/dev/null; }
lauf_jetzt()   { HOME="$FAKE" USERPROFILE="$FAKE_WIN" CLAUDE_CODE_SESSION_ID="$U" \
                 bash "$FAKE/.claude/skills/route/tools/kontext-jetzt.sh" 2>/dev/null; }
zone_aus()     { printf '%s' "$1" | grep -oE 'ARBEITEN|PLANEN|LANDEN|HALTEPUNKT' | head -1; }

# --- Grenzwerte: unmittelbar unter und auf jeder Schwelle -----------------
# Erwartung folgt der Definition in zonen-melder.py:38-45 (`<` je Schwelle).
pruefe_grenze() {
  local summe="$1" erwartet="$2" label="$3"
  fixture "$summe"
  local zj=$(zone_aus "$(lauf_jetzt)")
  local zm=$(zone_aus "$(lauf_melder)")

  if [ "$zj" != "$erwartet" ]; then
    bad "$label kontext-jetzt" "meldet '${zj:-nichts}', erwartet $erwartet"
  elif [ "$summe" -lt 200000 ]; then
    # Unter 200k MUSS der Melder schweigen (Bauprinzip 3: leise).
    if [ -z "$zm" ]; then ok "$label  beide korrekt (Melder schweigt wie vorgesehen)"
    else bad "$label Melder" "spricht unter 200k: '$zm'"; fi
  elif [ "$zm" != "$erwartet" ]; then
    bad "$label zonen-melder" "meldet '${zm:-nichts}', erwartet $erwartet"
  elif [ "$zj" != "$zm" ]; then
    bad "$label GLEICHSTAND" "kontext-jetzt sagt $zj, zonen-melder sagt $zm"
  else
    ok "$label  beide melden $erwartet"
  fi
}

pruefe_grenze 199999 ARBEITEN   "T1 199.999"
pruefe_grenze 200000 PLANEN     "T2 200.000"
pruefe_grenze 299999 PLANEN     "T3 299.999"
pruefe_grenze 300000 LANDEN     "T4 300.000"
pruefe_grenze 399999 LANDEN     "T5 399.999"
pruefe_grenze 400000 HALTEPUNKT "T6 400.000"

# --- Sabotage-Probe (Pflicht): misst der Test ueberhaupt? -----------------
# Eine Schwelle in der KOPIE des Melders verschieben. Danach muss mindestens ein
# Grenzfall rot werden. Bleibt alles gruen, vergleicht der Test nichts und alle
# Zeilen darueber sind wertlos.
sed -i 's/^SCHWELLE_PLANEN = 300_000/SCHWELLE_PLANEN = 350_000/' \
  "$FAKE/.claude/skills/route/tools/zonen-melder.py"
fixture 300000
sabo_j=$(zone_aus "$(lauf_jetzt)")
sabo_m=$(zone_aus "$(lauf_melder)")
if [ "$sabo_j" != "$sabo_m" ]; then
  ok "T7 Sabotage-Probe  verschobene Schwelle wird erkannt ($sabo_j vs $sabo_m)"
else
  bad "T7 Sabotage-Probe" "TEST IST BLIND - Divergenz blieb unbemerkt (beide $sabo_j)"
fi

# --- T8: Drosselung innerhalb der HALTEPUNKT-Zone ------------------------
# Seit 26.07.2026 spricht HALTEPUNKT nicht mehr bei jedem Aufruf. Erwartet:
# Eintritt spricht (Zonen-WECHSEL), die zwei folgenden schweigen, der dritte
# spricht wieder (WIEDERHOLUNG_HALTEPUNKT = 3). Bewusst OHNE fixture() zwischen
# den Aufrufen - die Marke muss stehenbleiben, sonst misst man vier Eintritte.
fixture 450000
t8=""
for i in 1 2 3 4; do
  if [ -n "$(lauf_melder)" ]; then t8="${t8}J"; else t8="${t8}-"; fi
done
if [ "$t8" = "J--J" ]; then
  ok "T8 HALTEPUNKT-Takt Eintritt spricht, dann jeder 3. (Muster $t8)"
else
  bad "T8 HALTEPUNKT-Takt" "Muster $t8, erwartet J--J (J=spricht, -=schweigt)"
fi

# --- T9: Gegenprobe zur Drosselung ---------------------------------------
# Ohne diesen Fall wuerde T8 auch gruen bleiben, wenn der Melder in HALTEPUNKT
# generell verstummt waere. Ueber acht Aufrufe MUESSEN mehrere Meldungen kommen.
fixture 450000
treffer=0
for i in 1 2 3 4 5 6 7 8; do
  [ -n "$(lauf_melder)" ] && treffer=$((treffer+1))
done
if [ "$treffer" -ge 3 ]; then
  ok "T9 Druck bleibt   $treffer von 8 Aufrufen melden (Zone verstummt nicht)"
else
  bad "T9 Druck bleibt" "nur $treffer von 8 Meldungen - HALTEPUNKT ist zu leise"
fi

echo "================================"
echo "  bestanden: $PASS   durchgefallen: $FAIL"
[ "$FAIL" -eq 0 ] && echo "  ALLE FAELLE TRAGEN" || echo "  NICHT ALLE FAELLE TRAGEN"
exit "$FAIL"
