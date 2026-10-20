#!/bin/bash
# Gegenprobe v2 fuer state-byte-gate.sh — deckt die 8 Ur-Tests PLUS alle Befunde
# der drei gegnerischen Linsen ab. Jeder Fall nennt seine Herkunft.
set -u
HOOK=~/.claude/hooks/state-byte-gate.sh
LAB=$(mktemp -d)
pass=0; fail=0
DASH_A="-""a"

# GROESSEN AUS DEM HOOK ABLEITEN, NIE VERDRAHTEN.
# Warum das hier steht (30.07.2026): der Hook stand auf LIMIT=2048, waehrend
# route v2 seit dem 26.07. 4096 vorschreibt. Diese Datei hat die Drift nicht
# gemeldet, weil ihre festen Groessen (2500/3000/3009/4000) zufaellig ueber
# BEIDEN Limits lagen - jeder Fall blieb gruen, obwohl das Gate die falsche
# Grenze durchsetzte. Ein Test, der die zu pruefende Zahl selbst verdrahtet,
# kann ihre Verschiebung nicht bemerken.
LIMIT=$(sed -n 's/^LIMIT=\([0-9][0-9]*\).*/\1/p' "$HOOK" | head -1)
[ -n "${LIMIT:-}" ] || { echo "LIMIT im Hook nicht gefunden - Test misst nichts" >&2; exit 9; }
TINY=100                      # klar unter jedem denkbaren Limit
SMALL=$((LIMIT - 48))         # unter dem Limit, aber nah dran
BIG=$((LIMIT + 453))          # ueber dem Limit
HUGE=$((LIMIT * 2 + 808))     # weit ueber dem Limit (Vorzustand fuer T20)
echo "  (Limit aus dem Hook: $LIMIT B - klein $SMALL, gross $BIG, riesig $HUGE)"

mk(){ python -c "import sys;open(sys.argv[1],'w',newline='').write('x'*int(sys.argv[2]))" "$1" "$2"; }
newrepo(){ local d="$LAB/$1"; mkdir -p "$d/.planning/route/demo"; git init -q "$d" >/dev/null 2>&1; git -C "$d" config user.email t@t; git -C "$d" config user.name t; git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "REPO-INIT KAPUTT: $d" >&2; exit 9; }; echo "$d"; }

# run <cwd> <command> -> exit code
#
# Der Hook setzt ZWEI Pflichten durch: den Byte-Deckel und die Kantenmessung.
# `run` schaltet die Kantenmessung ab, damit die Byte-Faelle messen, was sie zu
# messen behaupten - sonst blockte jeder Fall hier aus dem zweiten Grund und
# T2/T18/T20 waeren gruen, ohne dass der Byte-Vergleich je gelaufen waere.
# Die Kantenmessung hat ihren eigenen Abschnitt E mit `runm`.
run(){ ( cd "$1" && printf '{"tool_input":{"command":"%s"}}' "$2" | ROUTE_MESSUNG_GATE=off bash "$HOOK" >/dev/null 2>&1; echo $? ); }

# Abschnitt E: Kantenmessung scharf, mit FESTER Kennung statt der echten aus der
# Umgebung - der Test soll dasselbe messen, ob er in einer Claude-Session laeuft
# oder in einer Konsole.
FAKE_SID="deadbeef-0000-4000-8000-00000000abcd"
FREMD_SID="99999999-0000-4000-8000-0000000099999"
# runh <hook> <cwd> <command> -> exit code
runh(){ ( cd "$2" && printf '{"tool_input":{"command":"%s"}}' "$3" | CLAUDE_CODE_SESSION_ID="$FAKE_SID" bash "$1" >/dev/null 2>&1; echo $? ); }
runm(){ runh "$HOOK" "$1" "$2"; }

