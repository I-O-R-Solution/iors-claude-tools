#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Worker-Preflight (profiliert, v2.2) — prueft VOR der Einplanung die drei
# Riegel, an denen worker.sh in diesem Verzeichnis abbrechen wuerde:
# recht/, .env, Key. Antwort "ja" heisst also: keiner der drei Riegel greift
# — nicht, dass der Lauf gelingt. NICHT geprueft werden Dinge, die erst beim
# Lauf sichtbar sind: ob die claude-CLI erreichbar ist, ob der Key gueltig
# ist, ob Netz und Endpunkt antworten, ob das Budget reicht.
#
# Zweck: Ein Boss-Modell soll Kimi als Zweit-Reviewer einplanen koennen, ohne
# dass daraus eine Sackgasse wird. Ohne Preflight merkt es das Scheitern erst
# beim Aufruf und verbrennt Turns mit einer Fehlersuche, die immer gleich endet.
#
# Aufruf:  bash preflight.sh <profil> [--quiet]
# Exit:    0 = ja (Worker kann laufen)   1 = nein (Grund steht auf stdout)
#          2 = Aufruf-Fehler (Profil fehlt, unbekannter Schalter)
#
# Die Exit-Codes sind BEWUSST 0/1 statt der 3/4 aus worker.sh: so ist der
# Preflight direkt in einer if-Bedingung nutzbar.
#
#   if bash preflight.sh kimi --quiet; then ... ; fi
#
# Historie: bis 01.09.2026 hiess diese Datei kimi-preflight.sh;
# kimi-preflight.sh bleibt als Shim (exec preflight.sh kimi "$@") stehen.
#
# KEINE Seiteneffekte: nur lesen und pruefen. Es wird nichts angelegt, nichts
# geschrieben, nichts gesendet, keine Netzverbindung aufgebaut.
#
# ACHTUNG — GEMEINSAME RIEGEL, KEINE KOPIE (seit 26.07.2026):
# Riegel 1 und 2 rufen dieselben Funktionen aus kimi-guards.sh auf, die auch
# kimi-worker.sh benutzt. Vorher stand hier eine Kopie plus die Prosa-Regel
# "aendert sich der Worker, hier nachziehen". Sie hat zweimal nicht gehalten:
# die .env-Namensliste war in BEIDEN Dateien unvollstaendig, und eine
# Praezisierung von Riegel 1 im Worker liess diesen Preflight noch am selben
# Tag "nein" melden, wo der Worker laeuft. NICHT wieder auskopieren — eine
# Doppelung, die eine falsche Antwort produziert, ist teurer als der Umweg
# ueber eine gemeinsame Datei.
# Eigen bleibt hier zweierlei: die REIHENFOLGE der Riegel, die der des Workers
# entsprechen muss (sonst legt der Nutzer erst den Key an und stellt dann fest,
# dass es immer noch nicht geht), und die Formulierung der Antwort. Riegel 3
# (Key) bleibt bewusst eigenstaendig: er prueft nur Existenz und Fuellstand.
# ---------------------------------------------------------------------------
set -euo pipefail

SKILLDIR="C:/Users/User/.claude/skills/route"

# Erstes Argument ist das Profil (fail-closed, wie worker.sh).
[ $# -ge 1 ] || { echo "Aufruf: $0 <profil> [--quiet]" >&2; exit 2; }
PROFIL="$1"; shift
PROFILDATEI="$SKILLDIR/profiles/$PROFIL.conf"
[ -r "$PROFILDATEI" ] || { echo "PROFIL FEHLT: $PROFILDATEI" >&2; exit 2; }
. "$PROFILDATEI"
for PFLICHT in PROFIL_KEY_FILE PROFIL_T4_MARKER PROFIL_OVERRIDE_PREFIX; do
  [ -n "${!PFLICHT:-}" ] || { echo "PROFIL UNVOLLSTAENDIG: $PFLICHT fehlt in $PROFILDATEI." >&2; exit 2; }
done
_ov() { local n="${PROFIL_OVERRIDE_PREFIX}_$1"; printf '%s' "${!n:-}"; }

KEYFILE="$PROFIL_KEY_FILE"   # nur Existenz/Fuellstand, nie Inhalt

# Alle Argumente durchlaufen, nicht nur $1: ein zweiter Schalter darf nicht
# stumm verschluckt werden, und --quiet muss an jeder Position wirken.
QUIET=0
while [ $# -gt 0 ]; do
  case "$1" in
    --quiet) QUIET=1 ;;
    *)       echo "Aufruf: $0 <profil> [--quiet]" >&2; exit 2 ;;
  esac
  shift
done

# nein <Grund> <naechster Schritt>
nein() {
  if [ "$QUIET" -eq 0 ]; then
    echo "WORKER $PROFIL: nein — $1"
    echo "Naechster Schritt: $2"
  fi
  exit 1
}

