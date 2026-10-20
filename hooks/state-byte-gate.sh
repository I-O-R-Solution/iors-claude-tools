#!/bin/bash
# state-byte-gate.sh — PreToolUse (Bash): haelt den Byte-Deckel der route-STATE.md durch.
#
# DER DECKEL IST 4096 B (30.07.2026 nachgezogen). Er stand hier bis dahin auf
# 2048 und war damit STRENGER als die Regel, die er durchsetzen soll: route v2
# hat das Budget am 26.07. auf 4096 angehoben (skills/route/SKILL.md Abschnitt
# "Cutting and resuming" und skills/route/STATE-TEMPLATE.md "Harte Grenze"),
# der Hook blieb auf dem alten Wert stehen. Folge waren Blocks auf Zettel, die
# der Regel entsprachen — und ein blockierter Hook wird per ROUTE_STATE_GATE=off
# abgeschaltet, womit ALLE Pruefungen hier fallen. Die Zahl steht deshalb nur an
# EINER Stelle (LIMIT unten); die Gegenprobe liest sie aus dieser Datei, statt
# eigene Groessen zu verdrahten — genau daran ist die Drift entstanden.
#
# WARUM DIESER HOOK EXISTIERT (Memory-Audit 2026-07-25):
#   Die Regel "Byte-Check VOR dem Commit, nie danach" stand seit 23.07. woertlich
#   in skills/route/SKILL.md — und wurde in den 2 Tagen danach achtmal gebrochen.
#   Immer derselbe Mechanismus: `wc -c STATE.md && git add … && git commit …`.
#   `wc` druckt die Zahl und exitet 0, egal was dort steht. Eine Messung, deren
#   Wert keine Verzweigung anfasst, ist Protokoll, kein Gate.
#   Belege: episodes/2026-07/2026-07-23_{6ef275df,e55e3103,db100c9e,7002165c,9c9dd270}.md,
#           episodes/2026-07/2026-07-24_{00793b80,7e08ba30,56d27d28}.md
#
# ── GARANTIE-REGISTER ────────────────────────────────────────────────────────
# ERKENNEND fuer (per Gegenprobe belegt, siehe Testliste unten):
#   - `git commit` im Arbeitsverzeichnis, gestagete STATE.md ueber Limit
#   - `git -C <pfad> commit` und fuehrendes `cd <pfad> && … git commit`
#     (Ziel-Repo wird aus dem Befehl aufgeloest, nicht aus der eigenen cwd)
#   - Pathspec-Commits (`git commit … <pfad>`, `--only`, `--include`) — dort
#     zaehlt die ARBEITSKOPIE, weil git bei Pathspec den Index uebergeht
#   - `git commit -a/--all`, auch aus einem Unterverzeichnis heraus
#   - Slugs mit Umlauten (core.quotePath=false + NUL-getrennte Pfade)
#   - BEIDE Lauf-Orte: .planning/route/<slug>/ und .planning/route-opus/<slug>/
#     (30.07.2026 ergaenzt — route-opus ist in SKILL.md S1 Schritt 0 ein
#     gleichrangiger Ort, lief hier aber komplett am Gate vorbei)
#   - ZWEITE PFLICHT (30.07.2026): eine STATE.md im Commit ohne Messzeile der
#     COMMITTENDEN Session in MESSUNG.md daneben. Grund steht unten am Block.
#
# OFFEN gegen (bewusst, nicht behoben — wer mehr behauptet, zitiert falsch):
#   - Commit-Wege ausserhalb des Bash-Tools
#   - in Anfuehrungszeichen verpackte Aufrufe: `bash -c '…'`, `eval "…"`,
#     Backticks, sowie git-Aliase (`-c alias.ci=commit ci`) und `/usr/bin/git`
#   - `cd` in einem FRUEHEREN Bash-Aufruf (der Hook sieht nur diesen Befehl)
#   - Byte-Wachstum NACH dem Commit
#   - Kantenmessung: ein Schnitt OHNE Commit (`Kante: ROT — kein Commit`) wird
#     nicht erwischt — dort gibt es keinen Ausloeser. Diese Luecke faengt erst
#     der Bericht: `kanten-messung.py <lauf> --bericht` nennt jede Session, die
#     im Zettel steht und keine Zeile hat, und haelt die Gesamtzahl zurueck.
#   - Kantenmessung: geprueft wird die ARBEITSKOPIE der MESSUNG.md, nicht ob
#     sie mitgestaget ist. "Gemessen" wird erzwungen, "mitcommittet" nicht —
#     die Auflage steht im Blocktext, ein Gate dafuer waere bei Pathspec-Commits
#     ein Dauerfehlalarm.
#   - Kantenmessung: ohne CLAUDE_CODE_SESSION_ID (Commit aus einer fremden
#     Konsole) wird nicht geprueft. Absicht: eine Auflage, die der Committer
#     nicht erfuellen KANN, waere ein unloesbarer Block.
#
# ── ZWEI DESIGN-ENTSCHEIDUNGEN, die Fehlalarme verhindern ────────────────────
# 1) Gemessen wird nur, was DIESER Commit wirklich enthaelt. Ein Pathspec-Commit
#    (`git commit -- README.md`) traegt den restlichen Index NICHT — eine fremde,
#    gestagete STATE.md einer Parallel-Session darf ihn also nicht blocken.
#    Genau diese Form schreibt feedback_parallele_session_commit_disziplin.md vor.
# 2) Geblockt wird ZUWACHS, nicht Zustand: nur wenn die Fassung dieses Commits
#    groesser ist als die in HEAD. Damit laufen Merge, Cherry-Pick, Revert,
#    Archivierung und Kuerzungs-Commits durch — dort hat der Committer den
#    Inhalt nicht geschrieben, und "kuerze das" waere keine erfuellbare Auflage.
#
# NOTAUSGAENGE (benannt, nicht still): ROUTE_STATE_GATE=off schaltet den ganzen
# Hook ab, ROUTE_MESSUNG_GATE=off nur die Kantenmessung. Getrennt, damit ein
# Fehlalarm der einen Pflicht nicht die andere mitreisst — die 2048/4096-Drift
# haette genau diesen Weg genommen.
#
# GEGENPROBE: `bash hooks/state-byte-gate.test.sh` — 41 Faelle, alle gruen
# (17 muessen blocken, 24 duerfen nicht). Darin ZWEI Sabotage-Proben, je eine
# pro Pflicht: Limit-Vergleich bzw. Kennungs-Vergleich entschaerft -> der
# zugehoerige Blockfall MUSS gruen werden, sonst waere der Vergleich Deko.
# Jede Sabotage traegt einen Kontrollfall daneben (unveraenderte Kopie blockt
# weiter), damit ein Gruen aus einem anderen Grund nicht als Beweis durchgeht.
# Die erste Fassung dieses Hooks bestand 8 selbstgebaute Tests und fiel danach
# in einem gegnerischen Review mit vier Blockern durch — u. a. behauptete ihr
# Register `git -C <pfad>` als ERKENNEND, obwohl der Test das nur deshalb zeigte,
# weil Ziel-Repo und Arbeitsverzeichnis zufaellig dasselbe waren. Wer dieses
# Register aendert, faehrt vorher die Testdatei.

