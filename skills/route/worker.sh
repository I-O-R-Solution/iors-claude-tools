#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Anbieter-blinder Worker fuer /route und /kimi (v2.2, 01.09.2026).
#
# Aufruf: worker.sh <profil> <critique|build|resume|chat> <slug> <schema|-> <outfile|-> <prompt>
#
#   profil    Datei profiles/<profil>.conf - Endpunkt, Key, Marker, Namespace,
#             Budget. Start-Profile: kimi, deepseek.
#   critique  read-only  (Read,Grep,Glob)          - Plan-Kritik, Schritt 3
#   build     schreibend (+Edit,Write), OHNE Bash  - Bau, Schritt 5
#   resume    schreibend, setzt die build-Session fort - Fix-Runden, Schritt 7
#   chat      read-only, ohne Schema               - freier Aufruf
#
# Der Worker bekommt in KEINEM Modus eine Shell - fuer KEIN Profil. Er
# schreibt Code, der Boss fuehrt aus und verifiziert (SKILL.md S4). Das ist
# das Etappen-Protokoll aus LESSONS.md, eine Stufe strenger - noetig, weil
# Codex eine OS-Sandbox hat und diese Worker keine.
#
# Warum kein Codex: Codex hat wire_api="chat" entfernt und haengt bei
# wire_api="responses" zwingend /responses an die URL - einen Pfad, den
# die Anthropic-kompatiblen Endpunkte (Moonshot, DeepSeek) nicht haben.
# Deshalb ein zweiter headless Claude-Code-Prozess gegen den Endpunkt.
# ~/.codex/config.toml wird NIE angefasst.
#
# Historie: bis 01.09.2026 hiess diese Datei kimi-worker.sh und kannte nur
# Moonshot. kimi-worker.sh bleibt als Shim (exec worker.sh kimi "$@") stehen.
# ---------------------------------------------------------------------------
set -euo pipefail

SKILLDIR="C:/Users/User/.claude/skills/route"   # native Windows-Pfade: der
                                                # Git-Bash-Shim konvertiert
                                                # Argumente NICHT mit

