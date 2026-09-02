#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Test T9 — greifen Riegel 1 und Riegel 2, und sagen Worker und Preflight
# dasselbe?
#
# Aufruf:  bash tests/t9-riegel.sh
# Exit:    0 = bestanden   1 = NICHT bestanden
#
# Offline. Kein Kimi-Key noetig, kein Netz, keine Kosten: der Worker wird mit
# einem UNGUELTIGEN Modus aufgerufen. Die Riegel laufen dann vollstaendig
# durch, aber der Modus-Dispatch endet in `usage` (Exit 2), bevor irgendein
# claude-Prozess startet.
#
# --- WARUM ES DIESEN TEST GIBT (26.07.2026) --------------------------------
# Riegel 1 (Pfadsperre) und der .env-Scan waren als Kopie in kimi-worker.sh UND
# kimi-preflight.sh vorhanden, zusammengehalten von einer Prosa-Regel im Kopf
# des Preflights. Die Regel hat zweimal nicht gehalten:
#   - die .env-Namensliste war in BEIDEN Dateien unvollstaendig
#     (.env.staging/.development/.test liefen durch),
#   - eine Praezisierung von Riegel 1 im Worker liess den Preflight noch am
#     selben Tag "nein" melden, wo der Worker laeuft.
# Beide Male hat kein Test etwas gesagt, weil es keinen gab. Seitdem liegen die
# Riegel in kimi-guards.sh, und dieser Test haelt sie ehrlich.
#
# --- JEDER FALL WIRD IN BEIDE RICHTUNGEN GEPRUEFT --------------------------
# Ein Test, der nur "sperrt es?" fragt, ist auf einem Guard gruen, der ALLES
# sperrt - und ein solcher Guard wird in der Praxis abgeschaltet. Zu jedem
# Muss-sperren-Fall gehoert deshalb ein Muss-durchlassen-Fall:
#   Unterordner mapping/ sperrt   <-> Repo, das SELBST mapping heisst, laeuft
#   .env.staging sperrt           <-> .env.example laeuft
#   fehlende kimi-guards.sh sperrt <-> vorhandene laesst laufen
# ---------------------------------------------------------------------------
set -uo pipefail

SKILLDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Profil (v2.2): optionales erstes Argument, Default kimi.
PROFIL="${1:-kimi}"
[ -r "$SKILLDIR/profiles/$PROFIL.conf" ] || { echo "PROFIL FEHLT: $SKILLDIR/profiles/$PROFIL.conf" >&2; exit 1; }

WORKER="$SKILLDIR/worker.sh"
PREFLIGHT="$SKILLDIR/preflight.sh"
GUARDS="$SKILLDIR/kimi-guards.sh"

FEHLER=0
ok()   { printf '  OK   %s\n' "$1"; }
rot()  { printf '  ROT  %s\n' "$1"; FEHLER=$((FEHLER + 1)); }

T="$(mktemp -d)"
# Der Fail-closed-Fall verschiebt kimi-guards.sh. Ohne diesen trap bliebe die
# Datei nach einem Abbruch verschwunden - und beide Skripte waeren tot.
aufraeumen() {
  [ -e "$GUARDS.t9weg" ] && mv "$GUARDS.t9weg" "$GUARDS"
  rm -rf "$T"
}
trap aufraeumen EXIT

repo() {  # repo <relpfad> -> legt ein Git-Repo an und gibt den Pfad aus
  mkdir -p "$T/$1"
  ( cd "$T/$1" && git init -q . \
      && git config user.email t@t.t && git config user.name T ) >/dev/null 2>&1
  printf '%s' "$T/$1"
}

# worker_urteil <verzeichnis> -> "gesperrt" | "frei" | "unschluessig"
# Exit 3 = ein Riegel hat gesperrt. Exit 2 = alle Riegel passiert, `usage`.
# Alles andere (z. B. Exit 4, Key fehlt) ist unschluessig und faellt auf,
# statt sich als "frei" zu tarnen.
worker_urteil() {
  ( cd "$1" && bash "$WORKER" "$PROFIL" T9_UNGUELTIGER_MODUS t9slug - - x ) >/dev/null 2>&1
  case $? in 3) echo gesperrt ;; 2) echo frei ;; *) echo unschluessig ;; esac
}

