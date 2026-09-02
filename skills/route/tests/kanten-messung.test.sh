#!/bin/bash
# Gegenprobe fuer tools/kanten-messung.py.
#
# WOZU: die einzige Aufgabe des Berichts ist, eine LUECKE zu benennen statt eine
# kleinere Summe als vollstaendig auszuweisen. Ein Bericht, der das verlernt,
# sieht von aussen identisch aus - er sagt nur oefter "GESAMT". Genau diese
# Klasse heisst in STATE-TEMPLATE.md FALSCH-GRUEN. Deshalb enthaelt diese Datei
# eine Sabotage-Probe: wird die Luecken-Pruefung entschaerft, MUSS ein Fall
# kippen, sonst waere die Pruefung Deko.
#
# Aufruf: bash ~/.claude/skills/route/tests/kanten-messung.test.sh
set -u
TOOL="$HOME/.claude/skills/route/tools/kanten-messung.py"
LAB=$(mktemp -d)
pass=0; fail=0

chk(){ # chk <name> <erwartet> <ist> <warum>
  if [ "$2" = "$3" ]; then printf "  OK   %-44s %s\n" "$1" "$4"; pass=$((pass+1));
  else printf "  FAIL %-44s erwartet %s, ist %s  %s\n" "$1" "$2" "$3" "$4"; fail=$((fail+1)); fi
}

R="$LAB/.planning/route/demo"
mkdir -p "$R"

# Feste Zeilen statt echter Messung: der Bericht ist die zu pruefende Einheit.
# Eine echte Messung braeuchte ein Transkript und machte den Test von der
# Umgebung abhaengig, in der er gerade laeuft.
zeilen(){ cat > "$R/MESSUNG.md" <<'EOF'
# MESSUNG — demo

| Session | von | bis | Anf | Sub | Ktx-Start | Ktx-Mittel | Ktx-Anz | Ktx-Spitze | Ktx-Ende | Cache-Read | Kosten $ |
|---|---|---|---|---|---|---|---|---|---|---|---|
| aaaaaaaa-1111-4111-8111-000000000001 | 29.07. 09:00 | 29.07. 11:00 | 30 | 4 | 71.000 | 140.000 | 30 | 210.000 | 205.000 | 3.000.000 | 6,40 |
| bbbbbbbb-2222-4222-8222-000000000002 | 29.07. 12:00 | 29.07. 14:00 | 20 | 0 | 74.000 | 160.000 | 20 | 230.000 | 228.000 | 2.000.000 | 5,10 |
EOF
}

lauf(){ ( cd "$LAB" && python "$1" .planning/route/demo --bericht >"$LAB/out.txt" 2>&1; echo $? ); }
hat(){ grep -qF "$1" "$LAB/out.txt" && echo ja || echo nein; }

echo "=== A. Gruen-Vorlauf: Zettel und Kanten decken sich ==="
zeilen
printf 'Basis: abc1234 \xc2\xb7 Sessions: aaaaaaaa,bbbbbbbb\n' > "$R/STATE.md"
chk "T1 vollstaendig -> exit 0" 0 "$(lauf "$TOOL")" "ohne diesen Fall misst der Rest nichts"
chk "T1b Gesamtzahl wird ausgewiesen" ja "$(hat 'GESAMT (alle Kanten')" "Summe 11,50 \$"
chk "T1c gepoolter Mittelwert, nicht Mittel der Mittel" ja "$(hat '148.000')" "(140k*30+160k*20)/50"

echo ""
echo "=== B. Muss eine LUECKE benennen (Summe wird zurueckgehalten) ==="
zeilen
printf 'Basis: abc1234 \xc2\xb7 Sessions: aaaaaaaa,bbbbbbbb,cccccccc\n' > "$R/STATE.md"
chk "T2 Kante ohne Messung -> exit 1" 1 "$(lauf "$TOOL")" "der Rotations-/Abbruch-Fall"
chk "T2b nennt die fehlende Kennung" ja "$(hat 'cccccccc')" "Luecke benannt, nicht verschwiegen"
chk "T2c KEINE Gesamtzahl" nein "$(hat 'GESAMT (alle Kanten')" "weggelassen statt geschaetzt"

zeilen
# Die Tippfehler-Klasse: am 30.07.2026 real in zwei von drei Laeufen gefunden
# (08399, cd0cba7e - Kennungen, die nie eine Datei getragen haben).
printf 'Basis: abc1234 \xc2\xb7 Sessions: aaaaaaaa,bbbb9999\n' > "$R/STATE.md"
chk "T3 Tippfehler im Zettel -> exit 1" 1 "$(lauf "$TOOL")" "Phantom-Kennung"
chk "T3b nennt das Phantom" ja "$(hat 'bbbb9999')" "Richtung Zettel -> Kante"
chk "T3c nennt die verwaiste Messung" ja "$(hat 'ZETTEL UNVOLLSTAENDIG')" "Richtung Kante -> Zettel"