usage() { echo "Aufruf: $0 <profil> <critique|build|resume|chat> <slug> <schema|-> <outfile|-> <prompt>" >&2; exit 2; }
[ $# -ge 6 ] || usage
PROFIL="$1"; MODE="$2"; SLUG="$3"; SCHEMA="$4"; OUT="$5"; PROMPT="$6"

# --- Profil laden (fail-closed) ---------------------------------------------
# Ein Profil definiert NUR PROFIL_*-Variablen. Fehlt die Datei oder ein
# Pflichtfeld, gibt es keinen Lauf - ein halbes Profil darf nie mit Defaults
# eines anderen Anbieters aufgefuellt werden (sonst laeuft ein
# DeepSeek-Auftrag still gegen Moonshot).
PROFILDATEI="$SKILLDIR/profiles/$PROFIL.conf"
[ -r "$PROFILDATEI" ] || { echo "PROFIL FEHLT: $PROFILDATEI - kein Lauf." >&2; exit 2; }
. "$PROFILDATEI"
for PFLICHT in PROFIL_BASE_URL PROFIL_MODEL PROFIL_KEY_VAR PROFIL_KEY_FILE \
               PROFIL_T4_MARKER PROFIL_T8_MARKER PROFIL_SESSION_PREFIX \
               PROFIL_SETTINGS_FILE PROFIL_OVERRIDE_PREFIX PROFIL_MAX_BUDGET_USD; do
  [ -n "${!PFLICHT:-}" ] || { echo "PROFIL UNVOLLSTAENDIG: $PFLICHT fehlt in $PROFILDATEI." >&2; exit 2; }
done

KEYFILE="$PROFIL_KEY_FILE"
SETTINGS="$SKILLDIR/$PROFIL_SETTINGS_FILE"

# Laufzeit-Overrides unter dem Profil-Praefix - das Bestandsmuster
# KIMI_BASE_URL/KIMI_MODEL/KIMI_KEY_VAR bleibt fuers kimi-Profil identisch
# nutzbar, DeepSeek bekommt DEEPSEEK_*.
_ov() { local n="${PROFIL_OVERRIDE_PREFIX}_$1"; printf '%s' "${!n:-}"; }
WORKER_BASE_URL="$(_ov BASE_URL)"; WORKER_BASE_URL="${WORKER_BASE_URL:-$PROFIL_BASE_URL}"
WORKER_MODEL="$(_ov MODEL)";       WORKER_MODEL="${WORKER_MODEL:-$PROFIL_MODEL}"
WORKER_KEY_VAR="$(_ov KEY_VAR)";   WORKER_KEY_VAR="${WORKER_KEY_VAR:-$PROFIL_KEY_VAR}"

# --- Riegel-Bausteine laden -------------------------------------------------
# Sperrliste, Marker-Pruefung und Umgebungsdatei-Scan liegen seit 26.07.2026 in
# kimi-guards.sh, weil dieselben Riegel hier UND in kimi-preflight.sh standen
# und zweimal auseinandergelaufen sind. Fail-closed: ohne die Datei kein Lauf.
GUARDS="$SKILLDIR/kimi-guards.sh"
[ -r "$GUARDS" ] || { echo "FEHLT: $GUARDS - Riegel nicht ladbar, Abbruch." >&2; exit 3; }
. "$GUARDS"

# --- Riegel 1: Arbeitsverzeichnis ------------------------------------------
# Laeuft VOR jeder Netzverbindung. Der erste Lauf IST bereits die Uebertragung.
# Normalisierung, Wurzel-Bezug und Begruendung der Liste: kimi-guards.sh.
CWD_WIN="$(pwd -W 2>/dev/null || pwd)"
# Wurzel EINMAL ermitteln - Riegel 1, 2 und 2b benutzen sie alle drei.
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if BLOCKED="$(guard_blocked_dir "$CWD_WIN" "$REPO_ROOT")"; then
  echo "GESPERRT: $BLOCKED/ ist fuer den Worker tabu (Personendaten Dritter, Geheimnisse" >&2
  echo "          oder Kernkapital). Arbeitsverzeichnis wechseln, nicht umgehen." >&2
  exit 3
fi

# --- Riegel 2: .env ---------------------------------------------------------
# Der Schutz der .env haengt daran, dass die Deny-Regeln aus --settings auch
# unter --safe-mode greifen. Das war UNBELEGT - bis Test T4 (tests/t4-env-guard.sh)
# es am 19.07.2026 gegen Claude Code 2.1.175 empirisch gezeigt hat: drei
# Angriffswege (Read/cat/Grep) geblockt, Gegen-Test beweist Lesefaehigkeit.
# Der Nachweis ist an die Version gebunden: der T4-Marker des Profils traegt in
# Zeile 1 die belegte Version. Stimmt sie mit der laufenden `claude --version`
# ueberein, gilt der Guard als belegt und Kimi darf im Repo arbeiten. Weicht sie
# ab (Update) oder fehlt die Datei, bleibt es safe-by-default: gesperrt.
# So faellt der Schutz nach einem Update automatisch zu, statt still stale zu
# gelten. <PREFIX>_ENV_GUARD_VERIFIED=1 bleibt als manuelle Uebersteuerung.
ENV_GUARD_VERIFIED="$(_ov ENV_GUARD_VERIFIED)"; ENV_GUARD_VERIFIED="${ENV_GUARD_VERIFIED:-0}"
if [ "$ENV_GUARD_VERIFIED" != "1" ] && guard_marker_verified "$SKILLDIR/$PROFIL_T4_MARKER"; then
  ENV_GUARD_VERIFIED=1
fi
# REPO_ROOT steht schon aus Riegel 1 - nicht neu ermitteln.
# Suchmuster und Ausnahmen: guard_find_env in kimi-guards.sh.
if [ "$ENV_GUARD_VERIFIED" != "1" ] && ENV_FUND="$(guard_find_env "." "$REPO_ROOT")"; then
  echo "GESPERRT: $ENV_FUND gefunden, und der .env-Schutz ist noch nicht per T4 belegt." >&2
  echo "          Erst T4 fahren, dann ${PROFIL_OVERRIDE_PREFIX}_ENV_GUARD_VERIFIED=1 setzen." >&2
  exit 3
fi

# --- Riegel 2b: .planning nur als Lauf-Ausschnitt ---------------------------
# .planning/ traegt Kernkapital (PREMIUM-STRATEGIE.md, cockpit-online/, Preis-
# staffeln) und bleibt deshalb gesperrt. Genau diese pauschale Sperre machte
# Kimi am 24.07.2026 als Worker fuer eine Etappe unbrauchbar, deren Werkstueck
# - die Pruefskripte - im Lauf-Ordner unter .planning/ liegt. Statt die Sperre
# aufzugeben, wird sie praezisiert: offen ist NUR .planning/route[-opus]/<slug>/
# des aktiven Laufs. Die Aufzaehlung entsteht bei JEDEM Start aus dem echten
# Verzeichnisbaum, ein neuer Ordner unter .planning/ ist also von selbst
# gesperrt. Scheitert die Erzeugung, gilt die statische pauschale Sperre weiter
# - ein Fehlschlag darf nie mehr oeffnen, nur weniger.
# Nicht behoben und bewusst so: Kimi hat weiter KEINE Shell. Es kann die
# Pruefskripte im Lauf-Ordner schreiben, aber nicht ausfuehren; das bleibt
# Boss-Arbeit (SKILL.md Schritt 6.1).
SETTINGS_EFFEKTIV="$SETTINGS"
if [ -n "$REPO_ROOT" ] && [ -d "$REPO_ROOT/.planning" ]; then
  LAUF_REL=""; LAUF_ANZAHL=0
  for KAND in "route" "route-opus"; do
    if [ -d "$REPO_ROOT/.planning/$KAND/$SLUG" ]; then
      LAUF_REL=".planning/$KAND/$SLUG"; LAUF_ANZAHL=$((LAUF_ANZAHL + 1))
    fi
  done
  if [ "$LAUF_ANZAHL" -eq 1 ]; then
    GEN="$SKILLDIR/.$PROFIL_SESSION_PREFIX-settings-$SLUG.json"
    if python "$SKILLDIR/tools/kimi-planning-ausschnitt.py" \
         "$SETTINGS" "$REPO_ROOT" "$LAUF_REL" "$GEN" >&2; then
      SETTINGS_EFFEKTIV="$GEN"
    else
      echo "HINWEIS: kein .planning-Ausschnitt erzeugt - pauschale Sperre bleibt." >&2
    fi
  elif [ "$LAUF_ANZAHL" -gt 1 ]; then
    echo "HINWEIS: Slug '$SLUG' liegt in route UND route-opus - pauschale Sperre bleibt." >&2
  fi
fi

# --- Riegel 3: Key nur inline, nie global ----------------------------------
# ANTHROPIC_AUTH_TOKEN steht in Claude Codes Auth-Reihenfolge auf Rang 2, das
# Abo-OAuth erst auf Rang 6. Global gesetzt liefe die Boss-Session auf Kimi.
[ -r "$KEYFILE" ] || { echo "FEHLT: $KEYFILE (eine Zeile, der API-Key fuer Profil '$PROFIL')." >&2; exit 4; }
WORKER_KEY="$(tr -d ' \t\r\n' < "$KEYFILE")"
[ -n "$WORKER_KEY" ] || { echo "LEER: $KEYFILE enthaelt keinen Key." >&2; exit 4; }

# --- Modus ------------------------------------------------------------------
RO_TOOLS="Read,Grep,Glob"
RW_TOOLS="Read,Edit,Write,Glob,Grep"
# SCHLUSSSTRICH 18.07.2026: Bash ist in KEINEM Modus mehr im Werkzeugsatz.
# Begruendung ist die Asymmetrie, die weiter unten schon steht, nur zu Ende
# gedacht: --tools IST der Werkzeugsatz, --allowedTools/deny sind nur
# Erlaubnis-Regeln. Ob die Erlaubnis-Schicht unter --safe-mode ueberhaupt
# greift, ist bis T4 unbelegt. Bash haengt zu 100 % an dieser ungeprueften
# Schicht: faellt sie offen aus, ist Bash unbeschraenkt; faellt sie zu, ist Bash
# nutzlos. Beide Enden sprechen dagegen, es ueberhaupt zu reichen.
# Verlust: kein "git status --porcelain", kein "ls". Beides ersetzt Glob, und
# welche Dateien Kimi geaendert hat, weiss es aus der eigenen Sitzung - genau
# das fragt das build-report-Schema unter files_changed ab.
# Bewusst OHNE python/node/gh/curl: python -c "print(open('.env').read())"
# umginge jede Read()-Deny-Regel, gh ist authentifiziert und POST-faehig.
#
# Aus demselben Grund seit 18.07.2026 auch OHNE cat und git diff. Beide sind
# vollwertige Datei-Ausgabe-Primitive, fuer die Kimi keine Zeile Code schreiben
# muss:
#   cat .env                            - Dateiinhalt direkt ueber die Shell
#   git diff --no-index leer.txt .env   - druckt jede Zeile der Datei als +-Zeile
#   git diff -U100000 <datei>           - druckt die ganze Datei als Diff-Kontext
# Die Messung vom 18.07.2026 (Claude Code 2.1.175) hat gezeigt, dass die
# Read()-Deny-Regeln beide Formen tatsaechlich abfangen ("Permission to use Bash
# with command ... has been denied"). Genau darauf soll die Shell-Flaeche aber
# nicht angewiesen sein: die Wand ist die --tools-/--allowedTools-Whitelist, die
# Deny-Regeln sind nur die zweite Reihe. Kimi hat Read fuer Dateiinhalte und
# Grep zum Suchen - cat und git diff bringen keine Faehigkeit, die es braucht.
# Funktionsverlust: Kimi kann seine eigenen Aenderungen nicht mehr per git diff
# ueberblicken, sondern muss die geaenderten Dateien mit Read ansehen.
#
# pytest ist am 18.07.2026 GEMESSEN als offener Weg an der .env vorbei belegt
# worden: "pytest -q -s" laeuft ohne jede Rechteabfrage durch (0 Denials im
# Roh-JSON) und fuehrt dabei conftest.py aus - beliebigen Repo-Code also, den
# Kimi im build-Modus selbst schreiben kann. Genau der Umweg, wegen dem
# python/node draussen sind. Deshalb raus, trotz Funktionsverlust.
# "npm test" war zusaetzlich wirkungslos: Bash(npm:*) in der Deny-Liste schlaegt
# den Allow-Eintrag, der Aufruf wurde ohnehin abgelehnt. Eine Allow-Regel, die
# nie greift, taeuscht nur eine Faehigkeit vor.
#
# Funktionsverlust, bewusst: Kimi kann keine Tests fahren und seine Aenderungen
# nicht per git diff ueberblicken. Beides ist Aufgabe des Boss-Modells, das
# ohnehin unabhaengig verifiziert (SKILL.md Schritt 6.1). Wer das aufmacht,
# oeffnet den Code-Ausfuehrungs-Weg wieder - dann vorher T4 scharf fahren.
# "git status" MUSS auf --porcelain eingeschraenkt bleiben: "git status -vv"
# druckt den vollstaendigen alten Inhalt jeder geaenderten getrackten Datei als
# Diff-Zeilen und umgeht damit Read()-Deny-Regeln. Am 18.07.2026 im Wegwerf-Repo
# gemessen: Koeder-Inhalt woertlich ausgegeben, 0 Denials. Dasselbe Primitiv,
# wegen dem git diff oben rausgeflogen ist - nur unter anderem Namen.
# NICHT MEHR AKTIV - siehe SCHLUSSSTRICH oben. Bash ist gar nicht erst im
# Werkzeugsatz, damit entfaellt jede Allow-Liste. Bleibt als Messprotokoll
# stehen: wer Bash je wieder aufmacht, faengt bei dieser Liste an und nicht
# bei einer breiteren - und faehrt vorher T4 scharf.
# BASH_ALLOW="Bash(git status --porcelain:*),Bash(ls:*)"

STATE="$SKILLDIR/.$PROFIL_SESSION_PREFIX-session-$SLUG"
case "$MODE" in
  critique) SID="$(python -c 'import uuid;print(uuid.uuid4())' | tr -d '\r\n')"
            printf '%s' "$SID" > "$STATE.critique"
            SESSION=(--session-id "$SID"); GUARD=(--permission-mode acceptEdits --tools "$RO_TOOLS") ;;
  chat)     SID="$(python -c 'import uuid;print(uuid.uuid4())' | tr -d '\r\n')"
            printf '%s' "$SID" > "$STATE.chat"
            SESSION=(--session-id "$SID"); GUARD=(--permission-mode acceptEdits --tools "$RO_TOOLS") ;;
  build)    SID="$(python -c 'import uuid;print(uuid.uuid4())' | tr -d '\r\n')"
            printf '%s' "$SID" > "$STATE.build"
            SESSION=(--session-id "$SID")
            GUARD=(--permission-mode acceptEdits --tools "$RW_TOOLS") ;;
  resume)   if [ ! -r "$STATE.build" ]; then
              # Namespace-Riegel: eine build-Session eines ANDEREN Profils
              # unter demselben Slug ist ein harter Abbruch, nie ein stiller
              # Neustart - sie entstand gegen einen anderen Endpunkt.
              for FREMD in "$SKILLDIR"/.*-session-"$SLUG".build; do
                [ -e "$FREMD" ] || continue
                [ "$FREMD" = "$STATE.build" ] && continue
                echo "NAMESPACE-RIEGEL: $FREMD gehoert einem anderen Profil." >&2
                echo "          Ein resume ueber Profilgrenzen ist verboten. Mit dem" >&2
                echo "          richtigen Profil aufrufen oder frisch 'build' fahren." >&2
                exit 5
              done
              echo "KEINE SESSION: $STATE.build fehlt - erst 'build' laufen lassen." >&2; exit 5
            fi
            # --- T8-Gate: resume nur mit belegtem Thinking-Replay -----------
            # Moonshot dokumentiert fuer K3: ohne vollstaendig zurueck-
            # gesendeten Denkverlauf wird die Qualitaet "highly unstable".
            # Ob `claude --resume` die Thinking-Bloecke tatsaechlich zurueck-
            # spielt, ist versionsabhaengiges Client-Verhalten und wird von
            # tests/t8-resume-thinking.sh OFFLINE gemessen (Mock-Server, kein
            # Key, keine Kosten). Gleiches Muster wie der T4-Guard: Marker-
            # Datei traegt in Zeile 1 die belegte Version, entsperrt nur bei
            # exaktem Treffer, faellt nach einem Claude-Code-Update von selbst
            # zu. <PREFIX>_RESUME_VERIFIED=1 bleibt als manuelle Uebersteuerung.
            # Bewusst NICHT in preflight.sh gespiegelt: der Preflight
            # beantwortet "kann Kimi laufen", nicht "kann resume laufen" -
            # er kennt den Modus nicht.
            RESUME_VERIFIED="$(_ov RESUME_VERIFIED)"; RESUME_VERIFIED="${RESUME_VERIFIED:-0}"
            if [ "$RESUME_VERIFIED" != "1" ] \
               && guard_marker_verified "$SKILLDIR/$PROFIL_T8_MARKER"; then
              RESUME_VERIFIED=1
            fi
            if [ "$RESUME_VERIFIED" != "1" ]; then
              echo "GESPERRT: resume ohne T8-Beleg (Thinking-Replay unbewiesen fuer diese Claude-Code-Version)." >&2
              echo "          Fix-Runde als frischen 'build'-Aufruf fahren (Delta-Findings + PLAN.md/STATE.md)," >&2
              echo "          oder erst 'bash $SKILLDIR/tests/t8-resume-thinking.sh $PROFIL' laufen lassen." >&2
              exit 6
            fi
            # Online-Zeuge (nur Profile, die ihn fordern - deepseek): der
            # T8-Mock beweist NUR das Client-Replay. Ob der Endpunkt
            # zurueckgespielte Thinking-Bloecke AKZEPTIERT, belegt erst ein
            # protokollierter echter resume; dessen Ergebnis legt die
            # Marker-Datei an. Die Uebersteuerung <PREFIX>_RESUME_VERIFIED=1
            # greift hier bewusst NICHT: der Zeuge betrifft den Server, nicht
            # den Client, und eine Client-Uebersteuerung darf ihn nicht
            # ersetzen.
            if [ -n "${PROFIL_RESUME_ONLINE_MARKER:-}" ] \
               && [ ! -r "$SKILLDIR/$PROFIL_RESUME_ONLINE_MARKER" ]; then
              echo "GESPERRT: resume ohne Online-Zeugen ($PROFIL_RESUME_ONLINE_MARKER fehlt)." >&2
              echo "          Ob der $PROFIL-Endpunkt Thinking-Replay akzeptiert, ist unbelegt." >&2
              echo "          Fix-Runde als frischen 'build'-Aufruf fahren, oder den" >&2
              echo "          protokollierten Echt-resume-Test fahren (siehe profiles/$PROFIL.conf)." >&2
              exit 6
            fi
            SID="$(tr -d ' \t\r\n' < "$STATE.build")"
            [ -n "$SID" ] || { echo "LEER: $STATE.build enthaelt keine Session-ID - erst 'build' laufen lassen." >&2; exit 5; }
            SESSION=(--resume "$SID")
            GUARD=(--permission-mode acceptEdits --tools "$RW_TOOLS") ;;
  *) usage ;;