# AUSFALL-RESTFALL (fremde Abnahme 16.08., bewusst offen): ist .git/index
# korrupt bei intaktem git (rev-parse 0, diff --cached scheitert), bleibt die
# Kandidatenliste leer und das Gate schweigt — ein Spur-Loch, keine Schutz-
# luecke: derselbe kaputte Index laesst auch `git commit` selbst scheitern
# (gemessen rc=128), der bewachte Commit kann also gar nicht passieren.

set -uo pipefail

LIMIT=4096
[ "${ROUTE_STATE_GATE:-on}" = "off" ] && exit 0

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{process.stdout.write(JSON.parse(d).tool_input?.command||'')}catch{}})" 2>/dev/null)
RC=$?
# Ausfall-Sichtbarkeit (16.08., Klassen-Fix, gleiche Bauart wie im
# bash-herestring-gate): Extraktions-Fehlschlag (node fehlt/crasht) fiel
# bisher still auf exit 0 — Schutz weg, keine Spur. Jetzt: stderr sofort,
# Logzeile fuer den Healthcheck. Fail-Open bleibt Absicht. Der zweite
# node-Aufruf (norm_bytes) ist mit abgedeckt: ohne node endet der Hook hier.
if [ "$RC" -ne 0 ]; then
  echo "WARN: state-byte-gate: Payload-Extraktion fehlgeschlagen (rc=$RC) — Gate prueft NICHT" >&2
  mkdir -p "$HOME/.claude/.cache" 2>/dev/null
  echo "$(date -Iseconds)|state-byte-gate|rc=$RC" >> "$HOME/.claude/.cache/gate_ausfall.log" 2>/dev/null
  exit 0
