#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""zonen-melder.py - PostToolUse-Hook: meldet den Kontextstand ungefragt.

WARUM ES DIESEN HOOK GIBT
Die 200k-Regel stand ab 2026-07-17 im route-Skill und blieb wirkungslos, weil im
Loop nichts messt - eine Session lief blind auf 440k (gemessen 25.07.2026). Danach
bekam die Regel einen Messbefehl. Der hing aber weiter an der Disziplin des
Modells, und genau diese Klasse ist zweimal belegt zurueckgefallen. Dieser Hook
nimmt den Ausloeser aus der Hand des Modells: er misst selbst und spricht, wenn es
zaehlt.

BAUPRINZIPIEN, die nicht verhandelbar sind
1. FAIL-OPEN. Jeder Fehler endet mit Exit 0 und ohne Ausgabe. Ein Waechter, der
   Werkzeugaufrufe kaputtmacht, wird abgeschaltet - und dann misst wieder niemand.
2. SCHNELL. Kein Vollparse des Transkripts (1,6 MB nach 120 Turns). Nur der
   Schwanz der Datei wird gelesen und die letzte usage-Zeile ausgewertet.
3. LEISE. Unter 200k gar keine Ausgabe. Jede Zeile, die dieser Hook druckt, landet
   selbst im Kontext - ein geschwaetziger Melder finanziert das Problem, das er
   melden soll. Innerhalb einer Zone wird deshalb gedrosselt: der Zonen-WECHSEL
   spricht immer, danach LANDEN jeden 5. und HALTEPUNKT jeden 3. Aufruf. Bis zum
   26.07.2026 sprach HALTEPUNKT bei JEDEM Aufruf - gemessen 11 gleichlautende
   Meldungen hintereinander, was diesem Prinzip widersprach.