# --- Riegel-Bausteine laden -------------------------------------------------
# Seit 26.07.2026 KEINE Kopie der Worker-Riegel mehr, sondern dieselbe Quelle.
# Die alte Prosa-Regel ("SPIEGEL-PFLICHT" im Kopf) hat zweimal nicht gehalten:
# die .env-Namensliste war in beiden Dateien unvollstaendig, und eine
# Praezisierung von Riegel 1 im Worker liess diesen Preflight noch am selben
# Tag "nein" melden, wo der Worker laeuft. Fail-closed: ohne die Datei keine
# Aussage, denn ein nicht geladener Riegel darf nie als bestandener gelten.
GUARDS="$SKILLDIR/kimi-guards.sh"
[ -r "$GUARDS" ] || nein "Riegel-Datei fehlt ($GUARDS)" \
  "Ohne kimi-guards.sh laesst sich nicht sagen, ob der Worker sperren wuerde. Datei wiederherstellen."
# Hinweis: die Riegel-Datei behaelt ihren historischen Namen kimi-guards.sh -
# ihre Funktionen sind profilneutral, nur die Sperrlisten-Begruendung im
# Kopf ist anbieter-spezifisch formuliert.
. "$GUARDS"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"

# --- Riegel 1: Arbeitsverzeichnis (worker.sh, Riegel 1) ---------------------
# Dieselbe Funktion, die der Worker aufruft. Normalisierung, Wurzel-Bezug und
# Begruendung der Sperrliste stehen in kimi-guards.sh.
CWD_WIN="$(pwd -W 2>/dev/null || pwd)"
if BLOCKED="$(guard_blocked_dir "$CWD_WIN" "$REPO_ROOT")"; then
  nein "gesperrtes Verzeichnis ($BLOCKED/)" \
       "Worker hier nicht einplanen — Personendaten, Geheimnisse oder Kernkapital. Ausserhalb dieses Ordners arbeiten, nicht umgehen."
fi

# --- Riegel 2: .env (worker.sh, Riegel 2) -----------------------------------
# Der Worker scannt aktuelles Verzeichnis + Repo-Root und nur solange der
# Guard nicht belegt ist. Belegt ist er, wenn <PREFIX>_ENV_GUARD_VERIFIED=1
# gesetzt ist ODER der T4-Marker des Profils die laufende Claude-Code-Version
# traegt. EXAKT diese Ableitung spiegeln, sonst meldet der Preflight "nein",
# wo der Worker laeuft.
ENV_GUARD_VERIFIED="$(_ov ENV_GUARD_VERIFIED)"; ENV_GUARD_VERIFIED="${ENV_GUARD_VERIFIED:-0}"
if [ "$ENV_GUARD_VERIFIED" != "1" ] && guard_marker_verified "$SKILLDIR/$PROFIL_T4_MARKER"; then
  ENV_GUARD_VERIFIED=1
fi
# Suchmuster und Ausnahmen: guard_find_env in kimi-guards.sh.
if [ "$ENV_GUARD_VERIFIED" != "1" ]; then
  if ENV_FUND="$(guard_find_env "." "$REPO_ROOT")"; then
    nein ".env-Schutz nicht per T4 belegt" \
      "Gefunden: $ENV_FUND. Entweder ausserhalb dieses Baums arbeiten, oder Test T4 fahren und danach ${PROFIL_OVERRIDE_PREFIX}_ENV_GUARD_VERIFIED=1 setzen."
  fi
fi

# --- Riegel 3: Key (worker.sh, Riegel 3) ------------------------------------
# NUR Existenz und Fuellstand. Der Inhalt wird nie gelesen, nie ausgegeben,
# nie gehasht und nie in eine Variable gelegt: `tr | wc -c` sieht nur die
# Byte-Zahl nach Entfernen von Whitespace. Genau das prueft auch worker.sh —
# eine Datei aus einem einzelnen Newline gilt dort als leer, `[ -s ]` wuerde
# sie faelschlich durchwinken.
[ -r "$KEYFILE" ] || nein "API-Key fehlt (Profil $PROFIL)" \
  "Datei $KEYFILE anlegen (eine Zeile, der API-Key). Nicht automatisiert erzeugen — Oliver legt sie selbst an."

# stderr der Pipe wird verworfen und ein unbrauchbares Ergebnis auf 0 gesetzt:
# ist der Pfad zwar lesbar, aber kein Regularfile (z. B. ein Verzeichnis),
# schriebe `tr` sonst quer an --quiet vorbei auf stderr. Fuer den Preflight ist
# ein nicht lesbarer Key derselbe Fall wie ein leerer: Kimi laeuft nicht.
KEY_BYTES="$( { tr -d ' \t\r\n' < "$KEYFILE" | wc -c; } 2>/dev/null | tr -d ' \r\n' || true)"
case "$KEY_BYTES" in
  ''|*[!0-9]*) KEY_BYTES=0 ;;
esac

if [ "$KEY_BYTES" -eq 0 ]; then
  nein "API-Key fehlt (Profil $PROFIL)" \
    "Datei $KEYFILE ist leer oder nicht lesbar. Den API-Key eintragen — nicht automatisiert erzeugen, Oliver traegt ihn selbst ein."
fi

# --- alle Riegel passiert ---------------------------------------------------
[ "$QUIET" -eq 1 ] || echo "WORKER $PROFIL: ja"
exit 0