fi
# rc=0 + leer = fast sicher Schema-Drift (Begruendung im herestring-Gate,
# gleiche Bauart): Logzeile ohne WARN, Healthcheck meldet beim Start.
if [ -z "${CMD:-}" ]; then
  mkdir -p "$HOME/.claude/.cache" 2>/dev/null
  echo "$(date -Iseconds)|state-byte-gate|leer" >> "$HOME/.claude/.cache/gate_ausfall.log" 2>/dev/null
  exit 0
fi

# Zitierte Bereiche neutralisieren, damit eine blosse ERWAEHNUNG von "git commit"
# in einem echo/Kommentar nicht als Befehl gilt. (Kostet die Erkennung von
# `bash -c '…'` — steht so im OFFEN-Register.)
DECMD=$(printf '%s' "$CMD" | sed -e "s/'[^']*'/Q/g" -e 's/"[^"]*"/Q/g')

# Werte von globalen Optionen einfalten, damit `git -C <pfad> commit` erkannt
# wird — genau daran scheiterte die erste Fassung, und Test T6 hat es nicht
# gemerkt, weil dort Ziel-Repo und Arbeitsverzeichnis dasselbe waren.
PRE=$(printf '%s' "$DECMD" | sed -E 's/(-C|-c|--exec-path|--namespace)[[:space:]]+[^[:space:]]+/\1/g')

# Nur bei git … commit weiterdenken; `git` muss am Anfang oder hinter einem
# Trenner stehen, nicht mitten in einem Wort.
printf '%s' "$PRE" | grep -Eq '(^|[;&|]|[[:space:]])git([[:space:]]+(-[^[:space:]]+|--[^[:space:]]+=[^[:space:]]*))*[[:space:]]+commit([[:space:]]|$)' || exit 0

# ── Ziel-Repo aufloesen: -C <pfad>, --git-dir=, fuehrendes `cd <pfad> &&` ──
TARGET="."
if [[ "$CMD" =~ (^|[[:space:]])cd[[:space:]]+([^[:space:]\;\&\|]+)[[:space:]]*(\&\&|\;) ]]; then
  TARGET="${BASH_REMATCH[2]}"
fi
if [[ "$CMD" =~ (^|[[:space:]])git[[:space:]]+(-[^[:space:]]+[[:space:]]+)*-C[[:space:]]+([^[:space:]]+) ]]; then
  TARGET="${BASH_REMATCH[3]}"
fi
if [[ "$CMD" =~ --git-dir=([^[:space:]]+) ]]; then
  TARGET="$(dirname "${BASH_REMATCH[1]}")"
fi
TARGET="${TARGET%\"}"; TARGET="${TARGET#\"}"; TARGET="${TARGET%\'}"; TARGET="${TARGET#\'}"
[ -d "$TARGET" ] || TARGET="."

G=(git -c core.quotePath=false -C "$TARGET")