chk(){ # chk <name> <erwartet> <ist> <herkunft>
  if [ "$2" = "$3" ]; then printf "  OK   %-46s %s\n" "$1" "$4"; pass=$((pass+1));
  else printf "  FAIL %-46s erwartet %s, ist %s   %s\n" "$1" "$2" "$3" "$4"; fail=$((fail+1)); fi
}

echo "=== A. Regression: die 8 Ur-Tests ==="
R=$(newrepo a)
mk "$R/.planning/route/demo/STATE.md" $BIG; git -C "$R" add .planning >/dev/null
chk "T1 uebergross+gestaget" 2 "$(run "$R" 'git commit -m test')" "Ur-Test"
mk "$R/.planning/route/demo/STATE.md" $SMALL; git -C "$R" add .planning >/dev/null
chk "T2 klein+gestaget" 0 "$(run "$R" 'git commit -m test')" "Ur-Test"
git -C "$R" commit -qm base >/dev/null 2>&1
mk "$R/.planning/route/demo/STATE.md" $BIG
echo hi > "$R/other.txt"; git -C "$R" add other.txt >/dev/null
chk "T3 uebergross ungestaget, anderer Commit" 0 "$(run "$R" 'git commit -m other')" "Ur-Test"
chk "T4 nur Text, kein commit" 0 "$(run "$R" 'echo STATE.md 2048 blah > note.txt')" "Ur-Test"
git -C "$R" add .planning >/dev/null
chk "T5 wc-Kette (realer Vorfall)" 2 "$(run "$R" 'wc -c .planning/route/demo/STATE.md && git add -A && git commit -m s')" "Ur-Test"
chk "T6 git -C auf dasselbe Repo" 2 "$(run "$R" "git -C $R commit -m s")" "Ur-Test"
git -C "$R" reset -q >/dev/null 2>&1
chk "T7 commit ${DASH_A} uebergrosse Kopie" 2 "$(run "$R" "git commit ${DASH_A} -m x")" "Ur-Test"
git -C "$R" add .planning >/dev/null
sed 's/-le "\$LIMIT"/-le 999999/' "$HOOK" > "$LAB/sabo.sh"
# ROUTE_MESSUNG_GATE=off wie in `run`: sonst blockt die Kopie aus dem ZWEITEN
# Grund (fehlende Kantenmessung) und der Fall waere rot, ohne dass der
# entschaerfte Byte-Vergleich je zur Sprache kaeme. Beim ersten Lauf nach dem
# Einbau der Kantenmessung ist genau das passiert.
chk "T8 SABOTAGE Limit entschaerft" 0 "$( ( cd "$R" && printf '{"tool_input":{"command":"git commit -m t"}}' | ROUTE_MESSUNG_GATE=off bash "$LAB/sabo.sh" >/dev/null 2>&1; echo $? ) )" "Ur-Test"

echo ""
echo "=== B. Muss NEU blocken (Linse 1+3: Umgehungen) ==="
P=$(newrepo p); mk "$P/.planning/route/demo/STATE.md" $TINY
git -C "$P" add -A >/dev/null; git -C "$P" commit -qm base >/dev/null 2>&1
mk "$P/.planning/route/demo/STATE.md" $BIG   # Arbeitskopie gross, Index klein
chk "T9 Pathspec-Commit der Arbeitskopie" 2 "$(run "$P" 'git commit -m state .planning/route/demo/STATE.md')" "L1-Blocker-1"
chk "T9b --only" 2 "$(run "$P" 'git commit --only -m s .planning/route/demo/STATE.md')" "L1-Blocker-1"

X=$(newrepo x); mk "$X/.planning/route/demo/STATE.md" $TINY
git -C "$X" add -A >/dev/null; git -C "$X" commit -qm base >/dev/null 2>&1
mk "$X/.planning/route/demo/STATE.md" $BIG; git -C "$X" add -A >/dev/null
CLEAN=$(newrepo clean); git -C "$CLEAN" commit -q --allow-empty -m base >/dev/null 2>&1
chk "T10 git -C FREMDES Repo aus sauberem cwd" 2 "$(run "$CLEAN" "git -C $X commit -m x")" "L1-Blocker-2 / L3-Blocker-1"
chk "T11 cd FREMDES Repo && commit" 2 "$(run "$CLEAN" "cd $X && git commit -m x")" "L1-Blocker-2"

