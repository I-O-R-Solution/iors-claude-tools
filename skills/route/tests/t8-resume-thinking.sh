#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# T8 — Resume-Denkverlauf-Test fuer den Kimi-Worker.
#
# Frage: Spielt `claude -p --resume` (headless, --safe-mode, wie in
# kimi-worker.sh) die Thinking-Bloecke frueherer Assistant-Turns an den
# Endpunkt zurueck?
#
# Warum das zaehlt: Moonshot dokumentiert fuer K3, dass die Qualitaet "highly
# unstable" wird, wenn der Harness nicht den vollstaendigen Denkverlauf
# zurueckschickt. kimi-worker.sh Modus `resume` haengt also daran, ob der
# Claude-Code-Client das tut - versionsabhaengiges Client-Verhalten, darum
# wie T4 versionsgebunden belegt.
#
# Messmethode - komplett OFFLINE, kein Key, kein Moonshot, keine Kosten:
#   1. Mock-Server (t8-mock-server.py) auf 127.0.0.1, antwortet mit einem
#      Thinking-Block, der einen eindeutigen Marker traegt, und loggt jeden
#      Request-Body.
#   2. Turn 1: claude -p --session-id gegen den Mock (Env-Setup exakt wie
#      kimi-worker.sh, nur BASE_URL/Key ersetzt).
#   3. Turn 2: claude -p --resume <selbe Session>.
#   4. Auswertung: enthaelt ein Turn-2-Request einen Assistant-Thinking-Block
#      mit dem Marker?
#
# Ergebnis:
#   PASS  -> .kimi-t8-passed (Zeile 1 = claude-Version) wird geschrieben;
#            kimi-worker.sh Modus resume entsperrt fuer exakt diese Version.
#   FAIL  -> Thinking wird NICHT zurueckgespielt; ein etwaiger stale Marker
#            fuer die laufende Version wird entfernt. resume bleibt zu -
#            Fix-Runden als frischer build-Aufruf fahren.
#   Exit: 0 = PASS, 1 = FAIL, 2 = Infrastruktur/unklar (nichts geschrieben).
# ---------------------------------------------------------------------------
set -euo pipefail

SKILLDIR="C:/Users/User/.claude/skills/route"

# Profil (v2.2): optionales erstes Argument, Default kimi. Die Messung selbst
# ist profilunabhaengig (Client-Verhalten gegen einen Mock) — profiliert ist
# nur, WELCHER Marker bei PASS geschrieben wird.
PROFIL="${1:-kimi}"
PROFILDATEI="$SKILLDIR/profiles/$PROFIL.conf"
[ -r "$PROFILDATEI" ] || { echo "PROFIL FEHLT: $PROFILDATEI" >&2; exit 2; }
. "$PROFILDATEI"

MARKER_FILE="$SKILLDIR/$PROFIL_T8_MARKER"
MOCK_PY="$SKILLDIR/tests/t8-mock-server.py"
export T8_SETTINGS="$SKILLDIR/$PROFIL_SETTINGS_FILE"

TMPDIR_T8="$(mktemp -d)"
REQLOG="$TMPDIR_T8/requests.jsonl"
PORTFILE="$TMPDIR_T8/port"
export T8_WORKDIR="$TMPDIR_T8/work"
mkdir -p "$T8_WORKDIR"
: > "$REQLOG"

