#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# kante.sh - der Kanten-Ritus als ein Befehl (Route v2.2, 01.09.2026).
#
# WOZU: Jede Schnittkante bestand aus 5-6 Handgriffen (Byte-Check per
# handgetipptem python -c, kanten-messung.py, kontext-jetzt.sh, Abgleich,
# Commit-Gate). Bei 10-16 Boss-Sitzen je Lauf sind das 60-90 manuelle
# Schritte - jeder eine Vergessens-Chance, und LESSONS.md dokumentiert genau
# solche uebersprungenen Schritte. Dieses Werkzeug buendelt die Mechanik;
# das URTEIL (Narben, Selbsttest, "Naechster Schritt") bleibt Modellarbeit.
#
# ZWEI PHASEN (Henne-Ei, gemessen im Plan-Review 01.09.2026): die
# KONTEXT-Zahl muss erst gemessen, dann vom Modell in den Zettel geschrieben
# und erst DANACH geprueft werden.
#
#   bash kante.sh --messen  <run-dir>   vor dem Zettel-Fuellen:
#       1. kontext-jetzt.sh  - Zone + Zahl fuer die "Kante:"-Zeile
#       2. kanten-messung.py - Messzeile DIESER Session nach MESSUNG.md
#   -> dann fuellt das MODELL die STATE.md (Template lesen!)
#   bash kante.sh --pruefen <run-dir>   nach dem Zettel-Fuellen:
#       Ampel GRUEN/ROT ueber: Byte-Grenze (LF-normalisiert, wie
#       hooks/state-byte-gate.sh), Messzeile dieser Session, Branch gegen
#       die "Abgleich:"-Zeile, Basis-SHA als Vorfahr von HEAD, und die
#       "## Naechster Schritt"-Zeile (nur EXISTENZ + Woertlichkeit - das
#       Werkzeug zitiert sie, es erzeugt sie NIE).
#
# ABGLEICH GEGEN "Abgleich:", NIE GEGEN "Basis:" (Plan-Review 01.09.2026):
# Basis ist der eingefrorene Lauf-Beginn fuer den S4-Diff-Review
# (STATE-TEMPLATE.md) - nach dem ersten Etappen-Commit waere jede Kante
# sonst rot. Basis wird nur als Vorfahr von HEAD geprueft.
#
# Der Arbeitsbaum-Zustand wird ANGEZEIGT, nicht bewertet: an der Kante vor
# dem Commit ist der Baum naturgemaess dirty (die STATE.md selbst).
#
# FAIL-CLOSED: ein fehlendes Werkzeug, eine unlesbare Datei, eine fehlende
# Umgebungsvariable ist ROT mit benanntem Grund - nie stilles Gruen.
# Letzte Instanz bleibt hooks/state-byte-gate.sh am Commit; dieses Werkzeug
# ist die Vorwarnung derselben zwei geteilten Kriterien (Bytes, Messzeile).
# Gleichstand haelt tests/kante-gleichstand.test.sh ehrlich.
#
# Exit: 0 = GRUEN, 1 = ROT, 2 = Aufruf-Fehler.
# ---------------------------------------------------------------------------
set -uo pipefail

SKILLDIR="C:/Users/User/.claude/skills/route"
LIMIT=4096

usage() { echo "Aufruf: $0 --messen|--pruefen <run-dir>" >&2; exit 2; }
[ $# -eq 2 ] || usage
PHASE="$1"; LAUFDIR="$2"
[ -d "$LAUFDIR" ] || { echo "ROT: Run-Verzeichnis fehlt: $LAUFDIR" >&2; exit 1; }

rot() { echo "KANTE: ROT — $1"; FEHLER=1; }
FEHLER=0

case "$PHASE" in
  --messen)
    # 1. Zone + Zahl. Fail-closed: ohne Messung keine "Kante:"-Zeile.
    if ! bash "$SKILLDIR/tools/kontext-jetzt.sh"; then
      echo "KANTE: ROT — kontext-jetzt.sh liefert keinen Stand (Session-ID? Transkript?)."
      exit 1
    fi
    # 2. Messzeile dieser Session anhaengen (kanten-messung.py ist idempotent
    #    pro Aufruf gedacht; doppelte Zeilen tun dem Gate nicht weh, dem
    #    Bericht schon - deshalb nur einmal je Kante aufrufen).
    if ! python "$SKILLDIR/tools/kanten-messung.py" "$LAUFDIR"; then
      echo "KANTE: ROT — kanten-messung.py konnte die Messzeile nicht schreiben."
      exit 1
    fi
    echo ""
    echo "GEMESSEN. Jetzt fuellt das MODELL die STATE.md (Template:"
    echo "  $SKILLDIR/STATE-TEMPLATE.md — Narben, Selbsttest, Naechster Schritt),"
    echo "danach: bash $SKILLDIR/tools/kante.sh --pruefen $LAUFDIR"
    exit 0
    ;;

  --pruefen)
    STATE="$LAUFDIR/STATE.md"
    [ -r "$STATE" ] || { echo "KANTE: ROT — $STATE fehlt oder unlesbar."; exit 1; }

    # a) Byte-Grenze, LF-normalisiert — dasselbe Kriterium wie norm_bytes im
    #    Commit-Hook (CRLF -> LF, dann Bytes zaehlen).
    BYTES="$(python -c "import sys;print(len(open(sys.argv[1],'rb').read().replace(b'\r\n',b'\n')))" "$STATE" 2>/dev/null)"
    case "$BYTES" in
      ''|*[!0-9]*) rot "Byte-Check nicht durchfuehrbar (python?)." ;;
      *) [ "$BYTES" -le "$LIMIT" ] || rot "STATE.md hat $BYTES B (Limit $LIMIT, $((BYTES - LIMIT)) zu viel)." ;;
    esac

    # b) Messzeile DIESER Session — dasselbe Kriterium wie das Messungs-Gate
    #    im Commit-Hook (grep -qF auf MESSUNG.md).
    if [ -z "${CLAUDE_CODE_SESSION_ID:-}" ]; then
      rot "CLAUDE_CODE_SESSION_ID ist nicht gesetzt — Messzeile nicht pruefbar (fail-closed)."
    elif ! grep -qF "$CLAUDE_CODE_SESSION_ID" "$LAUFDIR/MESSUNG.md" 2>/dev/null; then
      rot "MESSUNG.md traegt keine Zeile dieser Session — erst kante.sh --messen fahren."
    fi

    # c) Branch gegen die Abgleich-Zeile (NICHT gegen Basis).
    JETZT_BRANCH="$(git -C "$LAUFDIR" branch --show-current 2>/dev/null)"
    ZETTEL_BRANCH="$(python - "$STATE" <<'PY'