S=$(newrepo s); mk "$S/.planning/route/demo/STATE.md" $TINY
git -C "$S" add -A >/dev/null; git -C "$S" commit -qm base >/dev/null 2>&1
mkdir -p "$S/tief/tiefer"; mk "$S/.planning/route/demo/STATE.md" $BIG
chk "T12 commit ${DASH_A} aus Unterverzeichnis" 2 "$(run "$S/tief/tiefer" "git commit ${DASH_A} -m x")" "L1-schwer-3 / L3-klein-3"

U=$(newrepo u); mkdir -p "$U/.planning/route/größe-test"
mk "$U/.planning/route/größe-test/STATE.md" $TINY
git -C "$U" add -A >/dev/null; git -C "$U" commit -qm base >/dev/null 2>&1
mk "$U/.planning/route/größe-test/STATE.md" $BIG; git -C "$U" add -A >/dev/null
chk "T13 Umlaut-Slug (quotePath)" 2 "$(run "$U" 'git commit -m x')" "L3-schwer-2"

# route-opus ist in SKILL.md S1 Schritt 0 ein gleichrangiger Lauf-Ort. Bis zum
# 30.07.2026 kannte der Hook nur .planning/route/ - jeder route-opus-Lauf
# committete seinen Zettel ungeprueft, in jeder Groesse.
O=$(newrepo opus); mkdir -p "$O/.planning/route-opus/demo"
mk "$O/.planning/route-opus/demo/STATE.md" $TINY
git -C "$O" add -A >/dev/null; git -C "$O" commit -qm base >/dev/null 2>&1
mk "$O/.planning/route-opus/demo/STATE.md" $BIG; git -C "$O" add -A >/dev/null
chk "T13b route-opus ist gleichrangig" 2 "$(run "$O" 'git commit -m x')" "30.07.: lief am Gate vorbei"

echo ""
echo "=== C. Darf NICHT blocken (Linse 2: Fehlalarm/Aussperrung) ==="
F=$(newrepo f); echo hi > "$F/README.md"; git -C "$F" add README.md >/dev/null
git -C "$F" commit -qm base >/dev/null 2>&1
mk "$F/.planning/route/alt/STATE.md" $BIG 2>/dev/null || { mkdir -p "$F/.planning/route/alt"; mk "$F/.planning/route/alt/STATE.md" $BIG; }
git -C "$F" add .planning >/dev/null            # fremde Parallel-Session-Arbeit im Index
echo neu >> "$F/README.md"
chk "T14 Pathspec-Form bei fremdem Index" 0 "$(run "$F" 'git commit -m docs -- README.md')" "L2-Blocker-1"
chk "T14b -o README.md" 0 "$(run "$F" 'git commit -o -m docs README.md')" "L2-Blocker-1"

I=$(newrepo inner); git -C "$I" commit -q --allow-empty -m base >/dev/null 2>&1
chk "T15 git -C SAUBERES Repo aus dreckigem cwd" 0 "$(run "$F" "git -C $I commit -m x --allow-empty")" "L2-Blocker-2"

chk "T16 echo-Erwaehnung von git commit" 0 "$(run "$F" 'echo Naechster Schritt: git commit -m msg >> NOTES.md')" "L2-schwer-3"
chk "T17 -m Message enthaelt Wort mit a-Flag" 0 "$(run "$F" 'git commit -m fix: -a Flag korrigiert -- README.md')" "L2-schwer-3"