esac

SCHEMA_ARGS=()
if [ "$SCHEMA" != "-" ]; then
  [ -r "$SCHEMA" ] || { echo "SCHEMA FEHLT: $SCHEMA" >&2; exit 2; }
  SCHEMA_ARGS=(--json-schema "$(cat "$SCHEMA")")
fi

RAW="$SKILLDIR/.$PROFIL_SESSION_PREFIX-raw-$SLUG-$MODE.json"

# --- Lauf -------------------------------------------------------------------
# --safe-mode schaltet CLAUDE.md, Skills, Plugins, Hooks und MCP ab: sonst
# gingen Geschaeftsstand und private Arbeitsvereinbarung schon beim ersten
# Token mit raus, und die Memory-Hooks wuerden den kuratierten Bestand mutieren.
#
# PROMPT KOMMT UEBER STDIN, NICHT ALS ARGUMENT (21.07.2026, /route-opus
# plattform-spike R3). Windows begrenzt die gesamte Kommandozeile auf 32767
# Zeichen (CreateProcess lpCommandLine). Ein Plan-Kritik-Prompt traegt den zu
# kritisierenden Plan INLINE - historisch, weil Kimi .planning/ ueberhaupt nicht
# lesen durfte (Deny-Regeln in den Settings; Riegel 1 prueft dagegen nur das
# Arbeitsverzeichnis). Seit Riegel 2b ist der Ordner des AKTIVEN Laufs lesbar,
# ein Datei-Verweis waere dort also moeglich - das Inline-Muster bleibt trotzdem
# der Standard, weil es auch fuer fremde Plaene und andere Repos traegt. Bei
# einem 29-KB-Freeze riss
# `claude -p "$PROMPT"` das Limit mit Exit 126 ("Argument list too long"),
# waehrend derselbe Aufruf eine Runde zuvor mit 23 KB noch durchlief - der
# Fehler taucht also erst auf, wenn ein Plan waechst, und sieht dann aus wie
# ein Kimi-Problem. `claude -p` ohne positionales Argument liest den Prompt aus
# stdin (dokumentiertes Muster `cat datei | claude -p`); damit steht nur noch
# das Schema in der Kommandozeile. NICHT auf das Argument zuruecksetzen.
set +e
printf '%s' "$PROMPT" | env -u ANTHROPIC_API_KEY -u ANTHROPIC_AUTH_TOKEN -u ANTHROPIC_MODEL \
    -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CODE_CHILD_SESSION \
    -u CLAUDE_CODE_ENTRYPOINT -u CLAUDE_CODE_EXECPATH -u CLAUDECODE \
  ANTHROPIC_BASE_URL="$WORKER_BASE_URL" \
  "$WORKER_KEY_VAR"="$WORKER_KEY" \
  ANTHROPIC_MODEL="$WORKER_MODEL" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="$WORKER_MODEL" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="$WORKER_MODEL" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="$WORKER_MODEL" \
  ANTHROPIC_DEFAULT_FABLE_MODEL="$WORKER_MODEL" \
  CLAUDE_CODE_SUBAGENT_MODEL="$WORKER_MODEL" \
  CLAUDE_CODE_AUTO_COMPACT_WINDOW="1048576" \
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1" \
  claude -p \
    "${SESSION[@]}" "${GUARD[@]}" \
    --safe-mode \
    --output-format json \
    ${SCHEMA_ARGS[@]+"${SCHEMA_ARGS[@]}"} \
    --settings "$SETTINGS_EFFEKTIV" \
    --disable-slash-commands \
    --max-budget-usd "$PROFIL_MAX_BUDGET_USD" \
  > "$RAW" 2> "$RAW.err"