zeilen
rm -f "$R/STATE.md"
chk "T4 gar keine Sessions-Liste -> exit 1" 1 "$(lauf "$TOOL")" "der ueber-uns-nextlevel-Fall"
chk "T4b nennt den billigen Fix" ja "$(hat 'siehe MESSUNG.md')" "Auflage muss erfuellbar sein"

printf '# MESSUNG\n' > "$R/MESSUNG.md"
printf 'Basis: abc1234 \xc2\xb7 Sessions: siehe MESSUNG.md\n' > "$R/STATE.md"
chk "T5 keine einzige Kantenzeile -> exit 1" 1 "$(lauf "$TOOL")" "leere Datei ist keine Null"

echo ""
echo "=== C. Darf NICHT blocken ==="
zeilen
printf 'Basis: abc1234 \xc2\xb7 Sessions: siehe MESSUNG.md\n' > "$R/STATE.md"
chk "T6 Zettel tritt an MESSUNG.md ab -> exit 0" 0 "$(lauf "$TOOL")" "Byte-Budget-Ausweg, bewusst"

zeilen
# Praefixe sind der Normalfall: der Zettel kuerzt sie wegen des Byte-Budgets.
printf 'Basis: abc1234 \xc2\xb7 Sessions: aaaaa,bbbbb\n' > "$R/STATE.md"
chk "T7 Kurz-Praefixe im Zettel -> exit 0" 0 "$(lauf "$TOOL")" "5-Zeichen-Kennungen sind gueltig"

zeilen
printf 'Basis: abc1234 \xc2\xb7 Sessions: aaaaaaaa,bbbbbbbb (Vollliste in f57a334^)\n' > "$R/STATE.md"
chk "T8 Klammer-Prosa ist keine Kennung" 0 "$(lauf "$TOOL")" "realer wissens-center-Zettel"

zeilen
# CRLF hat am 30.07.2026 live einen Rotations-Fehlbefund erzeugt.
printf 'Basis: abc1234 \xc2\xb7 Sessions: aaaaaaaa,bbbbbbbb\r\n' > "$R/STATE.md"
chk "T9 Windows-Zeilenende im Zettel -> exit 0" 0 "$(lauf "$TOOL")" "\\r darf keine Kennung zerstoeren"

echo ""
echo "=== D. Sabotage: ist die Luecken-Pruefung ueberhaupt scharf? ==="
# Luecken-Liste am Ende leeren -> T2 MUSS gruen werden. Bleibt er rot, misst
# der Test etwas anderes als die Pruefung, die er zu pruefen behauptet.
#
# Die Kopie MUSS neben measure-run.py liegen: kanten-messung.py laedt den
# Messer aus seinem eigenen Ordner. Eine Kopie im leeren Verzeichnis stirbt
# schon beim Import und liefert ebenfalls Exit 1 - der Fall waere dann gruen
# aus dem falschen Grund, also gar kein Zeuge. (Genau so ist dieser Test beim
# ersten Lauf durchgefallen.)
mkdir -p "$LAB/werkzeug"
cp "$(dirname "$TOOL")"/*.py "$LAB/werkzeug/"
python - "$TOOL" "$LAB/werkzeug/sabo.py" <<'PY'
import io, sys
s = io.open(sys.argv[1], encoding="utf-8").read()
alt = '        "luecken": luecken,'
neu = '        "luecken": [],'
assert s.count(alt) == 1, "Anker fuer die Sabotage nicht eindeutig"
io.open(sys.argv[2], "w", encoding="utf-8").write(s.replace(alt, neu))
PY
zeilen
printf 'Basis: abc1234 \xc2\xb7 Sessions: aaaaaaaa,bbbbbbbb,cccccccc\n' > "$R/STATE.md"
# Kontrolle vor der Sabotage: die unveraenderte KOPIE muss sich genauso
# verhalten wie das Original (exit 1). Ohne sie beweist T10 nur, dass die
# Kopie laeuft - nicht, dass die Luecken-Pruefung sie rot faerbt.
chk "T10a Kopie unveraendert -> weiter exit 1" 1 "$(lauf "$LAB/werkzeug/kanten-messung.py")" "Kontrolle gegen den Import-Tod"
chk "T10b SABOTAGE entschaerft -> T2 kippt auf 0" 0 "$(lauf "$LAB/werkzeug/sabo.py")" "sonst waere die Pruefung Deko"

echo ""
echo "================================"
echo "  bestanden: $pass   durchgefallen: $fail"
[ "$fail" = "0" ] && echo "  ALLE FAELLE TRAGEN" || echo "  NACHBESSERN NOETIG"
cd /; rm -rf "$LAB"
[ "$fail" = "0" ]