D=$(newrepo d); mk "$D/.planning/route/demo/STATE.md" $BIG
git -C "$D" add -A >/dev/null; git -C "$D" commit -qm base >/dev/null 2>&1
rm "$D/.planning/route/demo/STATE.md"
chk "T18 geloeschte STATE.md + commit ${DASH_A}" 0 "$(run "$D" "git commit ${DASH_A} -m weg")" "L3-klein-4"

M=$(newrepo m); echo a > "$M/a.txt"; git -C "$M" add -A >/dev/null; git -C "$M" commit -qm base >/dev/null 2>&1
git -C "$M" checkout -qb feature >/dev/null 2>&1
mk "$M/.planning/route/demo/STATE.md" $BIG; git -C "$M" add -A >/dev/null; git -C "$M" commit -qm feat >/dev/null 2>&1
git -C "$M" checkout -q master >/dev/null 2>&1 || git -C "$M" checkout -q main >/dev/null 2>&1
git -C "$M" merge --no-ff --no-commit feature >/dev/null 2>&1
chk "T19 Merge-Commit bringt fremde grosse Datei" 0 "$(run "$M" 'git commit -m merge')" "L2-schwer-4"

K=$(newrepo k); mk "$K/.planning/route/demo/STATE.md" $HUGE
git -C "$K" add -A >/dev/null; git -C "$K" commit -qm base >/dev/null 2>&1
mk "$K/.planning/route/demo/STATE.md" $BIG; git -C "$K" add -A >/dev/null
chk "T20 Kuerzungs-Commit $HUGE -> $BIG" 0 "$(run "$K" 'git commit -m kuerzen')" "L2-schwer-4"

A=$(newrepo arch); mk "$A/.planning/route/l1/STATE.md" $BIG 2>/dev/null || { mkdir -p "$A/.planning/route/l1"; mk "$A/.planning/route/l1/STATE.md" $BIG; }
git -C "$A" add -A >/dev/null; git -C "$A" commit -qm base >/dev/null 2>&1
git -C "$A" mv .planning/route/l1 .planning/route/archiv-l1 >/dev/null 2>&1
chk "T21 Archivierung per git mv (kein neues Byte)" 0 "$(run "$A" 'git commit -m archiv')" "L2-schwer-4"

I2=$(newrepo import); mkdir -p "$I2/.planning/route/alt"; mk "$I2/.planning/route/alt/STATE.md" $BIG
git -C "$I2" add -A >/dev/null
chk "T22 Erst-Commit blockt bewusst (Notausgang)" 2 "$(run "$I2" 'git commit -m initial')" "Entscheid: primaerer Fall schlaegt Import"
chk "T22b Notausgang ROUTE_STATE_GATE=off" 0 "$( ( cd "$I2" && ROUTE_STATE_GATE=off bash -c "printf '{\"tool_input\":{\"command\":\"git commit -m initial\"}}' | bash '$HOOK'" >/dev/null 2>&1; echo $? ) )" "Notausgang traegt"

N=$(newrepo nonrepo)
chk "T23 ausserhalb jedes Repos" 0 "$(run "$LAB" 'git commit -m x')" "L1/L3-Randfall"
chk "T24 gar kein git-Befehl" 0 "$(run "$F" 'ls -la')" "Grundfall"

echo ""
echo "=== E. Kantenmessung: Zettel-Commit ohne eigene Messzeile ==="
# Der Schnitt committet immer die STATE.md. Genau dort wird geprueft, ob die
# Session ihre Zeile geschrieben hat - Durchsetzung im Gate statt in Prosa.
E=$(newrepo mess); mk "$E/.planning/route/demo/STATE.md" $SMALL
git -C "$E" add -A >/dev/null; git -C "$E" commit -qm base >/dev/null 2>&1
mk "$E/.planning/route/demo/STATE.md" $SMALL; echo x >> "$E/.planning/route/demo/STATE.md"
git -C "$E" add -A >/dev/null
chk "E1 keine MESSUNG.md" 2 "$(runm "$E" 'git commit -m schnitt')" "der eigentliche Zweck"