SERVER_PID=""
cleanup() {
  [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2>/dev/null || true
  rm -rf "$TMPDIR_T8" 2>/dev/null || true
}
trap cleanup EXIT

python "$MOCK_PY" "$REQLOG" "$PORTFILE" &
SERVER_PID=$!

# Auf den Port warten (Server bindet Port 0 und schreibt ihn in die Datei).
PORT=""
for _ in $(seq 1 50); do
  if [ -s "$PORTFILE" ]; then PORT="$(cat "$PORTFILE")"; break; fi
  sleep 0.2
done
[ -n "$PORT" ] || { echo "T8: FEHLER - Mock-Server startet nicht." >&2; exit 2; }
export T8_MOCK_URL="http://127.0.0.1:$PORT"

curl -s -o /dev/null --max-time 5 "$T8_MOCK_URL/health" \
  || { echo "T8: FEHLER - Mock-Server antwortet nicht auf $T8_MOCK_URL." >&2; exit 2; }

SID="$(powershell.exe -NoProfile -Command '[guid]::NewGuid().ToString()' | tr -d '\r\n')"

# Helper-Skript: exakt das Env-Setup aus kimi-worker.sh, nur BASE_URL und
# Dummy-Key ersetzt. Eigene Datei, damit `timeout` es als Kommando fassen kann.
CALL="$TMPDIR_T8/call.sh"
cat > "$CALL" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
PROMPT="$1"; shift
cd "$T8_WORKDIR"
exec env -u ANTHROPIC_API_KEY -u ANTHROPIC_AUTH_TOKEN -u ANTHROPIC_MODEL \
    -u CLAUDE_CODE_SESSION_ID -u CLAUDE_CODE_CHILD_SESSION \
    -u CLAUDE_CODE_ENTRYPOINT -u CLAUDE_CODE_EXECPATH -u CLAUDECODE \
  ANTHROPIC_BASE_URL="$T8_MOCK_URL" \
  ANTHROPIC_API_KEY="t8-dummy-key" \
  ANTHROPIC_MODEL="k3" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="k3" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="k3" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="k3" \
  ANTHROPIC_DEFAULT_FABLE_MODEL="k3" \
  CLAUDE_CODE_SUBAGENT_MODEL="k3" \
  CLAUDE_CODE_AUTO_COMPACT_WINDOW="1048576" \
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1" \
  claude -p "$PROMPT" \
    "$@" \
    --permission-mode acceptEdits --tools "Read,Grep,Glob" \
    --safe-mode \
    --output-format json \
    --settings "$T8_SETTINGS" \
    --disable-slash-commands \
    --max-budget-usd 8
EOF
chmod +x "$CALL"

TIMEOUT_CMD=()
command -v timeout >/dev/null 2>&1 && TIMEOUT_CMD=(timeout 180)

# Beide Prompts als Variablen: der Turn-2-Text ist zugleich das Erkennungs-
# merkmal, mit dem die Auswertung den echten Turn-2-Request identifiziert -
# robust gegen Log-Races und /count_tokens-Beifang.
TURN1_PROMPT="Sag kurz hallo."
TURN2_PROMPT="Was hast du eben geantwortet?"

echo "T8: Turn 1 (Session $SID) ..."
set +e
"${TIMEOUT_CMD[@]+"${TIMEOUT_CMD[@]}"}" bash "$CALL" "$TURN1_PROMPT" --session-id "$SID" \
  > "$TMPDIR_T8/turn1.json" 2> "$TMPDIR_T8/turn1.err"
RC1=$?
set -e
if [ $RC1 -ne 0 ]; then
  echo "T8: FEHLER - Turn 1 fehlgeschlagen (Exit $RC1). stderr:" >&2
  tail -n 20 "$TMPDIR_T8/turn1.err" >&2
  exit 2
fi

echo "T8: Turn 2 (--resume) ..."
set +e
"${TIMEOUT_CMD[@]+"${TIMEOUT_CMD[@]}"}" bash "$CALL" "$TURN2_PROMPT" --resume "$SID" \
  > "$TMPDIR_T8/turn2.json" 2> "$TMPDIR_T8/turn2.err"
RC2=$?
set -e
if [ $RC2 -ne 0 ]; then
  echo "T8: FEHLER - Turn 2 (--resume) fehlgeschlagen (Exit $RC2). stderr:" >&2
  tail -n 20 "$TMPDIR_T8/turn2.err" >&2
  exit 2
fi

# Auswertung. Als Beleg zaehlt NUR ein Request, der (a) auf /messages ging
# (nicht /count_tokens) und (b) den Turn-2-User-Prompt enthaelt - damit sind
# Log-Races (spaet geloggte Turn-1-Requests) und Token-Zaehl-Beifang raus.
# PASS setzt den Marker-INHALT voraus; ein Thinking-Block ohne Marker
# (gestrippt/redacted) ist FAIL, denn Moonshot braucht den nutzbaren Text.
set +e
python - "$REQLOG" "$TURN2_PROMPT" <<'PY'
import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
reqlog, turn2_prompt = sys.argv[1], sys.argv[2]
MARKER = "T8-THINKING-MARKER-8f3a1c"
ANSWER = "T8-ANTWORT"

thinking_replayed = False
history_replayed = False
stripped_thinking = False
qualified = 0

for line in open(reqlog, encoding="utf-8").read().splitlines():
    try:
        rec = json.loads(line)
    except Exception:
        continue
    if not (rec.get("path") or "").endswith("/messages"):
        continue
    body = rec.get("body") or {}
    msgs = body.get("messages") or []

    is_turn2 = False
    for msg in msgs:
        if msg.get("role") != "user":
            continue
        c = msg.get("content")
        if isinstance(c, str) and turn2_prompt in c:
            is_turn2 = True
        elif isinstance(c, list):
            for b in c:
                if isinstance(b, dict) and b.get("type") == "text" \
                        and turn2_prompt in (b.get("text") or ""):
                    is_turn2 = True
    if not is_turn2:
        continue
    qualified += 1

    for msg in msgs:
        if msg.get("role") != "assistant":
            continue
        content = msg.get("content")
        if isinstance(content, str):
            if ANSWER in content:
                history_replayed = True
            continue
        for block in content or []:
            if not isinstance(block, dict):
                continue
            t = block.get("type")
            if t == "text" and ANSWER in (block.get("text") or ""):
                history_replayed = True
            elif t == "thinking" and MARKER in (block.get("thinking") or ""):
                thinking_replayed = True
            elif t in ("thinking", "redacted_thinking"):
                stripped_thinking = True

if qualified == 0:
    print("T8: UNKLAR - kein /messages-Request mit dem Turn-2-Prompt gefunden.")
    sys.exit(2)
if thinking_replayed:
    print("T8: PASS - Thinking-Block aus Turn 1 (Marker-Inhalt) wurde beim --resume zurueckgespielt.")
    sys.exit(0)
if stripped_thinking:
    print("T8: FAIL - Thinking kam nur ohne Marker-Inhalt an (gestrippt/redacted) - fuer Moonshot unbrauchbar.")
    sys.exit(1)
if history_replayed:
    print("T8: FAIL - Historie kam an, aber OHNE den Thinking-Block (Marker fehlt).")
    sys.exit(1)
print("T8: UNKLAR - Turn-2-Request gefunden, aber weder Thinking noch Assistant-Historie darin.")
sys.exit(2)
PY
VERDICT=$?
set -e

CC_VER="$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true)"

case "$VERDICT" in
  0)
    [ -n "$CC_VER" ] || { echo "T8: FEHLER - claude-Version nicht ermittelbar, Marker NICHT geschrieben." >&2; exit 2; }
    printf '%s\nT8 bestanden am %s - Thinking-Replay bei --resume belegt (Mock-Messung, tests/t8-resume-thinking.sh).\n' \
      "$CC_VER" "$(date +%Y-%m-%d)" > "$MARKER_FILE"
    echo "T8: Marker geschrieben: $MARKER_FILE (Version $CC_VER). worker.sh $PROFIL resume: T8-Gate offen."
    if [ -n "${PROFIL_RESUME_ONLINE_MARKER:-}" ] && [ ! -r "$SKILLDIR/$PROFIL_RESUME_ONLINE_MARKER" ]; then
      echo "T8: HINWEIS - Profil $PROFIL verlangt zusaetzlich den Online-Zeugen ($PROFIL_RESUME_ONLINE_MARKER)."
      echo "    resume bleibt bis zu dessen protokolliertem Echt-Lauf gesperrt (siehe profiles/$PROFIL.conf)."
    fi
    exit 0 ;;
  1)
    if [ -n "$CC_VER" ] && [ -r "$MARKER_FILE" ] && [ "$(head -n1 "$MARKER_FILE" | tr -d ' \t\r\n')" = "$CC_VER" ]; then
      rm -f "$MARKER_FILE"
      echo "T8: stale Marker fuer $CC_VER entfernt."
    fi
    echo "T8: resume bleibt GESPERRT ($PROFIL). Fix-Runden als frischen 'build'-Aufruf fahren (Delta-Findings + PLAN.md/STATE.md)."
    exit 1 ;;
  *)
    echo "T8: kein Beleg in beide Richtungen - nichts geschrieben, resume bleibt gesperrt (safe-by-default)."
    exit 2 ;;
esac
