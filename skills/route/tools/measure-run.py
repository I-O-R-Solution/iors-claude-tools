#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""measure-run.py - misst Token-Verbrauch und Kosten eines Claude-Code-Laufs.

Beweisgrundlage fuer den route-Umbau: ohne Messung ist jede Ersparnis behauptet.
Liest Session-.jsonl-Dateien zeilenweise (Streaming, auch bei 100+ MB) und
rechnet die usage-Felder der Assistant-Antworten in Dollar um.

Aufruf:
    python measure-run.py <pfad-zur-session.jsonl> [--json] [--bis-turn N]
    python measure-run.py            # neueste .jsonl des aktuellen Arbeitsverzeichnisses
    python measure-run.py --lauf a.jsonl b.jsonl c.jsonl [--json]
    python measure-run.py --lauf "~/.claude/projects/<ws>/*.jsonl"

Warum --lauf und nicht einfach mehrere Positionsargumente:
Ein route-Lauf verteilt sich seit dem Umbau ueber mehrere Sessions, mit einem
Schnitt an jeder Phasenkante. Gemessen werden muss der LAUF, nicht die Datei.
Mehrere Positionsargumente waeren die gefaehrlichere Form: ein
"measure-run.py *.jsonl" im Projektordner wuerde Dutzende voellig unbeteiligter
Sessions zu einer plausibel aussehenden Gesamtzahl verschmelzen, die niemand
mehr zurueckverfolgen kann. --lauf zwingt zur ausdruecklichen Behauptung "diese
Sessions gehoeren zu EINEM Lauf"; der Bericht listet sie dann chronologisch mit
Einzelsummen auf, damit ein falsch zusammengestellter Satz sofort auffaellt.
Glob-Muster werden intern aufgeloest - unter Windows expandiert die Konsole
nicht selbst.

Bezugsrahmen - der wichtigste Punkt beim Vergleichen:
Sub-Agenten laufen in eigenen Dateien. Wer nur die Hauptdatei misst, sieht eine
Verlagerung von Arbeit in Sub-Agenten als Ersparnis. Die Zahl unter GESAMT ist
deshalb immer Hauptlauf PLUS Sub-Agenten; alles andere ist als Teilmenge
beschriftet. Laesst sich die Gesamtzahl nicht ehrlich bilden, wird sie
weggelassen statt geschaetzt.

Preisbasis - zwei Rahmen, die nie stillschweigend gemischt werden:
  * "fable_pauschal": alles zu Fable-5-Preisen. Voreinstellung im
    Einzeldatei-Bericht, damit aeltere Baselines vergleichbar bleiben.
  * "je_modell": jede Anfrage zum Preis ihres eigenen Modells. Voreinstellung
    im Lauf-Bericht, denn der traegt den Kostenanspruch des Skills und muss
    stimmen. Sub-Agenten laufen oft auf billigeren Modellen - pauschal
    gerechnet ist die Zahl zu hoch.
Jeder Bericht nennt seine Basis; der Lauf-Bericht zeigt zusaetzlich, was die
andere Basis ergaebe, damit die Differenz sichtbar ist statt behauptet.