printf '| %s | 30.07. 10:00 | 30.07. 11:00 |\n' "$FAKE_SID" > "$E/.planning/route/demo/MESSUNG.md"
chk "E2 eigene Kennung steht drin" 0 "$(runm "$E" 'git commit -m schnitt')" "erfuellte Auflage laesst durch"

printf '| %s | 30.07. 10:00 | 30.07. 11:00 |\n' "$FREMD_SID" > "$E/.planning/route/demo/MESSUNG.md"
chk "E3 nur FREMDE Kennung" 2 "$(runm "$E" 'git commit -m schnitt')" "Datei da reicht nicht"

chk "E4 ohne CLAUDE_CODE_SESSION_ID" 0 \
  "$( ( cd "$E" && printf '{"tool_input":{"command":"git commit -m s"}}' | env -u CLAUDE_CODE_SESSION_ID bash "$HOOK" >/dev/null 2>&1; echo $? ) )" \
  "nie unloesbar blocken (Commit von aussen)"
chk "E5 Notausgang ROUTE_MESSUNG_GATE=off" 0 \
  "$( ( cd "$E" && printf '{"tool_input":{"command":"git commit -m s"}}' | CLAUDE_CODE_SESSION_ID="$FAKE_SID" ROUTE_MESSUNG_GATE=off bash "$HOOK" >/dev/null 2>&1; echo $? ) )" \
  "benannte Ausnahme, eigener Schalter"
chk "E5b ROUTE_STATE_GATE=off deckt beides" 0 \
  "$( ( cd "$E" && printf '{"tool_input":{"command":"git commit -m s"}}' | CLAUDE_CODE_SESSION_ID="$FAKE_SID" ROUTE_STATE_GATE=off bash "$HOOK" >/dev/null 2>&1; echo $? ) )" \
  "Kill-Switch bleibt Kill-Switch"

EO=$(newrepo messopus); mkdir -p "$EO/.planning/route-opus/demo"
mk "$EO/.planning/route-opus/demo/STATE.md" $SMALL
git -C "$EO" add -A >/dev/null
chk "E6 route-opus ebenfalls erfasst" 2 "$(runm "$EO" 'git commit -m schnitt')" "gleichrangiger Lauf-Ort"

ED=$(newrepo messdel); mk "$ED/.planning/route/demo/STATE.md" $SMALL
git -C "$ED" add -A >/dev/null; git -C "$ED" commit -qm base >/dev/null 2>&1
git -C "$ED" rm -q .planning/route/demo/STATE.md >/dev/null 2>&1
chk "E7 STATE.md wird geloescht" 0 "$(runm "$ED" 'git commit -m archiv')" "kein Messzwang beim Aufraeumen"

EN=$(newrepo messfremd); echo hi > "$EN/README.md"; git -C "$EN" add -A >/dev/null
chk "E8 Commit ohne route-STATE.md" 0 "$(runm "$EN" 'git commit -m docs')" "kein Fehlalarm ausserhalb"

# Eigener Code-Pfad als T13: dort loest git die Pfade auf, hier eine
# while-read-Schleife. Umlaut UND Leerzeichen im Slug in einem Fall.
EU=$(newrepo messumlaut); mkdir -p "$EU/.planning/route/größe test"
mk "$EU/.planning/route/größe test/STATE.md" $TINY
git -C "$EU" add -A >/dev/null
chk "E8b Umlaut+Leerzeichen im Slug blockt" 2 "$(runm "$EU" 'git commit -m x')" "IFS= read -r haelt Pfade zusammen"
printf '| %s |\n' "$FAKE_SID" > "$EU/.planning/route/größe test/MESSUNG.md"
chk "E8c derselbe Slug mit Messzeile" 0 "$(runm "$EU" 'git commit -m x')" "und laesst dann durch"