RC=$?
set -e
if [ $RC -ne 0 ]; then
  # Ein Exit != 0 loescht die Modellantwort NICHT (SKILL.md, Artefakt-Handshake).
  # Eine vollstaendige structured_output neben einem Transportfehler ist
  # POSTPROCESSOR-RED, kein Absturz - so ging schon eine fertige Fremdfamilien-
  # Kritik verloren, die auf der Platte lag. Und der Fehlergrund steht in der
  # Roh-JSON, nicht in .err (memory/reference_kimi_worker_argument_limit.md).
  # Deshalb erst den Envelope befragen, dann urteilen. Der Unterschied haengt
  # am EXIT-CODE und nicht an einem Satz in der Ausgabe - eine Regel, die keine
  # Verzweigung anfasst, ist Protokoll und kein Gate:
  #   Exit 7   = Modell hat geliefert, Nachverarbeitung/Transport kaputt.
  #              $RAW aufheben und auswerten, NICHT als Absturz behandeln.
  #   Exit $RC = echter Absturz, kein verwertbarer Envelope.
  echo "WORKER-LAUF ($PROFIL) Exit $RC. Envelope $RAW wird zuerst befragt:" >&2
  set +e
  python - "$RAW" >&2 <<'PY'
import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception as e:
    print("  kein lesbares JSON (%s) - echter Absturz." % type(e).__name__)
    sys.exit(1)
