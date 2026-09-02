#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Gemeinsame Riegel-Bausteine fuer kimi-worker.sh und kimi-preflight.sh.
#
# WARUM ES DIESE DATEI GIBT (26.07.2026)
# Beide Skripte trugen dieselben Riegel als Kopie, festgehalten als Prosa-Regel
# ("SPIEGEL-PFLICHT") im Kopf des Preflights. Die Regel hat nicht gehalten:
#   - Die Namensliste im .env-Scan war in BEIDEN Dateien unvollstaendig
#     (.env.staging/.development/.test liefen durch, gemessen 26.07.).
#   - Eine Praezisierung von Riegel 1 im Worker liess den Preflight noch am
#     selben Tag "nein" melden, wo der Worker laeuft.
# Eine Doppelung, die eine FALSCHE ANTWORT produziert, ist teurer als eine
# Include-Abhaengigkeit: der Preflight beantwortet "kann Kimi laufen", und ein
# falsches Ja schickt einen Lauf in die Sackgasse, ein falsches Nein verhindert
# ihn grundlos. Die Reihenfolge der Riegel bleibt Sache der Aufrufer, die
# ENTSCHEIDUNG liegt ab jetzt hier.
#
# Diese Datei wird nur GESOURCET, nie ausgefuehrt. Beide Aufrufer brechen
# fail-closed ab, wenn sie fehlt - ein nicht geladener Riegel darf nie als
# bestandener Riegel durchgehen.
# ---------------------------------------------------------------------------

# Sperrliste fuer Riegel 1. Deckungsgleich mit den Read()/Edit()-Deny-Regeln in
# kimi-worker-settings.json - wer hier etwas aendert, aendert dort mit, sonst
# schuetzt eine Schicht etwas, das die andere durchlaesst.
#   recht/datenschutz  TOM/VVT/DPA-Kette: Personendaten Dritter aus den
#                      E-Signatur-Audit-Trails, dazu die eigene Angriffskarte
#                      (tom-art32.md benennt offene 2FA-Luecken und SSH-Details)
#   marketing          Akquise-Mails mit Klarnamen realer Interessenten
#   mapping/.planning  kein Personenbezug, aber Kernkapital und Preisstaffeln -
#                      und die Kimi-ToS erlauben Training auf Inhalten.
#                      AUSNAHME: der Ordner des AKTIVEN Route-Laufs wird von
#                      Riegel 2b im Worker freigeschaltet, siehe dort.
#   website/rechtstexte, videokurs-cockpit-first-deploy  Anschriften bzw. der
#                      bcrypt-Hash der Live-Admin-Basic-Auth
GUARD_BLOCKED=("recht/datenschutz" "marketing" "mapping" ".planning" \
               "website/rechtstexte" "videokurs-cockpit-first-deploy")

# guard_cc_version
# Laufende Claude-Code-Version, leer wenn nicht ermittelbar.
# `|| true`: schlaegt grep fehl (claude fehlt, Version unlesbar), wuerde
# pipefail+set -e den Aufrufer sonst wortlos toeten, BEVOR der dokumentierte
# fail-safe-Pfad (leere Version -> gesperrt) ueberhaupt greifen kann.
guard_cc_version() {
  claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true
}

# guard_marker_verified <markerdatei>
# Exit 0 = Marker vorhanden UND Zeile 1 gleich der laufenden Version.
# Alles andere - fehlende Datei, Claude-Code-Update, unlesbare Version - ist
# Exit 1 und damit gesperrt. So faellt der Schutz nach einem Update von selbst
# zu, statt still stale zu gelten.
guard_marker_verified() {
  local marker="$1" belegt laufend
  [ -r "$marker" ] || return 1
  belegt="$(head -n1 "$marker" | tr -d ' \t\r\n')"
  laufend="$(guard_cc_version)"
  [ -n "$laufend" ] && [ "$belegt" = "$laufend" ]
}

# guard_blocked_dir <cwd> [repo_root]
# Gibt den getroffenen Sperrlisten-Eintrag aus (Exit 0) oder nichts (Exit 1).
# Kleinschreibung, weil das Windows-Dateisystem gross-klein-unempfindlich ist:
# "Recht/" und "RECHT/" fuehren in denselben Ordner, ohne Normalisierung waere
# der Riegel per Schreibweise umgehbar. Backslashes vereinheitlicht, sonst
# braeuchte jeder Eintrag zwei Muster.
# Verglichen wird NUR der Teil UNTERHALB der Repo-Wurzel: vorher traf der
# absolute Vergleich auch Segmente OBERHALB davon, ein Repo namens "mapping"
# war komplett gesperrt (gemessen 26.07.). LESSONS.md 20.07. nennt diese
# Klasse, und ein Falsch-Positiv dieser Sorte fuehrt in der Praxis zum
# Abschalten des Guards, ist also schwerer als eine offene Luecke. Die
# Sperrliste beschreibt ausnahmslos Ordner INNERHALB eines Projekts.
# Ohne Repo-Wurzel bleibt der absolute Vergleich stehen - fail-closed.
# Das Muster wird gequotet abgezogen: ein Wurzelpfad mit [ oder ? wuerde sonst
# als Glob gelesen und der Abzug griffe still daneben.
guard_blocked_dir() {
  local cwd_lc root_lc pruef eintrag
  cwd_lc="${1,,}"; cwd_lc="${cwd_lc//\\//}"
  pruef="$cwd_lc"
  if [ -n "${2:-}" ]; then
    root_lc="${2,,}"; root_lc="${root_lc//\\//}"
    case "$cwd_lc" in "$root_lc"*) pruef="${cwd_lc#"$root_lc"}" ;; esac
  fi
  for eintrag in "${GUARD_BLOCKED[@]}"; do
    case "$pruef/" in *"/$eintrag/"*) printf '%s' "$eintrag"; return 0 ;; esac
  done
  return 1
}

# guard_find_env <verzeichnis>...
# Gibt den Pfad der ERSTEN gefundenen Umgebungsdatei aus (Exit 0), sonst nichts.
# Glob statt Aufzaehlung: drei feste Namen lasen sich wie eine Definition, waren
# aber ein Beispielsatz - .env.staging, .env.development und .env.test liefen
# gemessen durch. Jetzt deckungsgleich mit Read(**/.env.*) in
# kimi-worker-settings.json.
# Ohne nullglob bleibt ein leeres Muster unaufgeloest stehen, deshalb [ -e ].
# .example/.sample sind Vorlagen ohne Geheimnisse: ein Falsch-Positiv dieser
# Sorte fuehrt in der Praxis zum Abschalten des Guards.
guard_find_env() {
  local d f
  for d in "$@"; do
    [ -n "$d" ] || continue
    for f in "$d"/.env*; do
      [ -e "$f" ] || continue
      case "$f" in *.example|*.sample) continue ;; esac
      printf '%s' "$f"; return 0
    done
  done
  return 1
}