# git-Ausfall von "kein Repo" trennen (fremde Abnahme 16.08., Kreativ-Probe:
# ohne git im PATH starb der Hook hier voellig still — dritte Geschwister-
# Stelle derselben Klasse nach node-Eintritt und norm_bytes). rev-parse
# antwortet 128 fuer "kein Repo" (legitim still — sonst spammt jeder
# Nicht-Repo-Bash-Call das Log), 127 fuer "git nicht gefunden"; alles
# andere Nicht-Null ist ein kaputtes git. Nur der Werkzeug-Ausfall
# hinterlaesst Spur, der Nicht-Repo-Fall bleibt lautlos wie immer.
"${G[@]}" rev-parse --is-inside-work-tree >/dev/null 2>&1
RCG=$?
if [ "$RCG" -ne 0 ] && [ "$RCG" -ne 128 ]; then
  echo "WARN: state-byte-gate: git nicht verfuegbar (rc=$RCG) — Gate prueft NICHT" >&2
  mkdir -p "$HOME/.claude/.cache" 2>/dev/null
  echo "$(date -Iseconds)|state-byte-gate|git-rc=$RCG" >> "$HOME/.claude/.cache/gate_ausfall.log" 2>/dev/null
  exit 0
fi
[ "$RCG" -ne 0 ] && exit 0
TOP=$("${G[@]}" rev-parse --show-toplevel 2>/dev/null) || exit 0

# Laufende Merge-/Pick-/Revert-/Rebase-Operation: der Committer hat den Inhalt
# nicht geschrieben — durchlassen (steht so im Register oben).
GD=$("${G[@]}" rev-parse --git-dir 2>/dev/null)
for m in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD rebase-merge rebase-apply; do
  [ -e "$GD/$m" ] && exit 0
done

# ── Befehls-Segment ab `commit` isolieren (bis zum naechsten Trenner) ──
SEG=$(printf '%s' "$DECMD" | sed -E 's/.*[[:space:]]commit([[:space:]]|$)/commit /; s/[;&|].*$//')

ALL_MODE=0
PATHSPECS=()
seen_commit=0; after_ddash=0
for tok in $SEG; do
  if [ "$seen_commit" = "0" ]; then [ "$tok" = "commit" ] && seen_commit=1; continue; fi
  if [ "$after_ddash" = "1" ]; then PATHSPECS+=("$tok"); continue; fi
  case "$tok" in
    --) after_ddash=1 ;;
    -a|--all|-am|-a[a-zA-Z]*|--all=*) ALL_MODE=1 ;;
    --only|-o) : ;;
    --include|-i) : ;;
    -m|--message|--author|--date|-C|--reuse-message|--file|-F) SKIPNEXT=1 ;;
    -*) case "$tok" in *a*) [[ "$tok" =~ ^-[a-zA-Z]+$ ]] && ALL_MODE=1 ;; esac ;;
    Q) : ;;   # neutralisierter Anfuehrungs-Block, z. B. die Commit-Message
    *) if [ "${SKIPNEXT:-0}" = "1" ]; then SKIPNEXT=0; else PATHSPECS+=("$tok"); fi ;;
  esac
  case "$tok" in -m|--message|--author|--date|-C|--reuse-message|--file|-F) ;; *) SKIPNEXT=0 ;; esac
done

# ── Was enthaelt dieser Commit wirklich? ──
#   Pathspec  -> Arbeitskopie der genannten Pfade (git uebergeht den Index)
#   -a/--all  -> Arbeitskopie aller geaenderten Tracked-Dateien
#   sonst     -> ausschliesslich der Index
if [ ${#PATHSPECS[@]} -gt 0 ]; then
  MODE=worktree
  mapfile -d '' CAND < <("${G[@]}" diff --name-only -z HEAD -- "${PATHSPECS[@]}" 2>/dev/null; "${G[@]}" ls-files -z -- "${PATHSPECS[@]}" 2>/dev/null)
elif [ "$ALL_MODE" = "1" ]; then
  MODE=worktree
  mapfile -d '' CAND < <("${G[@]}" diff --name-only -z 2>/dev/null; "${G[@]}" diff --cached --name-only -z 2>/dev/null)
else
  MODE=index
  mapfile -d '' CAND < <("${G[@]}" diff --cached --name-only -z 2>/dev/null)
fi

norm_bytes() {
  node -e "let c=[];process.stdin.on('data',d=>c.push(d));process.stdin.on('end',()=>{const b=Buffer.concat(c);const s=b.toString('binary').split('\r\n').join('\n');process.stdout.write(String(Buffer.byteLength(s,'binary')))})" 2>/dev/null
}

OFFENDERS=""
STATES=""
SEEN=" "
for f in "${CAND[@]:-}"; do
  [ -z "${f:-}" ] && continue
  case "$SEEN" in *" $f "*) continue ;; esac
  SEEN="$SEEN$f "
  case "$f" in
    */.planning/route/*/STATE.md|.planning/route/*/STATE.md) ;;
    */.planning/route-opus/*/STATE.md|.planning/route-opus/*/STATE.md) ;;
    *) continue ;;
  esac

  # VOR jedem Byte-Zweig sammeln: die Kantenmessung unten gilt fuer JEDE
  # STATE.md dieses Commits, auch fuer eine, die das Byte-Budget einhaelt.
  STATES="${STATES}$f