# preflight_urteil <verzeichnis> -> "gesperrt" | "frei"
preflight_urteil() {
  ( cd "$1" && bash "$PREFLIGHT" "$PROFIL" --quiet ) >/dev/null 2>&1
  [ $? -eq 0 ] && echo frei || echo gesperrt
}

pruefe() {  # pruefe <verzeichnis> <erwartet> <beschreibung>
  local ist; ist="$(worker_urteil "$1")"
  [ "$ist" = "$2" ] && ok "$3 ($ist)" || rot "$3: erwartet $2, war $ist"
}

echo "T9 — Riegel 1 und 2, Worker gegen Preflight"
echo

echo "Riegel 1: Pfadsperre"
R="$(repo kunde)"; mkdir -p "$R/mapping" "$R/src"
pruefe "$R/mapping" gesperrt "Unterordner mapping/ im Repo"
pruefe "$R/src"     frei     "harmloser Unterordner src/"
R2="$(repo mapping)"
pruefe "$R2" frei "Repo, das SELBST mapping heisst (Wurzel-Falschalarm)"

echo
echo "Riegel 2: Umgebungsdateien (nur wirksam ohne T4-Beleg)"
# Der Riegel greift nur, solange der T4-Marker nicht zur laufenden Version
# passt. Ist er belegt, ist Riegel 2 inert - dann sagt dieser Block nichts und
# meldet das ehrlich, statt ein bedeutungsloses Gruen zu drucken.
E="$(repo mitenv)"; : > "$E/.env.staging"
X="$(repo mitbeispiel)"; : > "$X/.env.example"
if [ "$(worker_urteil "$E")" = "gesperrt" ]; then
  ok ".env.staging sperrt (Glob statt Namensliste)"
  [ "$(worker_urteil "$X")" = "frei" ] \
    && ok ".env.example laeuft (kein Fehlalarm auf Vorlagen)" \
    || rot ".env.example wurde gesperrt - Vorlagen-Ausnahme kaputt"
else
  printf '  --   Riegel 2 ist inert (T4-Marker passt zur laufenden Version).\n'
  printf '       Aussagekraeftig erst nach einem Claude-Code-Update oder mit\n'
  printf '       einem absichtlich falschen .kimi-t4-passed.\n'
fi

echo
echo "Worker und Preflight muessen dasselbe sagen"
for d in "$R/mapping" "$R/src" "$R2"; do
  w="$(worker_urteil "$d")"; p="$(preflight_urteil "$d")"
  [ "$w" = "$p" ] && ok "einig ueber $(basename "$d"): $w" \
                  || rot "uneinig ueber $d: Worker=$w Preflight=$p"
done

echo
echo "Fail-closed: ohne kimi-guards.sh darf nichts laufen"
mv "$GUARDS" "$GUARDS.t9weg"
[ "$(worker_urteil "$R/src")" = "gesperrt" ] \
  && ok "Worker bricht ohne Riegel-Datei ab" \
  || rot "Worker lief OHNE geladene Riegel - fail-open"
[ "$(preflight_urteil "$R/src")" = "gesperrt" ] \
  && ok "Preflight meldet ohne Riegel-Datei nein" \
  || rot "Preflight meldete ja OHNE geladene Riegel - fail-open"
mv "$GUARDS.t9weg" "$GUARDS"
[ "$(worker_urteil "$R/src")" = "frei" ] \
  && ok "mit wiederhergestellter Riegel-Datei laeuft es wieder (Gegenprobe)" \
  || rot "nach Wiederherstellung immer noch gesperrt"

echo
if [ "$FEHLER" -eq 0 ]; then
  echo "T9 BESTANDEN"; exit 0
else
  echo "T9 NICHT BESTANDEN ($FEHLER Fehler)"; exit 1
fi