import io, re, sys
s = io.open(sys.argv[1], encoding="utf-8", errors="replace").read()
m = re.search(r"^Abgleich:.*?Branch\s+(\S+)", s, re.M)
print(m.group(1) if m else "")
PY
)"
    if [ -z "$JETZT_BRANCH" ]; then
      rot "git branch --show-current liefert nichts (detached HEAD oder kein Repo?)."
    elif [ -z "$ZETTEL_BRANCH" ] || [[ "$ZETTEL_BRANCH" == "<"* ]]; then
      rot "Abgleich-Zeile traegt keinen Branch (fehlt oder Platzhalter) — Zettel fuellen."
    elif [ "$ZETTEL_BRANCH" != "$JETZT_BRANCH" ]; then
      rot "Branch weicht ab: Zettel '$ZETTEL_BRANCH', gemessen '$JETZT_BRANCH' (drei Etappen gingen so schon an einen fremden Branch)."
    fi

    # d) Basis-SHA ist Vorfahr von HEAD (eingefroren fuer den Diff-Review;
    #    Gleichheit mit HEAD ist NICHT verlangt).
    BASIS_SHA="$(python - "$STATE" <<'PY'
import io, re, sys
s = io.open(sys.argv[1], encoding="utf-8", errors="replace").read()
m = re.search(r"^Basis:\s*([0-9a-fA-F]{7,40})", s, re.M)
print(m.group(1) if m else "")
PY
)"
    if [ -z "$BASIS_SHA" ]; then
      rot "Basis-Zeile traegt keinen SHA (fehlt oder Platzhalter) — der Diff-Review haette keinen Anker."
    elif ! git -C "$LAUFDIR" merge-base --is-ancestor "$BASIS_SHA" HEAD 2>/dev/null; then
      rot "Basis $BASIS_SHA ist kein Vorfahr von HEAD — falscher Zettel, falsches Repo oder umgeschriebene Historie."
    fi

    # e) "## Naechster Schritt": Existenz + Woertlichkeit. Nur zitieren.
    NAECHSTER="$(python - "$STATE" <<'PY'
import io, re, sys
s = io.open(sys.argv[1], encoding="utf-8", errors="replace").read()
m = re.search(r"^##\s*N\S*chster Schritt\s*$(.*?)(?=^##\s|\Z)", s, re.M | re.S)
if not m:
    sys.exit(0)
koerper = re.sub(r"<!--.*?-->", "", m.group(1), flags=re.S)
for zeile in koerper.splitlines():
    z = zeile.strip()
    if z:
        print(z)
        break
PY
)"
    if [ -z "$NAECHSTER" ]; then
      rot "'## Naechster Schritt' fehlt oder ist leer — die naechste Session haette keine Bruecke."
    elif printf '%s' "$NAECHSTER" | grep -q "<[^>]*>"; then
      rot "'Naechster Schritt' traegt einen Platzhalter statt eines woertlichen Befehls: $NAECHSTER"
    fi

    # f) Arbeitsbaum: nur anzeigen (an der Kante vor dem Commit naturgemaess
    #    dirty — mindestens die STATE.md selbst).
    BAUM="$(git -C "$LAUFDIR" status --porcelain 2>/dev/null | head -5)"

    echo ""
    if [ "$FEHLER" -eq 0 ]; then
      echo "KANTE: GRUEN — schneiden erlaubt."
      echo "  STATE.md: $BYTES B (Limit $LIMIT) · Branch $JETZT_BRANCH · Basis $BASIS_SHA ist Vorfahr."
      echo "  Naechster Schritt (zitiert): $NAECHSTER"
      if [ -n "$BAUM" ]; then
        echo "  Baum (dirty ist hier normal — STATE.md committen):"
        printf '%s\n' "$BAUM" | sed 's/^/    /'
      fi
      echo "  Letzte Instanz bleibt der Commit-Hook (state-byte-gate)."
      exit 0
    else
      echo "KANTE: ROT — NICHT schneiden. Gruende oben, jeder einzeln beheben."
      exit 1
    fi
    ;;

  *) usage ;;
esac