"

  if [ "$MODE" = "worktree" ]; then
    # Geloescht? Dann entfernt der Commit das Problem, statt es zu schaffen.
    [ -f "$TOP/$f" ] || continue
    BYTES=$(norm_bytes < "$TOP/$f")
  else
    BYTES=$("${G[@]}" show ":$f" 2>/dev/null | norm_bytes)
  fi
  # Leeres BYTES ist IMMER ein Werkzeug-Ausfall, nie ein Messwert: norm_bytes
  # liefert auf leere Eingabe "0", leer wird es nur, wenn node selbst stirbt.
  # Vorher stand hier `continue` — eine Messung, die nie rot werden konnte:
  # eine 6000-B-STATE.md ging beim norm_bytes-Crash spurlos durch (gefunden
  # von der fremden Abnahme 16.08., Szenario d2 — die Geschwister-Stelle des
  # Eintritts-Guards, die der Bauende fuer "mit abgedeckt" hielt).
  if [ -z "${BYTES:-}" ]; then
    echo "WARN: state-byte-gate: Byte-Messung fuer $f fehlgeschlagen — Datei ungeprueft" >&2
    mkdir -p "$HOME/.claude/.cache" 2>/dev/null
    echo "$(date -Iseconds)|state-byte-gate|norm_bytes-leer|$f" >> "$HOME/.claude/.cache/gate_ausfall.log" 2>/dev/null
    continue
  fi
  [ "$BYTES" -le "$LIMIT" ] && continue

  # Kein HEAD (Erst-Commit) => es gibt keinen Vorzustand, gegen den man messen
  # koennte. Bewusst BLOCKIEREN statt durchlassen: der erste STATE-Commit eines
  # frischen route-Laufs ist genau der Fall, um den es geht. Der seltene
  # Gegenfall (Import eines Fremd-Repos mit Alt-Ordner) nimmt den Notausgang
  # ROUTE_STATE_GATE=off — eine benannte Ausnahme statt eines stillen Lochs.
  if ! "${G[@]}" rev-parse --verify HEAD >/dev/null 2>&1; then
    OFFENDERS="${OFFENDERS}  $f — $BYTES B (Limit $LIMIT, $((BYTES - LIMIT)) zu viel, Erst-Commit)
"
    continue
  fi

  # ACHTUNG: `git show HEAD:<pfad> | norm_bytes` liefert bei fehlendem Pfad NICHT
  # leer, sondern "0" — die Pipe laeuft weiter, auch wenn git scheitert. Deshalb
  # die Existenz getrennt pruefen statt sie aus der Zahl zu erschliessen.
  # (Gefunden in der Gegenprobe T21; dieselbe Fehlerklasse, die dieser Hook
  # ueberhaupt bewacht: eine Messung, die nie rot werden kann.)
  if "${G[@]}" cat-file -e "HEAD:$f" 2>/dev/null; then
    # Zuwachs, nicht Zustand: was schon so in HEAD steht, blockiert nicht.
    HEADB=$("${G[@]}" show "HEAD:$f" 2>/dev/null | norm_bytes)
    [ -n "${HEADB:-}" ] && [ "$BYTES" -le "$HEADB" ] && continue
  elif [ "$MODE" = "index" ]; then
    # Am Pfad nicht in HEAD — kann eine Umbenennung/Archivierung sein.
    # Existiert exakt derselbe Blob schon irgendwo in HEAD, ist kein Byte neu.
    OID=$("${G[@]}" rev-parse ":$f" 2>/dev/null)
    if [ -n "${OID:-}" ] && "${G[@]}" ls-tree -r HEAD 2>/dev/null | awk '{print $3}' | grep -qx "$OID"; then
      continue
    fi
  fi

  OFFENDERS="${OFFENDERS}  $f — $BYTES B (Limit $LIMIT, $((BYTES - LIMIT)) zu viel)