print("  subtype=%r is_error=%r terminal_reason=%r"
      % (d.get("subtype"), d.get("is_error"), d.get("terminal_reason")))
so, txt = d.get("structured_output"), (d.get("result") or "")
if so is not None or txt.strip():
    print("  MODELLANTWORT VORHANDEN (structured_output=%s, result=%d Zeichen)."
          % (so is not None, len(txt)))
    print("  POSTPROCESSOR-RED, kein Absturz. Datei aufheben und auswerten.")
    sys.exit(7)
print("  kein structured_output und kein result - echter Absturz.")
sys.exit(1)
PY
  ENVRC=$?
  set -e
  tail -n 40 "$RAW.err" >&2
  [ "$ENVRC" -eq 7 ] && exit 7
  exit $RC
fi

# --- Kosten-Erfassung (v2.2) -------------------------------------------------
# Fremd-Worker laufen auf eigener Quota und tauchen in keiner Transkript-
# Messung auf - ohne diese Zeile schoent jeder Vorher/Nachher-Vergleich die
# Verlagerung von Arbeit (Plan-Review 01.09.2026). Der Envelope traegt usage
# und total_cost_usd; eine Zeile je Aufruf geht in WORKER-KOSTEN.md des
# aktiven Lauf-Ordners (nur wenn Riegel 2b ihn EINDEUTIG ermittelt hat),
# sonst als stderr-Zeile ins Protokoll der Boss-Session. Fail-open: eine
# scheiternde Erfassung darf keinen erfolgreichen Lauf toeten - sie meldet
# sich aber, statt still zu fehlen.
KOSTEN_ZIEL=""
if [ -n "${REPO_ROOT:-}" ] && [ -n "${LAUF_REL:-}" ] && [ "${LAUF_ANZAHL:-0}" -eq 1 ]; then
  KOSTEN_ZIEL="$REPO_ROOT/$LAUF_REL/WORKER-KOSTEN.md"