# SABOTAGE: die Kennungs-Pruefung entschaerfen -> E1 MUSS gruen werden. Bleibt
# er rot, blockt der Hook aus einem anderen Grund und E1 waere kein Zeuge.
python - "$HOOK" "$LAB/sabo-mess.sh" <<'PY'
import io, sys
s = io.open(sys.argv[1], encoding="utf-8", newline="").read()
alt = '    if ! grep -qF "$CLAUDE_CODE_SESSION_ID" "$LAUFDIR/MESSUNG.md" 2>/dev/null; then'
neu = '    if false; then'
assert s.count(alt) == 1, "Sabotage-Anker nicht eindeutig"
io.open(sys.argv[2], "w", encoding="utf-8", newline="").write(s.replace(alt, neu))
PY
rm -f "$E/.planning/route/demo/MESSUNG.md"
chk "E9a Kopie unveraendert blockt weiter" 2 "$(runh "$HOOK" "$E" 'git commit -m s')" "Kontrolle vor der Sabotage"
chk "E9b SABOTAGE entschaerft -> E1 kippt" 0 "$(runh "$LAB/sabo-mess.sh" "$E" 'git commit -m s')" "sonst waere die Pruefung Deko"

# ── Abschnitt X: Ausfall-Sichtbarkeit (16.08.) ────────────────────────────────
# Extraktion kaputt (node fehlt/crasht) -> exit 0 + WARN auf stderr + Logzeile
# im isolierten HOME. Fail-Open ist Absicht; still war er der Audit-Befund
# vom 15.08. Die Block-Regression liefern die bestehenden Faelle oben.
xa(){
  local nr="$1" pfad="$2" rcmuster="$3"
  local FH; FH=$(mktemp -d)
  local errf="$LAB/xa-stderr.txt"
  ( cd "$LAB" && printf '{"tool_input":{"command":"git commit -m x"}}' \
    | env PATH="$pfad" HOME="$FH" ROUTE_MESSUNG_GATE=off bash "$HOOK" >/dev/null 2>"$errf" )
  local got=$?
  if [ "$got" = "0" ] && grep -q "WARN" "$errf" \
     && grep -q "$rcmuster" "$FH/.claude/.cache/gate_ausfall.log" 2>/dev/null; then
    pass=$((pass+1)); echo "PASS Xa$nr Ausfall sichtbar: exit 0 + WARN + Logzeile $rcmuster"
  else
    fail=$((fail+1)); echo "FAIL Xa$nr Ausfall stumm oder blockt (exit $got, Muster $rcmuster)"
  fi
  rm -rf "$FH"
}
xa 1 "/usr/bin:/bin" "rc=127"
FAKEBIN=$(mktemp -d); printf '#!/bin/sh\nexit 1\n' > "$FAKEBIN/node"; chmod +x "$FAKEBIN/node"
xa 2 "$FAKEBIN:$PATH" "rc=1"
rm -rf "$FAKEBIN"
# Xa3: TEIL-Ausfall (fremde Abnahme 16.08., Szenario d2): die Extraktion
# laeuft (1. node-Aufruf echt), norm_bytes crasht (ab 2. Aufruf exit 1).
# Eine uebergrosse STATE.md darf dann NICHT still passieren: exit 0 ist
# weiter richtig (fail-open), aber WARN + norm_bytes-leer-Logzeile Pflicht.
# Vorher stand an der Stelle ein nacktes `continue` — nie-rote Messung.
XR=$(newrepo xa3repo)
mk "$XR/.planning/route/demo/STATE.md" "$BIG"
git -C "$XR" add .planning/route/demo/STATE.md >/dev/null 2>&1
REALNODE=$(command -v node)
FAKEBIN3=$(mktemp -d)
cat > "$FAKEBIN3/node" <<EOF
#!/bin/sh
cnt="\$(cat "$FAKEBIN3/count" 2>/dev/null || echo 0)"
echo \$((cnt+1)) > "$FAKEBIN3/count"
[ "\$cnt" -ge 1 ] && exit 1
exec "$REALNODE" "\$@"
EOF
chmod +x "$FAKEBIN3/node"
FH3=$(mktemp -d); errf3="$LAB/xa3-stderr.txt"
( cd "$XR" && printf '{"tool_input":{"command":"git commit -m x"}}' \
  | env PATH="$FAKEBIN3:$PATH" HOME="$FH3" ROUTE_MESSUNG_GATE=off bash "$HOOK" >/dev/null 2>"$errf3" )