stdlib-only, keine Installation noetig.
"""

import argparse
import glob as globmodul
import json
import os
import sys
from datetime import datetime

# ---------------------------------------------------------------------------
# Preise in US-Dollar je 1 Mio. Token (Stand 07/2026).
#
# Gepflegt werden nur Input und Output. Cache-Read (0,1x Input) und Cache-Write
# (1,25x Input, 5-Min-TTL) leiten sich daraus ab - zwei Zahlen je Modell statt
# vier, und die Cache-Regel steht als Regel da statt viermal ausgeschrieben.
#
# Warum ueberhaupt eine Tabelle je Modell: Sub-Agenten laufen regelmaessig auf
# anderen Modellen als der Hauptlauf. Pauschal zu Fable-5-Preisen gerechnet war
# die Baseline dieses Umbaus rund 5 $ zu hoch (41 Opus-Anfragen in den
# Sub-Agenten). Eine Warnung allein reicht nicht - eine falsche Zahl mit
# Warnung daneben wird trotzdem abgeschrieben. Der Pflegeaufwand steigt kaum:
# die Datei hatte auch vorher schon eine fest verdrahtete Preistabelle, sie war
# nur einspaltig.
#
# Bewusst NICHT modelliert: der Aufschlag fuer Kontextfenster jenseits 200k
# (z. B. "[1m]"-Varianten). Dafuer fehlt eine belastbare Zahl; die Messung
# liegt bei solchen Laeufen also eher zu niedrig. Steht hier, damit es niemand
# fuer Vollstaendigkeit haelt.
# ---------------------------------------------------------------------------
# Vier EXPLIZITE Saetze je Modell (v2.2, 01.09.2026). Vorher wurden
# cache_read/cache_write GLOBAL aus Claude-Verhaeltnissen abgeleitet
# (input*0,1 / input*1,25) - fuer Fremdanbieter ist das falsch: DeepSeeks
# Cache-Hit-Satz ist ~0,008 * input, nicht 0,1. Die Ratio-Ableitung lebt nur
# noch als markierter Fallback fuer UNBEKANNTE Kennungen (preistabelle()).
# Reihenfolge zaehlt beim Substring-Match: "opus-5" MUSS vor "opus-4-8"
# nichts verdecken - beide Muster sind disjunkt ("opus-5" trifft claude-opus-5,
# "opus-4-8" trifft claude-opus-4-8).
PREISE_JE_MODELL = {
    # Claude (Anthropic-Listenpreise; cache_read = 0,1x, cache_write = 1,25x input)
    "fable-5":   {"input": 10.00, "output": 50.00, "cache_read": 1.000, "cache_write": 12.500},
    "opus-5":    {"input":  5.00, "output": 25.00, "cache_read": 0.500, "cache_write":  6.250},
    "opus-4-8":  {"input":  5.00, "output": 25.00, "cache_read": 0.500, "cache_write":  6.250},
    "sonnet-5":  {"input":  3.00, "output": 15.00, "cache_read": 0.300, "cache_write":  3.750},
    "haiku-4-5": {"input":  1.00, "output":  5.00, "cache_read": 0.100, "cache_write":  1.250},
    # Fremd-Worker (Stand 31.08.2026, benchlm.ai / Anbieter-Preisseiten).
    # kimi-k3: Cache-Saetze sind NICHT belegt - Claude-Ratio als konservative
    # Annahme eingetragen; vor der ersten Kosten-Aussage am Anbieter nachsehen.
    "kimi-k3":   {"input":  3.00, "output": 15.00, "cache_read": 0.300, "cache_write":  3.750},
    "k3":        {"input":  3.00, "output": 15.00, "cache_read": 0.300, "cache_write":  3.750},
    # deepseek-v4-pro: Cache-Hit 0,003625 belegt; DeepSeek berechnet keinen
    # separaten Cache-Write-Aufschlag -> cache_write = input.
    "deepseek-v4": {"input": 0.435, "output": 0.87, "cache_read": 0.003625, "cache_write": 0.435},
}

# Modell, mit dem unbekannte Modell-Kennungen bewertet werden. Fable 5 ist das
# teuerste in der Tabelle - eine unbekannte Kennung faellt damit eher zu hoch
# als zu niedrig aus und wird zusaetzlich in der Ausgabe angezeigt.
STANDARD_MODELL = "fable-5"


def preistabelle(modell):
    """Vier Preise je 1 Mio. Token fuer eine Modell-Kennung aus dem Transkript.

    Rueckgabe: (preise, bekannt). 'bekannt' ist False, wenn die Kennung in
    PREISE_JE_MODELL nicht vorkommt - dann gilt STANDARD_MODELL und die Zahl
    ist eine Annahme, keine Messung. Cache-Saetze kommen seit v2.2 EXPLIZIT
    aus der Tabelle; die alte Claude-Ratio (0,1x / 1,25x input) greift nur
    noch, wenn ein Eintrag die Felder nicht traegt - und das ist dann eine
    markierte Annahme, kein Preis.
    """
    name = (modell or "").lower()
    treffer = None
    for schluessel in PREISE_JE_MODELL:
        if schluessel in name:
            treffer = schluessel
            break
    bekannt = treffer is not None
    basis = PREISE_JE_MODELL[treffer or STANDARD_MODELL]
    return {
        "input": basis["input"],
        "output": basis["output"],
        "cache_read": basis.get("cache_read", basis["input"] * 0.1),
        "cache_write": basis.get("cache_write", basis["input"] * 1.25),
    }, bekannt


# Pauschal-Basis: alles zu Fable-5-Preisen. Aus derselben Tabelle abgeleitet,
# damit die beiden Rahmen nicht auseinanderlaufen koennen.
PREIS_PRO_MIO = preistabelle(STANDARD_MODELL)[0]

# Herkunft der beiden Zahlen, damit sie niemand fuer gleichwertig belegt haelt:
# das KONTEXT-Ziel steht woertlich in SKILL.md S6, das CACHE-READ-Ziel steht
# dort NICHT - es ist aus dem ersten abgeleitet (Rechnung unten). Fest
# verdrahtet, damit der Schritt ohne Merkzettel ausfuehrbar ist - und per
# Schalter ueberschreibbar, damit die Datei nicht still von SKILL.md abdriftet,
# wenn dort die Ziele wandern.
#
# 200k, nicht mehr 120k (Olivers Entscheidung 30.07.2026). Der alte Wert stammte
# aus v1 und widersprach SKILL.md, das seit jeher "mean <= 200k, peak <= 400k"
# nennt: Laeufe, die der Skill in Ordnung fand, meldete diese Datei als
# VERFEHLT. 200k ist ausserdem kein runder Wunsch, sondern genau die Decke der
# ARBEITEN-Zone - das Ziel heisst damit "der Lauf blieb im Mittel in der Zone,
# in der man ueberhaupt etwas anfangen darf". Die Begruendung fuer die Hoehe:
# das Fenster traegt 1 Mio Token, die Qualitaet faellt erst jenseits ~400k
# (Context Rot), 120k war also kein Sparziel, sondern Selbstverstuemmelung.
ZIEL_KONTEXT_MITTEL = 200_000
# MITGEZOGEN, nicht stehengelassen: die beiden Ziele muessen gleich scharf sein,
# sonst wird das eine zum heimlichen Engpass des anderen - dieselbe Fehlerklasse
# wie ein Gate, das eine ueberholte Grenze durchsetzt. Baseline (aus der
# Vorfassung dieses Kommentars uebernommen, nicht neu gemessen): Oe 324k Kontext
# bei 76 Mio Cache-Read. Die alte Rechnung war 120/324 = 37 % -> 76 Mio * 0,37
# = 28 Mio, aufgerundet 30 Mio. Dieselbe Rechnung mit dem neuen Ziel:
# 200/324 = 62 % -> 76 Mio * 0,62 = 47 Mio, aufgerundet 50 Mio.
ZIEL_CACHE_READ = 50_000_000

# Sockel: was eine frische Session allein durch Systemprompt, Skills und
# CLAUDE.md liest, bevor der erste Auftrag kommt. Ein Schnitt an der
# Phasenkante hat gewirkt, wenn die Folgesession wieder hier startet statt
# dort weiterzumachen, wo die vorige aufgehoert hat.
SOCKEL_ERWARTUNG = 80_000
SOCKEL_GRENZE = 150_000

# Die vier usage-Felder, die Claude Code je API-Antwort schreibt.
FELDER = {
    "input": "input_tokens",
    "output": "output_tokens",
    "cache_read": "cache_read_input_tokens",
    "cache_write": "cache_creation_input_tokens",
}

# Ein Kontext-Abfall unter diesen Anteil des Vorgaengers gilt als Reset
# (Compact, /clear oder neuer Lauf).
RESET_SCHWELLE = 0.70


# ---------------------------------------------------------------------------
# Datei finden
# ---------------------------------------------------------------------------

def workspace_id(pfad):
    """Claude Code ersetzt in Projektpfaden jedes Sonderzeichen durch '-'."""
    return "".join(c if c.isalnum() else "-" for c in pfad)


def finde_neueste_session():
    """Neueste .jsonl im Projektordner des aktuellen Arbeitsverzeichnisses."""
    basis = os.path.join(os.path.expanduser("~"), ".claude", "projects")
    kandidat = os.path.join(basis, workspace_id(os.getcwd()))

    if not os.path.isdir(kandidat):
        # Der Laufwerksbuchstabe kommt je nach Aufruf gross oder klein.
        ziel = workspace_id(os.getcwd()).lower()
        treffer = [d for d in os.listdir(basis) if d.lower() == ziel] if os.path.isdir(basis) else []
        if not treffer:
            sys.exit(
                "Kein Projektordner fuer dieses Arbeitsverzeichnis gefunden.\n"
                "  gesucht: %s\n"
                "  Bitte den Pfad zur .jsonl direkt angeben." % kandidat
            )
        kandidat = os.path.join(basis, treffer[0])

    dateien = [
        os.path.join(kandidat, d)
        for d in os.listdir(kandidat)
        if d.endswith(".jsonl") and os.path.isfile(os.path.join(kandidat, d))
    ]
    if not dateien:
        sys.exit("Keine .jsonl in %s" % kandidat)
    return max(dateien, key=os.path.getmtime)


def subagenten_dateien(pfad):
    """Sub-Agenten liegen in <session-id>/subagents/agent-*.jsonl neben der Session."""
    ordner = os.path.join(os.path.splitext(pfad)[0], "subagents")
    if not os.path.isdir(ordner):
        return []
    return sorted(
        os.path.join(ordner, d) for d in os.listdir(ordner) if d.endswith(".jsonl")
    )


# ---------------------------------------------------------------------------
# Kern: eine Datei einlesen
# ---------------------------------------------------------------------------

def sammle(pfad, bis_turn=None, bis_zeit=None):
    """Liest eine .jsonl zeilenweise und fasst sie je API-Anfrage zusammen.

    Zwei Schnitt-Arten, die sich gegenseitig ausschliessen:

    * bis_turn - Schnitt nach N Assistant-Zeilen. Nur fuer die Hauptdatei
      sinnvoll: Zeilennummern der Hauptdatei bedeuten in einer Sub-Agenten-Datei
      nichts.
    * bis_zeit - Schnitt am Zeitstempel. Das ist der EINZIGE Bezugsrahmen, den
      Haupt- und Sub-Agenten-Dateien teilen: "alles, was bis zum Zeitpunkt T
      passiert ist". Damit wird der Hauptdatei-Schnitt auf die Sub-Agenten
      uebertragbar.

    Zwei Fallen, die diese Funktion abfaengt:

    1. Claude Code schreibt EINE API-Antwort als MEHRERE Assistant-Zeilen - eine
       je Inhaltsblock (thinking, text, tool_use). Wer je Zeile summiert, zaehlt
       dieselbe Antwort mehrfach. Zaehlschluessel ist deshalb die requestId.
    2. In Haupt-Sessions steht auf allen Zeilen einer Anfrage dasselbe usage, in
       Sub-Agenten-Dateien dagegen waechst output_tokens von Zeile zu Zeile
       (Streaming-Zwischenstaende). Nur der groesste Wert je Feld ist der
       Endstand - die erste Zeile zu nehmen unterzaehlt den Output massiv.
    """
    je_anfrage = {}          # requestId -> {feld: max}, Reihenfolge = Ablauf
    meta = {}                # requestId -> (zeitstempel, modell, sidechain)
    summe_zeilen = {k: 0 for k in FELDER}   # Gegenprobe: naive Zeilen-Summe
    summe_zeilen_je_modell = {}             # dieselbe Gegenprobe, nach Modell getrennt
    zeilen_gesamt = 0
    zeilen_kaputt = 0
    assistant_zeilen = 0
    zeilen_nach_schnitt = 0   # per bis_zeit weggeschnitten
    zeilen_ohne_zeit = 0      # bei bis_zeit nicht einordenbar
    turn_schnitt_griff = False  # hat --bis-turn tatsaechlich etwas abgeschnitten?

    with open(pfad, "r", encoding="utf-8", errors="replace") as f:
        for zeile in f:
            zeile = zeile.strip()
            if not zeile:
                continue
            zeilen_gesamt += 1
            try:
                satz = json.loads(zeile)
            except Exception:
                zeilen_kaputt += 1
                continue
            if not isinstance(satz, dict) or satz.get("type") != "assistant":
                continue

            nachricht = satz.get("message")
            if not isinstance(nachricht, dict):
                zeilen_kaputt += 1
                continue
            usage = nachricht.get("usage")
            if not isinstance(usage, dict):
                zeilen_kaputt += 1
                continue

            # Zeit-Schnitt vor allem anderen: die Zeile gilt als nicht passiert.
            # Bewusst 'continue' statt 'break' - eine einzelne aus der Reihe
            # gefallene Zeile darf nicht den Rest der Datei abschneiden.
            if bis_zeit is not None:
                ts_zeile = satz.get("timestamp")
                if not ts_zeile:
                    zeilen_ohne_zeit += 1
                    continue
                if ts_zeile > bis_zeit:
                    zeilen_nach_schnitt += 1
                    continue

            assistant_zeilen += 1
            # --bis-turn schneidet hart bei einer Zeile ab. Faellt der Schnitt mitten
            # in eine mehrzeilige Anfrage, wird deren Output leicht unterzaehlt -
            # fuer Momentaufnahmen zum Vergleich hinnehmbar, fuer Messungen nicht.
            if bis_turn is not None and assistant_zeilen > bis_turn:
                assistant_zeilen -= 1
                turn_schnitt_griff = True
                break

            zeilen_modell = nachricht.get("model") or "unbekannt"
            zeilen_ziel = summe_zeilen_je_modell.setdefault(
                zeilen_modell, {k: 0 for k in FELDER})
            werte = {}
            for k, feld in FELDER.items():
                v = usage.get(feld)
                werte[k] = v if isinstance(v, (int, float)) else 0
                summe_zeilen[k] += werte[k]
                zeilen_ziel[k] += werte[k]

            # Fallback-Kette, damit Zeilen ohne requestId (z. B. synthetische
            # Fehlermeldungen) nicht faelschlich zu einer Anfrage verschmelzen.
            schluessel = satz.get("requestId") or nachricht.get("id") or satz.get("uuid")
            if schluessel in je_anfrage:
                alt = je_anfrage[schluessel]
                for k, v in werte.items():
                    if v > alt[k]:
                        alt[k] = v
            else:
                je_anfrage[schluessel] = werte
                meta[schluessel] = (
                    satz.get("timestamp"),
                    nachricht.get("model") or "unbekannt",
                    bool(satz.get("isSidechain")),
                )

    return {
        "je_anfrage": je_anfrage,
        "meta": meta,
        "summe_zeilen": summe_zeilen,
        "summe_zeilen_je_modell": summe_zeilen_je_modell,
        "zeilen_gesamt": zeilen_gesamt,
        "zeilen_kaputt": zeilen_kaputt,
        "assistant_zeilen": assistant_zeilen,
        "zeilen_nach_schnitt": zeilen_nach_schnitt,
        "zeilen_ohne_zeit": zeilen_ohne_zeit,
        "turn_schnitt_griff": turn_schnitt_griff,
    }


def kosten_von(token):
    """Pauschal-Basis: alle Token zum Preis von STANDARD_MODELL."""
    return {k: token[k] / 1_000_000 * PREIS_PRO_MIO[k] for k in FELDER}


def kosten_von_je_modell(token_je_modell):
    """Modellgenaue Basis: jeder Posten zum Preis seines eigenen Modells.

    Rueckgabe: (kosten, unbekannte_modelle). Die zweite Haelfte sagt, welche
    Kennungen nur geschaetzt wurden - ohne sie waere die Summe eine Zahl mit
    verschwiegener Unsicherheit.
    """
    kosten = {k: 0.0 for k in FELDER}
    unbekannt = []
    for modell, token in token_je_modell.items():
        preise, bekannt = preistabelle(modell)
        if not bekannt and modell != "<synthetic>":
            unbekannt.append(modell)
        for k in FELDER:
            kosten[k] += token[k] / 1_000_000 * preise[k]
    return kosten, sorted(unbekannt)


# ---------------------------------------------------------------------------
# Messung zusammensetzen
# ---------------------------------------------------------------------------

def messe(pfad, bis_turn=None, mit_subagenten=True, preise_je_modell=False):
    roh = sammle(pfad, bis_turn)
    je_anfrage, meta = roh["je_anfrage"], roh["meta"]

    summe = {k: 0 for k in FELDER}
    token_je_modell = {}
    kontexte = []
    modelle = {}
    sidechain = 0
    ts_erste = ts_letzte = None

    for rid, werte in je_anfrage.items():
        for k, v in werte.items():
            summe[k] += v
        ts, modell, sc = meta[rid]
        modelle[modell] = modelle.get(modell, 0) + 1
        modell_ziel = token_je_modell.setdefault(modell, {k: 0 for k in FELDER})
        for k, v in werte.items():
            modell_ziel[k] += v
        if sc:
            sidechain += 1
        if ts:
            ts_erste = ts if ts_erste is None or ts < ts_erste else ts_erste
            ts_letzte = ts if ts_letzte is None or ts > ts_letzte else ts_letzte
        # Kontextgroesse = alles, was das Modell bei dieser Anfrage gelesen hat.
        kontexte.append((werte["input"] + werte["cache_read"] + werte["cache_write"], ts))

    anfragen = len(je_anfrage)

    # Beide Basen werden immer gerechnet. Nur so kann der Lauf-Bericht die
    # Differenz zwischen ihnen ausweisen, ohne die Dateien zweimal zu lesen.
    kosten_pauschal = kosten_von(summe)
    kosten_modell, unbekannte_modelle = kosten_von_je_modell(token_je_modell)
    kosten = kosten_modell if preise_je_modell else kosten_pauschal
    kosten_gesamt = sum(kosten.values())
    if preise_je_modell:
        kosten_zeilen = sum(kosten_von_je_modell(roh["summe_zeilen_je_modell"])[0].values())
    else:
        kosten_zeilen = sum(kosten_von(roh["summe_zeilen"]).values())

    # Anfragen ohne usage (API-Fehler) verfaelschen Kurve und Reset-Erkennung.
    echte = [(c, t) for c, t in kontexte if c > 0]
    werte_kontext = [c for c, _ in echte]

    resets = []
    for i in range(1, len(echte)):
        vorher, jetzt = echte[i - 1][0], echte[i][0]
        if jetzt < vorher * RESET_SCHWELLE:
            resets.append({
                "turn": i,
                "vorher": vorher,
                "nachher": jetzt,
                "abfall_prozent": round((1 - jetzt / vorher) * 100, 1),
                "zeitstempel": echte[i][1],
            })

    # Jeder Schluessel traegt seinen Bezugsrahmen im Namen. Ein blosses "token"
    # oder "kosten_usd" waere die gleiche Falle wie die alte Gesamtzahl: ein
    # Skript liest es als Session-Wert und bekommt still nur die Hauptdatei.
    ergebnis = {
        "datei": os.path.abspath(pfad),
        "datei_bytes": os.path.getsize(pfad),
        "zeitraum": {"von": ts_erste, "bis": ts_letzte},
        "turns_hauptdatei": {
            "api_anfragen": anfragen,
            "assistant_zeilen": roh["assistant_zeilen"],
            "sidechain_anfragen": sidechain,
            "zeilen_je_anfrage": round(roh["assistant_zeilen"] / anfragen, 2) if anfragen else 0.0,
        },
        "token_je_zeile_gegenprobe_hauptdatei": roh["summe_zeilen"],
        "kosten_usd_hauptdatei": kosten,
        "kosten_usd_gegenprobe_gesamt_hauptdatei": kosten_zeilen,
        "kosten_usd_je_turn_hauptdatei": kosten_gesamt / anfragen if anfragen else 0.0,
        "residenz_anteil_prozent_hauptdatei": (
            round((kosten["cache_read"] + kosten["cache_write"]) / kosten_gesamt * 100, 1)
            if kosten_gesamt else 0.0
        ),
        "kontext_hauptdatei": {
            "start": werte_kontext[0] if werte_kontext else 0,
            "maximum": max(werte_kontext) if werte_kontext else 0,
            "mittel": round(sum(werte_kontext) / len(werte_kontext)) if werte_kontext else 0,
            "ohne_usage": len(kontexte) - len(echte),
            # Fuer den Lauf-Bericht: 'ende' zeigt, wie hoch die Session
            # aufgelaufen war, als geschnitten wurde; 'summe'/'anzahl' erlauben
            # einen exakten gepoolten Mittelwert ueber mehrere Sessions.
            # Ein Mittel aus Mittelwerten waere bei ungleich langen Sessions falsch.
            "ende": werte_kontext[-1] if werte_kontext else 0,
            "summe": sum(werte_kontext),
            "anzahl": len(werte_kontext),
        },
        "resets_hauptdatei": resets,
        "laeufe_hauptdatei": segmentiere(echte, resets),
        "modelle_hauptdatei": modelle,
        "zeilen_hauptdatei": {"gesamt": roh["zeilen_gesamt"],
                              "uebersprungen": roh["zeilen_kaputt"]},
        "subagenten": None,
    }

    # -----------------------------------------------------------------------
    # Bezugsrahmen. Jede Zahl in dieser Ausgabe gehoert zu genau einem Rahmen:
    # Hauptdatei allein oder Hauptdatei plus Sub-Agenten. Sie duerfen nur
    # addiert werden, wenn beide denselben Schnitt tragen - deshalb wird der
    # Hauptdatei-Schnitt hier in eine Zeitgrenze uebersetzt und weitergereicht.
    # -----------------------------------------------------------------------
    # Massgeblich ist, ob --bis-turn tatsaechlich gegriffen hat - nicht, ob es
    # angegeben wurde. Ein '--bis-turn 999999' auf einer kuerzeren Datei
    # schneidet nichts ab; trotzdem eine Zeitgrenze zu setzen wuerde einen
    # Schnitt behaupten, den es nicht gab, und die Sub-Agenten am Ende der
    # Hauptdatei beschneiden, obwohl die vollstaendig gemessen wurde.
    turn_schnitt_griff = roh["turn_schnitt_griff"]
    schnitt_zeit = ts_letzte if turn_schnitt_griff else None
    schnitt_uebertragbar = (not turn_schnitt_griff) or (ts_letzte is not None)

    vorhandene_subdateien = len(subagenten_dateien(pfad))
    ergebnis["bezugsrahmen"] = {
        "schnitt_bis_turn": bis_turn,
        "schnitt_hat_gegriffen": turn_schnitt_griff,
        "schnitt_bis_zeit": schnitt_zeit,
        "subagenten_dateien_vorhanden": vorhandene_subdateien,
        # Wird nach der Messung auf den tatsaechlichen Stand gesetzt - ob
        # gemessen WERDEN SOLLTE und ob gemessen WURDE ist nicht dasselbe.
        "subagenten_gemessen": bool(mit_subagenten and vorhandene_subdateien),
        "schnitt_auf_subagenten_uebertragbar": schnitt_uebertragbar,
        # Sidechain-Anfragen IN der Hauptdatei sind eine andere Population als
        # die separaten Sub-Agenten-Dateien. Treten beide auf, kann die Summe
        # denselben Aufwand zweimal enthalten - dann keine stille Gesamtzahl.
        "doppelzaehlung_moeglich": bool(sidechain and vorhandene_subdateien),
    }

    if mit_subagenten and vorhandene_subdateien:
        if not schnitt_uebertragbar:
            # Hauptdatei geschnitten, aber ohne Zeitstempel keine gemeinsame
            # Grenze. Lieber keine Zahl als eine falsche.
            ergebnis["subagenten"] = None
        else:
            ergebnis["subagenten"] = messe_subagenten(
                pfad, bis_zeit=schnitt_zeit, preise_je_modell=preise_je_modell)

    # Erst jetzt steht fest, ob wirklich gemessen wurde: bei nicht
    # uebertragbarem Schnitt bleibt 'subagenten' None, obwohl Dateien da sind
    # und --ohne-subagenten nicht gesetzt war.
    ergebnis["bezugsrahmen"]["subagenten_gemessen"] = ergebnis["subagenten"] is not None

    sub = ergebnis["subagenten"]
    sub_kosten = sub["kosten_usd_gesamt"] if sub else 0.0

    # Die Teilmenge behaelt einen Namen, der sie als Teilmenge ausweist.
    ergebnis["kosten_usd_gesamt_hauptdatei"] = kosten_gesamt
    ergebnis["token_hauptdatei"] = summe
    ergebnis["token_je_modell_hauptdatei"] = token_je_modell
    ergebnis["preisbasis"] = "je_modell" if preise_je_modell else "fable_pauschal"
    ergebnis["unbekannte_modelle_hauptdatei"] = unbekannte_modelle
    # Beide Basen offen ausweisen: eine Zahl, deren Rahmen man nicht sieht,
    # ist genau die Falle, gegen die der Rest dieser Datei gebaut ist.
    ergebnis["kosten_usd_gesamt_hauptdatei_pauschal"] = sum(kosten_pauschal.values())
    ergebnis["kosten_usd_gesamt_hauptdatei_je_modell"] = sum(kosten_modell.values())

    # kosten_usd_gesamt ist die Zahl, die ein Mensch oder ein Skript ablesen
    # wird. Sie ist deshalb IMMER die inklusive Zahl - oder None, wenn sie
    # nicht ehrlich gebildet werden kann. Ein stiller Teilwert an dieser
    # Stelle wuerde eine blosse Verlagerung in Sub-Agenten wie eine Ersparnis
    # aussehen lassen.
    unvollstaendig = None
    if ergebnis["bezugsrahmen"]["doppelzaehlung_moeglich"]:
        unvollstaendig = ("Hauptdatei enthaelt Sidechain-Anfragen UND es gibt eigene "
                          "Sub-Agenten-Dateien - die Summe koennte denselben Aufwand "
                          "doppelt zaehlen.")
    elif vorhandene_subdateien and not mit_subagenten:
        unvollstaendig = ("%d Sub-Agenten-Datei(en) wurden per --ohne-subagenten "
                          "uebersprungen." % vorhandene_subdateien)
    elif vorhandene_subdateien and not schnitt_uebertragbar:
        unvollstaendig = ("Hauptdatei ist per --bis-turn geschnitten, hat aber keinen "
                          "Zeitstempel - der Schnitt laesst sich nicht auf die "
                          "Sub-Agenten uebertragen.")

    ergebnis["gesamt_unvollstaendig_grund"] = unvollstaendig
    ergebnis["kosten_usd_gesamt"] = None if unvollstaendig else kosten_gesamt + sub_kosten
    ergebnis["token_gesamt"] = (
        None if unvollstaendig
        else {k: summe[k] + (sub["token"][k] if sub else 0) for k in FELDER}
    )
    return ergebnis


def messe_subagenten(pfad, bis_zeit=None, preise_je_modell=False):
    """Sub-Agenten laufen in eigenen Dateien - ihre Kosten fehlen sonst komplett.

    bis_zeit traegt den Schnitt der Hauptdatei hierher. Ohne ihn wuerde ein
    geschnittener Hauptlauf mit dem VOLLSTAENDIGEN Sub-Agenten-Aufwand addiert.

    Hier sitzt der eigentliche Grund fuer die Preistabelle je Modell: Explorer
    und Pruefer laufen planmaessig auf kleineren Modellen als der Hauptlauf.
    """
    dateien = subagenten_dateien(pfad)
    if not dateien:
        return None
    summe = {k: 0 for k in FELDER}
    token_je_modell = {}
    anfragen = 0
    modelle = {}
    weggeschnitten = 0
    ohne_zeit = 0
    for d in dateien:
        roh = sammle(d, bis_zeit=bis_zeit)
        weggeschnitten += roh["zeilen_nach_schnitt"]
        ohne_zeit += roh["zeilen_ohne_zeit"]
        for rid, werte in roh["je_anfrage"].items():
            anfragen += 1
            for k, v in werte.items():
                summe[k] += v
            modell = roh["meta"][rid][1]
            modelle[modell] = modelle.get(modell, 0) + 1
            ziel = token_je_modell.setdefault(modell, {k: 0 for k in FELDER})
            for k, v in werte.items():
                ziel[k] += v
    kosten_pauschal = kosten_von(summe)
    kosten_modell, unbekannt = kosten_von_je_modell(token_je_modell)
    kosten = kosten_modell if preise_je_modell else kosten_pauschal
    return {
        "dateien": len(dateien),
        "api_anfragen": anfragen,
        "token": summe,
        "kosten_usd": kosten,
        "kosten_usd_gesamt": sum(kosten.values()),
        "modelle": modelle,
        "schnitt_bis_zeit": bis_zeit,
        "zeilen_nach_schnitt": weggeschnitten,
        "zeilen_ohne_zeitstempel": ohne_zeit,
        "token_je_modell": token_je_modell,
        "preisbasis": "je_modell" if preise_je_modell else "fable_pauschal",
        "kosten_usd_gesamt_pauschal": sum(kosten_pauschal.values()),
        "kosten_usd_gesamt_je_modell": sum(kosten_modell.values()),
        "unbekannte_modelle": unbekannt,
    }


def segmentiere(echte, resets):
    """Teilt die Session an den Resets in Laufabschnitte.

    Ein Reset ist der verlaesslichste Lauf-Trenner: eine lange Pause allein
    trennt nicht, weil im selben Lauf mit Unterbrechungen weitergearbeitet wird.
    """
    if not echte:
        return []
    grenzen = [0] + [r["turn"] for r in resets] + [len(echte)]
    laeufe = []
    for i in range(len(grenzen) - 1):
        a, b = grenzen[i], grenzen[i + 1]
        teil = [c for c, _ in echte[a:b]]
        if not teil:
            continue
        laeufe.append({
            "nummer": len(laeufe) + 1,
            "turns": len(teil),
            "start_zeit": echte[a][1],
            "kontext_start": teil[0],
            "kontext_max": max(teil),
            "kontext_mittel": round(sum(teil) / len(teil)),
        })
    return laeufe


# ---------------------------------------------------------------------------
# Ein Lauf ueber mehrere Sessions
# ---------------------------------------------------------------------------

def loese_pfade_auf(muster_liste):
    """Macht aus Pfaden und Glob-Mustern eine geordnete, doppelfreie Dateiliste.

    Glob wird hier aufgeloest und nicht der Konsole ueberlassen: unter Windows
    expandiert weder cmd noch PowerShell fuer das Programm, das Muster kaeme
    woertlich an.
    """
    pfade = []
    gesehen = set()
    for muster in muster_liste:
        muster = os.path.expanduser(muster)
        if any(z in muster for z in "*?["):
            treffer = sorted(globmodul.glob(muster))
            if not treffer:
                sys.exit("Kein Treffer fuer Muster: %s" % muster)
        else:
            treffer = [muster]
        for t in treffer:
            if not os.path.isfile(t):
                sys.exit("Datei nicht gefunden: %s" % t)
            voll = os.path.abspath(t)
            # Dieselbe Session zweimal wuerde die Summe still verdoppeln.
            if voll in gesehen:
                sys.exit("Dieselbe Session ist mehrfach angegeben: %s" % voll)
            gesehen.add(voll)
            pfade.append(voll)
    if not pfade:
        sys.exit("--lauf braucht mindestens eine Datei.")
    return pfade


def messe_lauf(pfade, preise_je_modell=True, ziel_kontext=ZIEL_KONTEXT_MITTEL,
               ziel_cache_read=ZIEL_CACHE_READ):
    """Fasst mehrere Sessions zu EINEM Lauf zusammen.

    Seit dem route-Umbau wird an jeder Phasenkante geschnitten - ein Lauf liegt
    also in mehreren Dateien. Sechs Einzelberichte sind keine Gesamtzahl; ohne
    diese Funktion ist der Kostenanspruch des Skills unbelegbar.

    Die Kontext-Kurve ueber alle Sessions ist der eigentliche Zweck: an ihr
    liest man ab, ob die Schnitte gewirkt haben. Startet jede Session wieder
    nahe am Sockel, hat der Schnitt gegriffen; setzt sie dort fort, wo die
    vorige aufgehoert hat, wurde nur die Datei gewechselt, nicht der Kontext.
    """
    sessions = [
        messe(p, None, mit_subagenten=True, preise_je_modell=preise_je_modell)
        for p in pfade
    ]
    # Chronologisch nach erstem Zeitstempel - die Reihenfolge auf der
    # Kommandozeile sagt nichts ueber den Ablauf. Sessions ohne Zeitstempel
    # hinten anstellen, statt sie stillschweigend nach vorn zu sortieren.
    sessions.sort(key=lambda s: (s["zeitraum"]["von"] is None, s["zeitraum"]["von"] or ""))

    tok_haupt = {k: sum(s["token_hauptdatei"][k] for s in sessions) for k in FELDER}
    tok_sub = {
        k: sum((s["subagenten"]["token"][k] if s["subagenten"] else 0) for s in sessions)
        for k in FELDER
    }
    tok_gesamt = {k: tok_haupt[k] + tok_sub[k] for k in FELDER}

    # Gepoolter Mittelwert ueber alle Anfragen aller Hauptdateien. Bewusst
    # nicht der Mittelwert der Session-Mittelwerte: bei ungleich langen
    # Sessions gewichtet der die kurzen genauso stark wie die langen.
    ctx_summe = sum(s["kontext_hauptdatei"]["summe"] for s in sessions)
    ctx_anzahl = sum(s["kontext_hauptdatei"]["anzahl"] for s in sessions)
    ctx_mittel = round(ctx_summe / ctx_anzahl) if ctx_anzahl else 0
    ctx_spitze = max([s["kontext_hauptdatei"]["maximum"] for s in sessions] or [0])

    je_session = []
    vorheriges_ende = None
    for i, s in enumerate(sessions):
        k = s["kontext_hauptdatei"]
        sub = s["subagenten"]
        schnitt = None
        if vorheriges_ende is not None:
            # Der Beweis fuer einen gelungenen Schnitt: Start dieser Session
            # gegen Endstand der vorigen. Beide Zahlen stehen nebeneinander,
            # damit das Urteil nachrechenbar ist statt geglaubt werden zu muessen.
            schnitt = {
                "vorsession_ende": vorheriges_ende,
                "start": k["start"],
                "differenz": vorheriges_ende - k["start"],
                "startet_am_sockel": k["start"] <= SOCKEL_GRENZE,
                "sockel_grenze": SOCKEL_GRENZE,
            }
        je_session.append({
            "nummer": i + 1,
            "datei": os.path.basename(s["datei"]),
            "pfad": s["datei"],
            "zeitraum": s["zeitraum"],
            "api_anfragen_hauptdatei": s["turns_hauptdatei"]["api_anfragen"],
            "api_anfragen_subagenten": sub["api_anfragen"] if sub else 0,
            "kontext_start": k["start"],
            "kontext_maximum": k["maximum"],
            "kontext_mittel": k["mittel"],
            "kontext_ende": k["ende"],
            # Ein Reset INNERHALB einer Session ist ein Compact, kein
            # Phasenschnitt - also ein Hinweis, dass zu spaet geschnitten wurde.
            "resets_in_session": len(s["resets_hauptdatei"]),
            "kosten_usd_hauptdatei": s["kosten_usd_gesamt_hauptdatei"],
            "kosten_usd_subagenten": sub["kosten_usd_gesamt"] if sub else 0.0,
            "kosten_usd_gesamt": s["kosten_usd_gesamt"],
            "schnitt_gegen_vorsession": schnitt,
        })
        vorheriges_ende = k["ende"]

    # Eine einzige unvollstaendige Session macht die Lauf-Summe unvollstaendig.
    # Sie hier trotzdem zu bilden hiesse, den Fehler durch Addition zu verstecken.
    luecken = [
        {"datei": os.path.basename(s["datei"]), "grund": s["gesamt_unvollstaendig_grund"]}
        for s in sessions if s["kosten_usd_gesamt"] is None
    ]
    kosten_haupt = sum(s["kosten_usd_gesamt_hauptdatei"] for s in sessions)
    kosten_sub = sum(
        (s["subagenten"]["kosten_usd_gesamt"] if s["subagenten"] else 0.0)
        for s in sessions
    )

    # Was die jeweils andere Preisbasis ergaebe - damit die Differenz zwischen
    # den Basen eine gemessene Zahl ist und keine Behauptung.
    alt_haupt = sum(
        s["kosten_usd_gesamt_hauptdatei_pauschal"] if preise_je_modell
        else s["kosten_usd_gesamt_hauptdatei_je_modell"] for s in sessions
    )
    alt_sub = sum(
        ((s["subagenten"]["kosten_usd_gesamt_pauschal"] if preise_je_modell
          else s["subagenten"]["kosten_usd_gesamt_je_modell"]) if s["subagenten"] else 0.0)
        for s in sessions
    )

    modelle = {}
    unbekannt = set()
    for s in sessions:
        for m, n in s["modelle_hauptdatei"].items():
            modelle[m] = modelle.get(m, 0) + n
        unbekannt.update(s["unbekannte_modelle_hauptdatei"])
        if s["subagenten"]:
            for m, n in s["subagenten"]["modelle"].items():
                modelle[m] = modelle.get(m, 0) + n
            unbekannt.update(s["subagenten"]["unbekannte_modelle"])

    anfragen_haupt = sum(x["api_anfragen_hauptdatei"] for x in je_session)
    anfragen_sub = sum(x["api_anfragen_subagenten"] for x in je_session)

    # Ziele aus SKILL.md S6. Immer mit gemessenem Wert UND Sollwert -
    # ein blosses "erreicht" ist kein Nachweis, sondern eine Behauptung.
    ziele = {
        "kontext_mittel_hauptdateien": {
            "gemessen": ctx_mittel,
            "soll_hoechstens": ziel_kontext,
            "erreicht": ctx_mittel <= ziel_kontext,
        },
        "cache_read_gesamt": {
            "gemessen": tok_gesamt["cache_read"],
            "soll_hoechstens": ziel_cache_read,
            "erreicht": tok_gesamt["cache_read"] <= ziel_cache_read,
        },
    }

    return {
        "sessions_gemessen": len(sessions),
        "preisbasis": "je_modell" if preise_je_modell else "fable_pauschal",
        "zeitraum_lauf": {
            "von": sessions[0]["zeitraum"]["von"] if sessions else None,
            "bis": max([s["zeitraum"]["bis"] or "" for s in sessions] or [""]) or None,
        },
        "turns_lauf": {
            "api_anfragen_hauptdateien": anfragen_haupt,
            "api_anfragen_subagenten": anfragen_sub,
            "api_anfragen_gesamt": anfragen_haupt + anfragen_sub,
        },
        "token_hauptdateien": tok_haupt,
        "token_subagenten": tok_sub,
        "token_gesamt": tok_gesamt,
        "kosten_usd_gesamt_hauptdateien": kosten_haupt,
        "kosten_usd_gesamt_subagenten": kosten_sub,
        "kosten_usd_gesamt": None if luecken else kosten_haupt + kosten_sub,
        "kosten_usd_gesamt_andere_preisbasis": None if luecken else alt_haupt + alt_sub,
        "gesamt_unvollstaendig": luecken,
        "kontext_lauf": {
            "mittel_hauptdateien": ctx_mittel,
            "spitze_hauptdateien": ctx_spitze,
            "anfragen_in_kurve": ctx_anzahl,
            "sockel_erwartung": SOCKEL_ERWARTUNG,
        },
        "je_session": je_session,
        "ziele": ziele,
        "modelle_lauf": modelle,
        "unbekannte_modelle": sorted(unbekannt),
    }


# ---------------------------------------------------------------------------
# Ausgabe
# ---------------------------------------------------------------------------

def z(n):
    """Tausenderpunkte, deutsche Schreibweise."""
    return "{:,}".format(int(n)).replace(",", ".")


def geld(x):
    return "{:,.2f}".format(x).replace(",", "#").replace(".", ",").replace("#", ".")


def kurz_zeit(ts):
    if not ts:
        return "?"
    try:
        return datetime.fromisoformat(ts.replace("Z", "+00:00")).strftime("%d.%m. %H:%M")
    except Exception:
        return ts


def drucke(r):
    b = "=" * 74
    print(b)
    print("MESSUNG  " + os.path.basename(r["datei"]))
    print(b)
    print("Datei      %s (%s MB)" % (r["datei"], round(r["datei_bytes"] / 1048576, 1)))
    print("Zeitraum   %s  bis  %s" % (kurz_zeit(r["zeitraum"]["von"]), kurz_zeit(r["zeitraum"]["bis"])))

    t = r["turns_hauptdatei"]
    print("\n-- TURNS (nur Hauptdatei) --")
    print("  API-Anfragen (echte Turns)     %s" % z(t["api_anfragen"]))
    print("  Assistant-Zeilen (Bloecke)     %s   (%s Zeilen je Anfrage)"
          % (z(t["assistant_zeilen"]), str(t["zeilen_je_anfrage"]).replace(".", ",")))
    if t["sidechain_anfragen"]:
        # Nicht mit den separaten Sub-Agenten-Dateien verwechseln - andere Population.
        print("  davon Sidechain-Anfragen       %s   (in dieser Datei, NICHT die"
              " Sub-Agenten-Dateien)" % z(t["sidechain_anfragen"]))

    tk, ko = r["token_hauptdatei"], r["kosten_usd_hauptdatei"]
    print("\n-- TOKEN UND KOSTEN NUR HAUPTDATEI (je API-Anfrage gezaehlt) --")
    if r.get("preisbasis") == "je_modell":
        # Nur im Nicht-Standardfall zusaetzlich ausgeben: die Voreinstellung
        # muss Zeichen fuer Zeichen bleiben, wie sie war - an ihr haengen die
        # Baseline-Zahlen dieses Umbaus.
        print("  Preisbasis: je Modell (jede Anfrage zum Preis ihres Modells)")
    print("  %-14s %16s   %6s $/Mio   %12s $" % ("Posten", "Token", "Preis", "Kosten"))
    # "gemischt" richtet sich nach den tatsaechlichen Preisen, nicht nach der
    # Zahl der Modell-Kennungen: mehrere Kennungen zum selben Preis (z. B.
    # "<synthetic>" neben Fable) sind kein gemischter Posten.
    gemischt = r.get("preisbasis") == "je_modell" and len(
        {preistabelle(m)[0]["input"] for m in r.get("token_je_modell_hauptdatei", {})}) > 1
    for schluessel, name in (("output", "Output"), ("cache_read", "Cache-Read"),
                             ("cache_write", "Cache-Write"), ("input", "Roh-Input")):
        # Bei gemischten Modellen gibt es keinen EINEN Preis je Posten - dann
        # lieber "gemischt" als eine Zahl, die nur fuer einen Teil gilt.
        preis = "gemis." if gemischt else geld(PREIS_PRO_MIO[schluessel])
        print("  %-14s %16s   %6s        %12s $"
              % (name, z(tk[schluessel]), preis, geld(ko[schluessel])))
    print("  %-14s %16s   %6s        %12s $"
          % ("TEILSUMME", "", "", geld(r["kosten_usd_gesamt_hauptdatei"])))
    print("  (Teilmenge - die Gesamtzahl steht unten unter GESAMT)")
    print("\n  Kontext-Residenz (Cache-Read + Cache-Write): %s %% der Kosten (Hauptdatei)"
          % str(r["residenz_anteil_prozent_hauptdatei"]).replace(".", ","))
    print("  Kosten je Turn im Mittel (Hauptdatei): %s $" % geld(r["kosten_usd_je_turn_hauptdatei"]))

    k = r["kontext_hauptdatei"]
    print("\n-- KONTEXT-KURVE (nur Hauptdatei) --")
    print("  Start (Turn 0)   %s Token" % z(k["start"]))
    print("  Maximum          %s Token" % z(k["maximum"]))
    print("  Mittelwert       %s Token" % z(k["mittel"]))
    if k["ohne_usage"]:
        print("  (%s Anfrage(n) ohne usage aus der Kurve genommen - API-Fehler)" % k["ohne_usage"])
    if r["resets_hauptdatei"]:
        print("  Resets (Abfall > %d %%):" % round((1 - RESET_SCHWELLE) * 100))
        for x in r["resets_hauptdatei"]:
            print("    Turn %s: %s -> %s  (%s %% weniger, %s)"
                  % (x["turn"], z(x["vorher"]), z(x["nachher"]),
                     str(x["abfall_prozent"]).replace(".", ","), kurz_zeit(x["zeitstempel"])))
    else:
        print("  Resets: keine")

    if len(r["laeufe_hauptdatei"]) > 1:
        print("\n-- MEHRERE LAEUFE IN DER HAUPTDATEI (%d Abschnitte, an den Resets getrennt) --" % len(r["laeufe_hauptdatei"]))
        for l in r["laeufe_hauptdatei"]:
            print("  Lauf %d: %s Turns, ab %s, Kontext %s -> max %s, Mittel %s"
                  % (l["nummer"], z(l["turns"]), kurz_zeit(l["start_zeit"]),
                     z(l["kontext_start"]), z(l["kontext_max"]), z(l["kontext_mittel"])))

    s = r.get("subagenten")
    br = r["bezugsrahmen"]

    print("\n-- SUB-AGENTEN (eigene Dateien, in der Teilsumme oben NICHT enthalten) --")
    if s:
        print("  %s Datei(en), %s API-Anfragen, %s $"
              % (z(s["dateien"]), z(s["api_anfragen"]), geld(s["kosten_usd_gesamt"])))
        if s["schnitt_bis_zeit"]:
            print("  Gleicher Schnitt wie die Hauptdatei: bis %s"
                  % kurz_zeit(s["schnitt_bis_zeit"]))
            print("  %s Assistant-Zeile(n) lagen nach dem Schnitt und sind weggelassen."
                  % z(s["zeilen_nach_schnitt"]))
            if s["zeilen_ohne_zeitstempel"]:
                print("  ACHTUNG: %s Zeile(n) ohne Zeitstempel - zeitlich nicht"
                      " einzuordnen, weggelassen." % z(s["zeilen_ohne_zeitstempel"]))
    elif br["subagenten_dateien_vorhanden"]:
        print("  %s Datei(en) vorhanden, aber NICHT gemessen."
              % z(br["subagenten_dateien_vorhanden"]))
    else:
        print("  keine")

    print("\n-- GESAMT --")
    print("  Hauptdatei (Teilmenge)          %14s $"
          % geld(r["kosten_usd_gesamt_hauptdatei"]))
    if s:
        print("  Sub-Agenten (Teilmenge)         %14s $" % geld(s["kosten_usd_gesamt"]))
    elif br["subagenten_dateien_vorhanden"]:
        # Nicht "0,00" schreiben - ungemessen ist nicht null.
        print("  Sub-Agenten                     %14s" % "nicht gemessen")
    else:
        print("  Sub-Agenten                     %14s" % "keine vorhanden")
    if r["kosten_usd_gesamt"] is None:
        print("  GESAMT                          %14s" % "nicht bildbar")
        print("  Grund: %s" % r["gesamt_unvollstaendig_grund"])
        print("  Diese Messung taugt NICHT fuer einen Vorher/Nachher-Vergleich:")
        print("  verlagerte Arbeit wuerde als Ersparnis erscheinen.")
    else:
        print("  GESAMT (Hauptlauf + Sub-Agenten) %13s $" % geld(r["kosten_usd_gesamt"]))
        print("  ^ diese Zahl vergleichen, nicht die Teilmengen.")

    # Beide Zahlen hier sind bewusst NUR Hauptdatei - eine Gegenprobe gegen die
    # inklusive Gesamtzahl waere ein Vergleich zweier verschiedener Rahmen.
    print("\n-- GEGENPROBE: Zaehlweise je Assistant-Zeile (nur Hauptdatei) --")
    print("  Dieselbe API-Antwort steht als mehrere Zeilen in der Datei. Zeilenweises")
    print("  Summieren zaehlt sie mehrfach und ergibt zu hohe Werte:")
    g = r["token_je_zeile_gegenprobe_hauptdatei"]
    haupt = r["kosten_usd_gesamt_hauptdatei"]
    print("    Output %s | Cache-Read %s | Cache-Write %s | Input %s"
          % (z(g["output"]), z(g["cache_read"]), z(g["cache_write"]), z(g["input"])))
    print("    ergaebe %s $ statt %s $ (Faktor %s)"
          % (geld(r["kosten_usd_gegenprobe_gesamt_hauptdatei"]), geld(haupt),
             str(round(r["kosten_usd_gegenprobe_gesamt_hauptdatei"] / haupt, 2)).replace(".", ",")
             if haupt else "?"))

    # Modelle aus BEIDEN Rahmen pruefen - ein fremdes Modell im Sub-Agenten
    # verfaelscht die Gesamtzahl genauso wie eines im Hauptlauf.
    alle_modelle = dict(r["modelle_hauptdatei"])
    if s:
        for m, n in s.get("modelle", {}).items():
            alle_modelle[m] = alle_modelle.get(m, 0) + n
    fremd = [m for m in alle_modelle if "fable" not in m.lower() and m != "<synthetic>"]
    if fremd and r.get("preisbasis") == "je_modell":
        print("\n  Hinweis: Nicht-Fable-Modelle in der Session (%s) - sie sind"
              % ", ".join(fremd))
        print("  mit ihren eigenen Preisen gerechnet (Preisbasis je Modell).")
        if r.get("unbekannte_modelle_hauptdatei"):
            print("  ACHTUNG: unbekannte Modell-Kennung(en) %s - mit %s-Preisen"
                  % (", ".join(r["unbekannte_modelle_hauptdatei"]), STANDARD_MODELL))
            print("  geschaetzt, nicht gemessen.")
    elif fremd:
        # Wortlaut unveraendert: an dieser Ausgabe haengen die Baseline-Zahlen
        # des Umbaus, sie muss Zeichen fuer Zeichen vergleichbar bleiben. Der
        # Ausweg steht in --help und im JSON (kosten_usd_gesamt_*_je_modell).
        print("\n  ACHTUNG: Nicht-Fable-Modelle in der Session (%s) - die Preise oben"
              % ", ".join(fremd))
        print("  gelten nur fuer Fable 5, fuer diese Turns sind die Kosten falsch.")

    zl = r["zeilen_hauptdatei"]
    print("\nZeilen gelesen (Hauptdatei): %s, uebersprungen (kaputt/unvollstaendig): %s"
          % (z(zl["gesamt"]), z(zl["uebersprungen"])))
    print(b)


def drucke_lauf(r):
    """Bericht ueber einen Lauf, der sich ueber mehrere Sessions verteilt."""
    b = "=" * 74
    print(b)
    print("MESSUNG LAUF  %d Session(s)" % r["sessions_gemessen"])
    print(b)
    print("Zeitraum   %s  bis  %s"
          % (kurz_zeit(r["zeitraum_lauf"]["von"]), kurz_zeit(r["zeitraum_lauf"]["bis"])))
    print("Preisbasis %s" % ("je Modell (jede Anfrage zum Preis ihres Modells)"
                             if r["preisbasis"] == "je_modell"
                             else "pauschal Fable 5 (alle Anfragen zu Fable-5-Preisen)"))

    print("\n-- SESSIONS DES LAUFS (chronologisch) --")
    print("  %-3s %-14s %-13s %7s %11s %11s %11s"
          % ("Nr", "Datei", "Beginn", "Turns", "Ktx-Start", "Ktx-Max", "Kosten $"))
    for s in r["je_session"]:
        print("  %-3d %-14s %-13s %7s %11s %11s %11s"
              % (s["nummer"], s["datei"][:14], kurz_zeit(s["zeitraum"]["von"]),
                 z(s["api_anfragen_hauptdatei"]), z(s["kontext_start"]),
                 z(s["kontext_maximum"]),
                 geld(s["kosten_usd_gesamt"]) if s["kosten_usd_gesamt"] is not None else "n/a"))
    print("  (Turns = Hauptdatei; Sub-Agenten stehen in der Zeile darunter)")
    for s in r["je_session"]:
        if s["api_anfragen_subagenten"]:
            print("    Nr %d: zusaetzlich %s Sub-Agenten-Anfrage(n) (%s $)"
                  % (s["nummer"], z(s["api_anfragen_subagenten"]),
                     geld(s["kosten_usd_subagenten"])))

    print("\n-- TURNS DES LAUFS --")
    t = r["turns_lauf"]
    print("  Hauptdateien                   %s" % z(t["api_anfragen_hauptdateien"]))
    print("  Sub-Agenten                    %s" % z(t["api_anfragen_subagenten"]))
    print("  GESAMT                         %s" % z(t["api_anfragen_gesamt"]))

    print("\n-- TOKEN DES LAUFS (Hauptdateien + Sub-Agenten) --")
    print("  %-14s %16s %16s %16s"
          % ("Posten", "Hauptdateien", "Sub-Agenten", "GESAMT"))
    for schluessel, name in (("output", "Output"), ("cache_read", "Cache-Read"),
                             ("cache_write", "Cache-Write"), ("input", "Roh-Input")):
        print("  %-14s %16s %16s %16s"
              % (name, z(r["token_hauptdateien"][schluessel]),
                 z(r["token_subagenten"][schluessel]), z(r["token_gesamt"][schluessel])))

    print("\n-- KONTEXT-KURVE UEBER DEN LAUF (nur Hauptdateien) --")
    k = r["kontext_lauf"]
    print("  Mittel ueber alle %s Anfragen   %s Token"
          % (z(k["anfragen_in_kurve"]), z(k["mittel_hauptdateien"])))
    print("  Spitze im ganzen Lauf          %s Token" % z(k["spitze_hauptdateien"]))
    print("  Sockel einer frischen Session  %s Token (Erwartungswert)"
          % z(k["sockel_erwartung"]))
    print("\n  Je Session - Start, Spitze, Mittel:")
    for s in r["je_session"]:
        print("    Nr %d  Start %s  Spitze %s  Mittel %s  Ende %s"
              % (s["nummer"], z(s["kontext_start"]), z(s["kontext_maximum"]),
                 z(s["kontext_mittel"]), z(s["kontext_ende"])))
        if s["resets_in_session"]:
            # Ein Reset in der Session heisst: es wurde compacted statt geschnitten.
            print("           %d Reset(s) INNERHALB der Session - dort wurde"
                  " compacted, nicht an der Phasenkante geschnitten."
                  % s["resets_in_session"])

    print("\n-- HABEN DIE PHASENSCHNITTE GEWIRKT? --")
    nachfolger = [s for s in r["je_session"] if s["schnitt_gegen_vorsession"]]
    if not nachfolger:
        print("  Nur eine Session - kein Schnitt zu pruefen.")
    else:
        for s in nachfolger:
            sc = s["schnitt_gegen_vorsession"]
            urteil = "am Sockel" if sc["startet_am_sockel"] else "NICHT am Sockel"
            print("  Nr %d startet bei %s Token, Vorsession endete bei %s -> %s"
                  % (s["nummer"], z(sc["start"]), z(sc["vorsession_ende"]), urteil))
        gut = sum(1 for s in nachfolger if s["schnitt_gegen_vorsession"]["startet_am_sockel"])
        print("  %d von %d Folgesessions starten unter %s Token."
              % (gut, len(nachfolger), z(SOCKEL_GRENZE)))
        print("  Ein gelungener Schnitt startet nahe am Sockel; wer dort weitermacht,")
        print("  wo die Vorsession aufhoerte, hat nur die Datei gewechselt.")

    print("\n-- ZIELE (SKILL.md S6) --")
    for name, beschriftung, formatierer in (
            ("kontext_mittel_hauptdateien", "Kontext-Mittel", z),
            ("cache_read_gesamt", "Cache-Read gesamt", z)):
        zl = r["ziele"][name]
        # Immer gemessener Wert UND Sollwert - "erreicht" allein waere eine
        # Behauptung, die man nicht nachrechnen kann.
        print("  %-18s gemessen %14s   Soll hoechstens %14s   %s"
              % (beschriftung, formatierer(zl["gemessen"]),
                 formatierer(zl["soll_hoechstens"]),
                 "ERREICHT" if zl["erreicht"] else "VERFEHLT"))

    print("\n-- GESAMT --")
    print("  Hauptdateien (Teilmenge)        %14s $"
          % geld(r["kosten_usd_gesamt_hauptdateien"]))
    print("  Sub-Agenten (Teilmenge)         %14s $"
          % geld(r["kosten_usd_gesamt_subagenten"]))
    if r["kosten_usd_gesamt"] is None:
        print("  GESAMT                          %14s" % "nicht bildbar")
        for l in r["gesamt_unvollstaendig"]:
            print("  %s: %s" % (l["datei"], l["grund"]))
        print("  Diese Messung taugt NICHT fuer einen Vorher/Nachher-Vergleich.")
    else:
        print("  GESAMT (alle Sessions + Sub-Agenten) %9s $" % geld(r["kosten_usd_gesamt"]))
        print("  ^ diese Zahl vergleichen, nicht die Teilmengen.")
        andere = "pauschal Fable 5" if r["preisbasis"] == "je_modell" else "je Modell"
        alt = r["kosten_usd_gesamt_andere_preisbasis"]
        print("  Zum Vergleich, Basis %s: %s $ (Differenz %s $)"
              % (andere, geld(alt), geld(abs(alt - r["kosten_usd_gesamt"]))))

    fremd = [m for m in r["modelle_lauf"] if "fable" not in m.lower() and m != "<synthetic>"]
    if fremd:
        print("\n  Modelle im Lauf: %s"
              % ", ".join("%s (%s)" % (m, z(n)) for m, n in sorted(r["modelle_lauf"].items())))
    if r["unbekannte_modelle"]:
        print("  ACHTUNG: unbekannte Modell-Kennung(en) %s - mit %s-Preisen"
              % (", ".join(r["unbekannte_modelle"]), STANDARD_MODELL))
        print("  geschaetzt, nicht gemessen. Preistabelle ergaenzen.")
    print(b)


def main():
    p = argparse.ArgumentParser(
        description="Misst Token-Verbrauch und Kosten einer Claude-Code-Session "
                    "oder eines ganzen route-Laufs ueber mehrere Sessions.")
    p.add_argument("session", nargs="?", help="Pfad zur session.jsonl (ohne Angabe: neueste)")
    p.add_argument("--json", action="store_true", dest="als_json",
                   help="maschinenlesbare Ausgabe fuer Vorher/Nachher-Vergleiche")
    p.add_argument("--bis-turn", type=int, default=None, metavar="N",
                   help="nur die ersten N Assistant-Zeilen der Hauptdatei messen; "
                        "die Sub-Agenten werden am selben Zeitpunkt mitgeschnitten")
    p.add_argument("--ohne-subagenten", action="store_true",
                   help="Sub-Agenten-Dateien nicht mitmessen (schneller). Gibt es "
                        "welche, weist die Ausgabe KEINE Gesamtzahl mehr aus - eine "
                        "Teilmenge taugt nicht als Vergleichszahl.")
    p.add_argument("--lauf", nargs="+", metavar="JSONL",
                   help="mehrere Sessions als EINEN Lauf messen (seit dem Umbau "
                        "wird an jeder Phasenkante geschnitten). Pfade oder "
                        "Glob-Muster; Reihenfolge egal, es wird chronologisch "
                        "sortiert. Rechnet je Modell ab - siehe --preise-pauschal.")
    p.add_argument("--preise-je-modell", action="store_true",
                   help="Einzeldatei-Bericht mit modellgenauen Preisen statt "
                        "pauschal Fable 5. Noetig, sobald Sub-Agenten auf "
                        "anderen Modellen liefen - pauschal ist die Zahl zu hoch.")
    p.add_argument("--preise-pauschal", action="store_true",
                   help="Lauf-Bericht pauschal zu Fable-5-Preisen rechnen "
                        "(Vergleichbarkeit mit aelteren Baselines).")
    p.add_argument("--ziel-kontext", type=int, default=ZIEL_KONTEXT_MITTEL, metavar="N",
                   help="Zielwert mittlerer Kontext fuer den Lauf-Bericht "
                        "(Vorgabe %d aus SKILL.md S6)" % ZIEL_KONTEXT_MITTEL)
    p.add_argument("--ziel-cache-read", type=int, default=ZIEL_CACHE_READ, metavar="N",
                   help="Zielwert Cache-Read gesamt fuer den Lauf-Bericht "
                        "(Vorgabe %d aus SKILL.md S6)" % ZIEL_CACHE_READ)
    a = p.parse_args()

    if a.lauf:
        if a.session:
            sys.exit("Entweder eine einzelne Session ODER --lauf, nicht beides.\n"
                     "  Die Einzeldatei waere sonst zugleich Teil und Ganzes.")
        if a.bis_turn is not None:
            # Zeilennummern der einen Datei bedeuten in der naechsten nichts.
            sys.exit("--bis-turn gilt nur fuer eine einzelne Session, nicht fuer --lauf.")
        if a.ohne_subagenten:
            sys.exit("--ohne-subagenten und --lauf zusammen ergaeben eine Lauf-Summe "
                     "ohne Sub-Agenten - genau die Zahl, die Verlagerung wie "
                     "Ersparnis aussehen laesst.")
        r = messe_lauf(loese_pfade_auf(a.lauf),
                       preise_je_modell=not a.preise_pauschal,
                       ziel_kontext=a.ziel_kontext,
                       ziel_cache_read=a.ziel_cache_read)
        if a.als_json:
            r["preise_je_modell_pro_mio_usd"] = PREISE_JE_MODELL
            print(json.dumps(r, indent=2, ensure_ascii=False))
        else:
            drucke_lauf(r)
        return

    if a.preise_pauschal:
        sys.exit("--preise-pauschal gilt nur fuer --lauf; der Einzelbericht rechnet "
                 "ohnehin pauschal. Modellgenau: --preise-je-modell.")

    pfad = a.session or finde_neueste_session()
    if not os.path.isfile(pfad):
        sys.exit("Datei nicht gefunden: %s" % pfad)

    r = messe(pfad, a.bis_turn, mit_subagenten=not a.ohne_subagenten,
              preise_je_modell=a.preise_je_modell)
    if a.als_json:
        r["preise_pro_mio_usd"] = PREIS_PRO_MIO
        if a.preise_je_modell:
            r["preise_je_modell_pro_mio_usd"] = PREISE_JE_MODELL
        print(json.dumps(r, indent=2, ensure_ascii=False))
    else:
        drucke(r)


if __name__ == "__main__":
    main()