fi
python - "$RAW" "$PROFIL" "$MODE" "$SLUG" "$WORKER_MODEL" "$KOSTEN_ZIEL" <<'PY' || echo "HINWEIS: Worker-Kosten nicht erfasst (Envelope unlesbar?)." >&2
import datetime, io, json, sys
raw, profil, mode, slug, modell, ziel = sys.argv[1:7]
d = json.load(open(raw, encoding="utf-8"))
u = d.get("usage") or {}
zeile = "| %s | %s | %s | %s | %s | in=%s out=%s cr=%s cw=%s | usd=%s |" % (
    datetime.date.today().isoformat(), profil, modell, mode, slug,
    u.get("input_tokens", "?"), u.get("output_tokens", "?"),
    u.get("cache_read_input_tokens", "?"), u.get("cache_creation_input_tokens", "?"),
    d.get("total_cost_usd", "?"))
if ziel:
    neu = not __import__("os").path.exists(ziel)
    with io.open(ziel, "a", encoding="utf-8") as f:
        if neu:
            f.write("# Worker-Kosten (Fremd-Quota) - je Aufruf eine Zeile, geschrieben von worker.sh.\n")
            f.write("# S6 nimmt diese Summe ZUSAETZLICH zur kanten-messung auf; ohne sie gilt:\n")
            f.write('# "nur Boss-Kosten, Fremd-Quota unerfasst".\n')
            f.write("| Datum | Profil | Modell | Modus | Slug | Tokens | Kosten |\n")
        f.write(zeile + "\n")
    print("WORKER-KOSTEN -> " + ziel, file=sys.stderr)