got=$?
if [ "$got" = "0" ] && grep -q "Byte-Messung" "$errf3" \
   && grep -q "norm_bytes-leer" "$FH3/.claude/.cache/gate_ausfall.log" 2>/dev/null; then
  pass=$((pass+1)); echo "PASS Xa3 Teil-Ausfall sichtbar: WARN + norm_bytes-leer-Logzeile"
else
  fail=$((fail+1)); echo "FAIL Xa3 Teil-Ausfall stumm (exit $got) — nie-rote Messung zurueck?"
fi
rm -rf "$FAKEBIN3" "$FH3"
# Xa4: git fehlt im PATH, node intakt (Kreativ-Probe der fremden Abnahme
# 16.08.) -> exit 0 + WARN "git nicht verfuegbar" + Logzeile git-rc=127.
# Kontrolle Xa5: cwd AUSSERHALB eines Repos mit intaktem git bleibt voellig
# still (kein Log!) — sonst spammt jeder Nicht-Repo-Bash-Call das Log.
REALNODE=$(command -v node)
FAKEBIN4=$(mktemp -d)
printf '#!/bin/sh\nexec "%s" "$@"\n' "$REALNODE" > "$FAKEBIN4/node"
chmod +x "$FAKEBIN4/node"
FH4=$(mktemp -d); errf4="$LAB/xa4-stderr.txt"
( cd "$XR" && printf '{"tool_input":{"command":"git commit -m x"}}' \
  | env PATH="$FAKEBIN4:/usr/bin:/bin" HOME="$FH4" ROUTE_MESSUNG_GATE=off bash "$HOOK" >/dev/null 2>"$errf4" )
got=$?
if [ "$got" = "0" ] && grep -q "git nicht verfuegbar" "$errf4" \
   && grep -q "git-rc=127" "$FH4/.claude/.cache/gate_ausfall.log" 2>/dev/null; then
  pass=$((pass+1)); echo "PASS Xa4 git-Ausfall sichtbar: WARN + git-rc=127-Logzeile"
else
  fail=$((fail+1)); echo "FAIL Xa4 git-Ausfall stumm (exit $got)"
fi
NOREPO=$(mktemp -d); FH5=$(mktemp -d); errf5="$LAB/xa5-stderr.txt"
( cd "$NOREPO" && printf '{"tool_input":{"command":"git commit -m x"}}' \
  | env HOME="$FH5" ROUTE_MESSUNG_GATE=off bash "$HOOK" >/dev/null 2>"$errf5" )
got=$?
if [ "$got" = "0" ] && [ ! -s "$errf5" ] && [ ! -f "$FH5/.claude/.cache/gate_ausfall.log" ]; then
  pass=$((pass+1)); echo "PASS Xa5 Nicht-Repo bleibt lautlos (kein WARN, kein Log)"
else
  fail=$((fail+1)); echo "FAIL Xa5 Nicht-Repo erzeugt Spur oder blockt (exit $got)"
fi
rm -rf "$FAKEBIN4" "$FH4" "$NOREPO" "$FH5"

echo ""
echo "================================"
echo "  bestanden: $pass   durchgefallen: $fail"
[ "$fail" = "0" ] && echo "  ALLE FAELLE TRAGEN" || echo "  NACHBESSERN NOETIG"
cd /; rm -rf "$LAB"