"
done

# ── Zweite Pflicht: die Kantenmessung DIESER Session ────────────────────────
# Jeder Schnitt committet die STATE.md. Genau dort wird deshalb geprueft, ob die
# Session ihre eigene Messzeile geschrieben hat — nicht per Prosa im Skill.
# Warum ueberhaupt: die Abschluss-Messung hing an einer handgefuehrten
# Sessions-Liste, die das Byte-Budget kuerzt und in der am 30.07.2026 zwei
# Kennungen standen, die nie eine Datei getragen haben. Wer an der Kante misst,
# braucht die Liste nicht mehr.
#
# EIGENER NOTAUSGANG (ROUTE_MESSUNG_GATE=off), nicht der des Byte-Deckels: ein
# Fehlalarm hier darf niemanden zwingen, den ganzen Hook abzuschalten. Genau so
# faellt in der Praxis ein Gate — die Drift von 2048 gegen 4096 haette exakt
# diesen Weg genommen.
MESSUNG_FEHLT=""
if [ "${ROUTE_MESSUNG_GATE:-on}" != "off" ] && [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then
  while IFS= read -r sf; do
    [ -n "$sf" ] || continue
    # Nicht vorhanden = geloescht/archiviert. Ein Lauf, der seinen Zettel
    # entfernt, soll nicht zum Messen gezwungen werden.
    [ -f "$TOP/$sf" ] || continue
    LAUFDIR=$(dirname "$TOP/$sf")
    if ! grep -qF "$CLAUDE_CODE_SESSION_ID" "$LAUFDIR/MESSUNG.md" 2>/dev/null; then
      MESSUNG_FEHLT="${MESSUNG_FEHLT}  $(dirname "$sf")
"
    fi
  done <<EOF
$STATES
EOF
fi

if [ -n "$OFFENDERS" ] || [ -n "$MESSUNG_FEHLT" ]; then
  [ -n "$OFFENDERS" ] && cat >&2 <<MSG
BLOCKIERT — STATE.md ueber dem $LIMIT-Byte-Deckel (Repo: $TOP):

$OFFENDERS
Der Byte-Check gehoert in einen EIGENEN Schritt VOR den Commit, nicht in eine
&&-Kette dahinter: \`wc -c\` exitet 0 unabhaengig vom Wert und stoppt nichts.

So geht es weiter:
  1. Gegen die BYTE-BUDGET-Tabelle in skills/route/STATE-TEMPLATE.md kuerzen
     (gegen das Budget entwerfen, nicht hinterher herunterkuerzen)
  2. Erneut committen — dieser Hook entscheidet
  3. Bewusste Ausnahme? ROUTE_STATE_GATE=off — sie traegt dann ihren Namen.
MSG
  [ -n "$MESSUNG_FEHLT" ] && cat >&2 <<MSG
BLOCKIERT — Kantenmessung fehlt fuer diese Session (Repo: $TOP):

$MESSUNG_FEHLT
Session $CLAUDE_CODE_SESSION_ID hat in MESSUNG.md keine Zeile. Wird jetzt
committet, ist ihr Aufwand fuer den Abschluss verloren, sobald das Transkript
aufgeraeumt ist (cleanupPeriodDays, Vorgabe 30 Tage) — oder sobald ihre
Kennung im Zettel falsch abgeschrieben wurde. Beides ist belegt passiert.

So geht es weiter — je Lauf-Ordner EIN Befehl, dann erneut committen:
  python ~/.claude/skills/route/tools/kanten-messung.py <lauf-ordner>
Die erzeugte MESSUNG.md gehoert in denselben Commit wie die STATE.md.
Bewusste Ausnahme? ROUTE_MESSUNG_GATE=off — sie traegt dann ihren Namen.
MSG
  exit 2
fi

exit 0