else:
    print("WORKER-KOSTEN (kein eindeutiger Lauf-Ordner): " + zeile, file=sys.stderr)
PY

# --- Ausgabe ----------------------------------------------------------------
if [ "$SCHEMA" = "-" ] || [ "$OUT" = "-" ]; then
  python - "$RAW" <<'PY'
import json, sys, io
# Windows-Konsole laeuft hier auf cp1252. Kimi antwortet auf Deutsch, oft mit
# Emoji - ohne diese Umschaltung stirbt JEDE nicht-ASCII-Antwort im print mit
# UnicodeEncodeError, obwohl der Lauf selbst erfolgreich war (gemessen 19.07.).
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
d = json.load(open(sys.argv[1], encoding="utf-8"))
out = d.get("result") or d.get("structured_output")
print(out if isinstance(out, str) else json.dumps(out or d, ensure_ascii=False, indent=2))
PY
  exit 0
fi

# Zieldatei erst NACH bestandener Validierung schreiben - kein truncate-dann-sterben.
# jq ist auf dieser Maschine nicht installiert; python + jsonschema sind es.
python - "$RAW" "$SCHEMA" "$OUT" <<'PY'
import json, sys, io, jsonschema
# Gleicher cp1252-Grund wie oben: eine Schema-Verletzung druckt die
# beanstandeten Werte, und die sind deutschsprachig.
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")
raw, schema_path, out = sys.argv[1], sys.argv[2], sys.argv[3]
d = json.load(open(raw, encoding="utf-8"))
so = d.get("structured_output")
if so is None:                       # Fallback: Modell hat als Text geantwortet
    txt = (d.get("result") or "").strip()
    if txt.startswith("```"):
        txt = txt.split("```", 2)[1].lstrip("json").strip()
    try:
        so = json.loads(txt)
    except Exception:
        sys.exit("FEHLER: kein structured_output und result ist kein JSON "
                 "(subtype=%s). Zieldatei NICHT angefasst." % d.get("subtype"))
jsonschema.validate(so, json.load(open(schema_path, encoding="utf-8")))
json.dump(so, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print("SCHEMA OK ->", out)
PY

# Erfolg: die validierte Zieldatei steht, der Roh-Envelope ist damit redundant.
# SKILL.md, Artefakt-Handshake: "on success no raw log". Bei FEHLSCHLAG bleibt
# er ausdruecklich liegen - der Exit-7-Zweig oben braucht ihn, und der
# Fehlergrund steht dort und nicht in .err. Der schemalose chat-Pfad ist weiter
# oben schon mit exit 0 raus und behaelt seine Datei, weil es dort keine
# Zieldatei gibt, in der die Antwort sonst ueberlebte.
# Schlaegt die Validierung fehl, toetet set -e das Skript VOR dieser Zeile -
# das Aufraeumen darf nie den einzigen Beleg eines Fehlschlags loeschen.
rm -f "$RAW" "$RAW.err"