Feldnamen aus dem echten Transkript geprueft (25.07.2026), nicht geraten:
input_tokens + cache_creation_input_tokens + cache_read_input_tokens.
"""

import json
import os
import sys
from pathlib import Path

# ACHTUNG, ZWEITE STELLE: dieselben drei Werte stehen inline in
# tools/kontext-jetzt.sh:31-33. Bewusst nicht zu einer Konstantendatei
# zusammengezogen - dieser Hook laeuft bei JEDEM Werkzeugaufruf und ist
# absichtlich abhaengigkeitsfrei; ein Import waere ein Ausfallpunkt genau dort,
# wo Bauprinzip 1 jeden Fehler stumm schluckt. Den Gleichstand sichert
# stattdessen tests/zonen-gleichstand.test.sh an allen sechs Grenzwerten.
# Wer hier eine Zahl aendert, aendert sie dort mit und faehrt den Test.
SCHWELLE_ARBEITEN = 200_000
SCHWELLE_PLANEN = 300_000
SCHWELLE_LANDEN = 400_000
SCHWANZ_BYTES = 262_144          # 256 KB reichen fuer viele letzte Zeilen
WIEDERHOLUNG_LANDEN = 5          # in der LANDEN-Zone alle n Aufrufe erinnern
WIEDERHOLUNG_HALTEPUNKT = 3      # in HALTEPUNKT alle n Aufrufe (gedrosselt 26.07.2026)


def zone(stand):
    if stand < SCHWELLE_ARBEITEN:
        return "ARBEITEN"
    if stand < SCHWELLE_PLANEN:
        return "PLANEN"
    if stand < SCHWELLE_LANDEN:
        return "LANDEN"
    return "HALTEPUNKT"


def letzter_stand(pfad):
    """Kontext der letzten abgeschlossenen Antwort. None, wenn nicht ermittelbar."""
    groesse = pfad.stat().st_size
    with pfad.open("rb") as fh:
        if groesse > SCHWANZ_BYTES:
            fh.seek(groesse - SCHWANZ_BYTES)
            fh.readline()          # angeschnittene erste Zeile verwerfen
        zeilen = fh.read().decode("utf-8", "replace").splitlines()
    for zeile in reversed(zeilen):
        if '"usage"' not in zeile:
            continue
        try:
            satz = json.loads(zeile)
        except ValueError:
            continue
        nutzung = (satz.get("message") or {}).get("usage") or satz.get("usage")
        if not isinstance(nutzung, dict):
            continue
        stand = (nutzung.get("input_tokens", 0)
                 + nutzung.get("cache_creation_input_tokens", 0)
                 + nutzung.get("cache_read_input_tokens", 0))
        if stand > 0:
            return stand
    return None


def subagenten(basis, sitzung):
    ordner = basis / sitzung / "subagents"
    if not ordner.is_dir():
        return 0
    return sum(1 for _ in ordner.glob("*.jsonl"))


def melde(stand, wie_viele_subagenten):
    z = zone(stand)
    kopf = f"KONTEXT {stand // 1000}k - ZONE {z}"
    if wie_viele_subagenten:
        kopf += f" - {wie_viele_subagenten} Subagenten (nicht in dieser Zahl)"
    if z == "PLANEN":
        rat = ("Nur noch KLEIN oder MITTEL beginnen (KOSTEN.md). "
               "Spielraum bis zur Landereserve: "
               f"{(SCHWELLE_LANDEN - 40_000 - stand) // 1000}k.")
    elif z == "LANDEN":
        rat = ("Nichts Neues beginnen. Offenes abschliessen, verifizieren, "
               "committen, STATE.md schreiben, schneiden.")
    else:
        rat = ("Zum naechsten Haltepunkt gehen und dort landen - KEIN Abbruch. "
               "Haltepunkte: Worker-Antwort da, Verifikation fertig, Commit "
               "existiert. STATE.md nicht vergessen.")
    return f"{kopf}. {rat}"


def main():
    sitzung = os.environ.get("CLAUDE_CODE_SESSION_ID")
    if not sitzung:
        return
    basis_kandidaten = list(Path.home().glob(f".claude/projects/*/{sitzung}.jsonl"))
    if not basis_kandidaten:
        return
    transkript = basis_kandidaten[0]

    stand = letzter_stand(transkript)
    if stand is None or stand < SCHWELLE_ARBEITEN:
        return

    z = zone(stand)
    # BEKANNTE RACE (dokumentiert 26.07.2026, bewusst nicht gesperrt): Lesen und
    # Schreiben der Marke sind zwei Schritte. Claude Code fuehrt Werkzeuge parallel
    # aus, zwei Hook-Instanzen koennen sich also ueberholen und ein Zaehler-Inkrement
    # verlieren. Folge ist ausschliesslich, dass die LANDEN-Erinnerung einen Aufruf
    # spaeter kommt - der Zonen-Wechsel selbst haengt nicht am Zaehler. Ein Lock
    # waere teurer als der Schaden und verletzt Bauprinzip 1 (fail-open): eine
    # haengende Sperre wuerde Werkzeugaufrufe verzoegern.
    marke = Path.home() / ".claude" / "skills" / "route" / f".zone-{sitzung}"
    zuletzt, zaehler = "", 0
    if marke.exists():
        teile = marke.read_text(encoding="utf-8").strip().split()
        if len(teile) == 2:
            zuletzt, zaehler = teile[0], int(teile[1])

    zaehler += 1
    # Der Zonen-WECHSEL spricht immer - dort ist die Nachricht neu. Innerhalb
    # einer Zone wird gedrosselt, sonst steht dieselbe Warnung bei jedem
    # Werkzeugaufruf erneut im Verlauf (gemessen 26.07.2026: 11 Meldungen
    # hintereinander in HALTEPUNKT, Marke .zone-fb458be0).
    sprechen = (z != zuletzt) or (
        z == "HALTEPUNKT" and zaehler % WIEDERHOLUNG_HALTEPUNKT == 0) or (
        z == "LANDEN" and zaehler % WIEDERHOLUNG_LANDEN == 0)
    marke.write_text(f"{z} {0 if z != zuletzt else zaehler}\n", encoding="utf-8")

    if sprechen:
        print(melde(stand, subagenten(transkript.parent, sitzung)))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass          # fail-open, immer Exit 0 - siehe Bauprinzip 1
    sys.exit(0)
