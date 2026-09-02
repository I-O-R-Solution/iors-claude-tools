#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""kanten-messung.py - misst an der Schnittkante statt am Lauf-Ende.

WOZU
Der Abschluss (S6) misst den Lauf ueber `measure-run.py --lauf <alle .jsonl>`.
Das setzt zweierlei voraus, und beides hat gemessen nicht getragen:

  1. Die Liste der Sessions muss vollstaendig und richtig sein. Sie wird von
     Hand in `STATE.md` gefuehrt - und das 4096-B-Budget drueckt sie heraus:
     `wissens-center` traegt "Sessions: …,d66ffe1e,97eef5cb (Vollliste in
     f57a334^)", die volle Liste lebt nur noch in einem Eltern-Commit;
     `ueber-uns-nextlevel` hat gar keine Sessions-Zeile. Zwei von drei
     geprueften Laeufen tragen ausserdem eine Kennung, die NIE eine Datei
     getragen hat (`08399`, `cd0cba7e` - am 30.07.2026 in jedem
     Workspace-Ordner gesucht, nirgends; die Nachbarsessions derselben
     Stunden liegen alle da). Verschrieben, nicht geloescht.
  2. Die Transkripte muessen zum Schlusszeitpunkt noch existieren. Claude Code
     raeumt nach `cleanupPeriodDays` auf - ohne Eintrag in settings.json sind
     das 30 Tage. Am 30.07.2026 gemessen: das aelteste Transkript endet in
     JEDEM Workspace exakt an dieser Kante (AI-COMPLIANCE 30 Tage bei 168
     Dateien, IORS-CRM 29, claude-config 25). Die Grenze ist real. Sie hat
     bisher keinen Lauf gekostet - ein Lauf, der laenger als 30 Tage nach
     seiner ersten Session schliesst, verliert seinen Anfang aber lautlos.

Diese Datei dreht die Richtung um: JEDE Boss-Session misst SICH SELBST an
ihrer Schnittkante und haengt eine Zeile an `<lauf>/MESSUNG.md`. Die Session
kennt ihre eigene Kennung (Umgebungsvariable `CLAUDE_CODE_SESSION_ID`) -
verschreiben ist unmoeglich, Rekonstruieren unnoetig. S6 rechnet danach nur
noch gespeicherte Zeilen zusammen; ob die Transkripte dann noch da sind,
spielt keine Rolle mehr.

EHRLICHKEITS-GRENZE, die nicht wegzudiskutieren ist
Die Zeile entsteht, waehrend die Session noch laeuft. Was DANACH kommt -
`STATE.md` schreiben, committen, der Abschlussbericht - steht nicht darin.
Die Zahl ist also ein belegtes Minimum, kein Endstand; der Fehlbetrag ist
etwa ein Zug (gemessene Drift 10-30k Kontext). Das steht so im Kopf jeder
erzeugten MESSUNG.md und in jedem Bericht. Eine Zahl, deren Grenze man nicht
sieht, ist genau die Falle, gegen die `measure-run.py` gebaut ist.

AUFRUF
    python kanten-messung.py <lauf-ordner>              # eigene Zeile anhaengen
    python kanten-messung.py <lauf-ordner> --bericht    # S6: aggregieren
    python kanten-messung.py <lauf-ordner> --bericht --json

`<lauf-ordner>` ist der Ordner des Laufs - `.planning/route/<slug>/` ODER
`.planning/route-opus/<slug>/`. Der woertliche `route/`-Pfad spaltet einen
route-opus-Lauf lautlos; deshalb wird der Ordner uebergeben und nicht geraten.

stdlib-only, wie `measure-run.py`. Die Zaehl- und Preislogik wird NICHT neu
gebaut, sondern von dort importiert - zwei Zaehlweisen waeren zwei Wahrheiten.
"""

import argparse
import glob
import importlib.util
import io
import json
import os
import re
import sys

HIER = os.path.dirname(os.path.abspath(__file__))

# Windows-Konsolen laufen per Vorgabe auf cp1252 und machen aus dem
# Geviertstrich der LESSONS-Zeile ein Fragezeichen - eine Zeile zum Kopieren,
# die man nicht kopieren kann. Bewusst weich: schlaegt es fehl, laeuft der
# Bericht trotzdem, nur mit Ersatzzeichen.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass


def lade_messer():
    """Importiert measure-run.py. Der Bindestrich verbietet ein normales import."""
    pfad = os.path.join(HIER, "measure-run.py")
    if not os.path.isfile(pfad):
        sys.exit("measure-run.py fehlt neben dieser Datei: %s" % pfad)
    spec = importlib.util.spec_from_file_location("measure_run", pfad)
    modul = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(modul)
    return modul


M = lade_messer()

# Preisbasis dieser Datei. Bewusst dieselbe wie im Lauf-Bericht von
# measure-run.py (je_modell): die Kantenzeilen ERSETZEN diesen Bericht, sie
# duerfen ihm also nicht auf einer anderen Basis widersprechen.
PREISBASIS = "je_modell"

# Spaltenordnung ist Vertrag. Schreiben und Lesen benutzen dieselbe Liste -
# eine Spalte einzufuegen, ohne die Leseseite anzufassen, ist damit unmoeglich.
SPALTEN = [
    ("session",     "Session"),
    ("von",         "von"),
    ("bis",         "bis"),
    ("anfragen",    "Anf"),
    ("subagenten",  "Sub"),
    ("ktx_start",   "Ktx-Start"),
    ("ktx_mittel",  "Ktx-Mittel"),
    ("ktx_anzahl",  "Ktx-Anz"),
    ("ktx_spitze",  "Ktx-Spitze"),
    ("ktx_ende",    "Ktx-Ende"),
    ("cache_read",  "Cache-Read"),
    ("kosten",      "Kosten $"),
]
ZAHL_SPALTEN = ("anfragen", "subagenten", "ktx_start", "ktx_mittel",
                "ktx_anzahl", "ktx_spitze", "ktx_ende", "cache_read")

KOPF = """# MESSUNG — {slug}

Eine Zeile je Boss-Session, geschrieben **von der Session selbst an ihrer
Schnittkante** — nicht am Lauf-Ende. Erzeugt von
`~/.claude/skills/route/tools/kanten-messung.py`; von Hand nichts ändern, S6
rechnet hiermit.

Warum nicht am Schluss: die Sessions-Liste in `STATE.md` wird vom Byte-Budget
herausgedrückt und trägt gemessen Tippfehler, und Transkripte werden nach
`cleanupPeriodDays` (Vorgabe 30 Tage) aufgeräumt. Eine hier gespeicherte Zeile
überlebt beides.

**Grenze der Zahlen, ausdrücklich:** jede Zeile entsteht, während ihre Session
noch läuft. Was danach kommt — `STATE.md` schreiben, committen, der
Abschlussbericht — fehlt darin. Die Werte sind belegte **Mindestwerte**, der
Fehlbetrag liegt bei etwa einem Zug (gemessene Drift 10–30k Kontext).

Preisbasis: **{basis}** (jede Anfrage zum Preis ihres eigenen Modells) —
dieselbe wie im Lauf-Bericht von `measure-run.py`, damit die Zahlen
vergleichbar bleiben. `Ktx-Anz` ist das Gewicht für den gepoolten Mittelwert
(Anfragen mit Kontextwert); `Ktx-Ende` erlaubt S6 den Schnitt-Nachweis gegen
den Start der Folgesession.

"""


# ---------------------------------------------------------------------------
# Formatierung: z()/geld() aus measure-run.py, plus ihre exakten Umkehrungen.
# Ohne die Umkehrungen waere die Datei fuer Menschen lesbar und fuer den
# Bericht Datenmuell - beides zusammen ist der Punkt.
# ---------------------------------------------------------------------------

def entz(text):
    """'118.400' -> 118400. Umkehrung von measure-run.z()."""
    text = (text or "").strip().replace(".", "")
    return int(text) if text.lstrip("-").isdigit() else 0


def entgeld(text):
    """'1.234,56' -> 1234.56. Umkehrung von measure-run.geld(). None bei 'n/a'."""
    text = (text or "").strip()
    if not text or text == "n/a":
        return None
    text = text.replace(".", "").replace(",", ".")
    try:
        return float(text)
    except ValueError:
        return None


# ---------------------------------------------------------------------------
# Eigene Session finden
# ---------------------------------------------------------------------------

def eigene_session():
    """(session_id, transkript_pfad) der LAUFENDEN Session.

    Quelle ist CLAUDE_CODE_SESSION_ID - dasselbe Verfahren, das
    tools/zonen-melder.py seit dem 25.07.2026 im Dauerbetrieb benutzt.
    Bewusst NICHT "die neueste .jsonl im Ordner": bei Olivers parallelen
    Sessions greift das regelmaessig die falsche Datei, und ein falsch
    zugeordneter Messwert ist schlimmer als keiner.
    """
    sid = os.environ.get("CLAUDE_CODE_SESSION_ID")
    if not sid:
        sys.exit(
            "CLAUDE_CODE_SESSION_ID ist nicht gesetzt - die eigene Session ist\n"
            "nicht bestimmbar. Kein Rateverfahren: die neueste .jsonl im Ordner\n"
            "ist bei parallelen Sessions regelmaessig eine fremde."
        )
    treffer = glob.glob(os.path.expanduser("~/.claude/projects/*/%s.jsonl" % sid))
    if not treffer:
        sys.exit("Kein Transkript zu Session %s unter ~/.claude/projects/*/ gefunden." % sid)
    return sid, treffer[0]


# ---------------------------------------------------------------------------
# Tabelle lesen und schreiben
# ---------------------------------------------------------------------------

def lies_datei(pfad):
    """Liest Text und normalisiert CRLF weg.

    Das ist kein Schoenheitsschritt. In `plattform-spike/sessions.txt` traegt
    genau EINE Zeile ein Windows-Zeilenende; beim Nachschlagen ueber die Shell
    haengt dann ein unsichtbares \\r an der Kennung, der Treffer bleibt aus und
    die Session gilt als verschwunden. Genau so entsteht ein Rotations-Befund,
    wo nichts rotiert ist (am 30.07.2026 live reproduziert).
    """
    if not os.path.isfile(pfad):
        return None
    with io.open(pfad, "r", encoding="utf-8", errors="replace", newline="") as f:
        return f.read().replace("\r\n", "\n").replace("\r", "\n")


def lies_zeilen(messung_pfad):
    """Alle Datenzeilen der MESSUNG.md als Liste von dicts, in Dateireihenfolge."""
    text = lies_datei(messung_pfad)
    if text is None:
        return []
    zeilen = []
    for roh in text.split("\n"):
        roh = roh.strip()
        if not roh.startswith("|") or not roh.endswith("|"):
            continue
        felder = [f.strip() for f in roh[1:-1].split("|")]
        if len(felder) != len(SPALTEN):
            continue
        if felder[0] in ("Session", "") or set(felder[0]) <= set("-: "):
            continue          # Kopf- und Trennzeile
        satz = dict(zip([s[0] for s in SPALTEN], felder))
        satz["_roh"] = roh
        zeilen.append(satz)
    return zeilen


def formatiere_zeile(satz):
    return "| " + " | ".join(str(satz[s[0]]) for s in SPALTEN) + " |"


def schreibe(messung_pfad, slug, zeilen):
    """Schreibt Kopf + Tabelle. Sortiert chronologisch nach 'von'."""
    zeilen = sorted(zeilen, key=lambda s: (s["von"] == "?", s["von"]))
    aus = [KOPF.format(slug=slug, basis=PREISBASIS)]
    aus.append("| " + " | ".join(s[1] for s in SPALTEN) + " |")
    aus.append("|" + "|".join("---" for _ in SPALTEN) + "|")
    aus.extend(formatiere_zeile(s) for s in zeilen)
    aus.append("")
    with io.open(messung_pfad, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(aus))


def messe_und_haenge_an(lauf_ordner):
    sid, transkript = eigene_session()
    messung_pfad = os.path.join(lauf_ordner, "MESSUNG.md")
    slug = os.path.basename(os.path.normpath(lauf_ordner))

    r = M.messe(transkript, None, mit_subagenten=True, preise_je_modell=True)
    k = r["kontext_hauptdatei"]
    sub = r["subagenten"]

    # kosten_usd_gesamt ist None, wenn measure-run.py die Gesamtzahl nicht
    # ehrlich bilden kann (z. B. Sidechain-Anfragen UND eigene
    # Sub-Agenten-Dateien - dieselbe Arbeit koennte doppelt zaehlen). Dann
    # steht hier "n/a" und der Bericht weist die Luecke aus. Eine Teilsumme
    # an dieser Stelle waere die stille Zahl, die niemand mehr hinterfragt.
    kosten = r["kosten_usd_gesamt"]
    satz = {
        "session":    sid,
        "von":        M.kurz_zeit(r["zeitraum"]["von"]),
        "bis":        M.kurz_zeit(r["zeitraum"]["bis"]),
        "anfragen":   M.z(r["turns_hauptdatei"]["api_anfragen"]),
        "subagenten": M.z(sub["api_anfragen"]) if sub else "0",
        "ktx_start":  M.z(k["start"]),
        "ktx_mittel": M.z(k["mittel"]),
        "ktx_anzahl": M.z(k["anzahl"]),
        "ktx_spitze": M.z(k["maximum"]),
        "ktx_ende":   M.z(k["ende"]),
        "cache_read": M.z(r["token_gesamt"]["cache_read"] if r["token_gesamt"]
                          else r["token_hauptdatei"]["cache_read"]),
        "kosten":     M.geld(kosten) if kosten is not None else "n/a",
    }

    alt = lies_zeilen(messung_pfad)
    # Idempotent: dieselbe Session ueberschreibt ihre eigene Zeile. Eine Session
    # kann an einer roten Kante messen und nach dem Fix erneut - zwei Zeilen
    # fuer dieselbe Session wuerden ihren Aufwand doppelt zaehlen.
    ersetzt = False
    neu = []
    for s in alt:
        if s["session"] == sid:
            neu.append(satz)
            ersetzt = True
        else:
            neu.append(s)
    if not ersetzt:
        neu.append(satz)
    schreibe(messung_pfad, slug, neu)

    print("%s  %s" % ("ERSETZT " if ersetzt else "ANGEHAENGT", messung_pfad))
    print(formatiere_zeile(satz))
    if kosten is None:
        print("  ACHTUNG Kosten 'n/a': %s" % r["gesamt_unvollstaendig_grund"])
    print("  Mindestwerte - die Zuege nach dieser Messung (STATE.md, Commit,")
    print("  Bericht) sind nicht enthalten.")
    return 0


# ---------------------------------------------------------------------------
# Der Zettel als Gegenprobe: welche Sessions BEHAUPTET der Lauf zu haben?
# ---------------------------------------------------------------------------

KENNUNG = re.compile(r"^[0-9a-fA-F]{4,8}(?:-[0-9a-fA-F-]+)?$")


def zettel_sessions(lauf_ordner):
    """Session-Kennungen aus STATE.md (Zeile 'Sessions:') und sessions.txt.

    Rueckgabe: (kennungen, quellen, abgetreten). Beide Quellen werden gelesen,
    nicht die eine ODER die andere: `plattform-spike` lagert die Liste nach
    sessions.txt aus, weil sie sonst das Byte-Budget reisst - wer nur STATE.md
    liest, findet dort den Dateinamen und haelt ihn fuer eine Kennung.

    'abgetreten' ist der Ausweg aus dem Byte-Problem: nennt die Sessions-Zeile
    MESSUNG.md, tritt der Zettel die Liste ausdruecklich an diese Datei ab.
    Das ist keine Luecke, sondern eine Entscheidung - und sie kostet 25 Byte
    statt 120. Genau das Byte-Budget hat die Liste in zwei geprueften Laeufen
    zerschossen (einmal in einen Eltern-Commit ausgelagert, einmal ganz weg).
    Der Unterschied zu "keine Zeile": hier steht, WO die Wahrheit liegt.
    """
    kennungen, quellen = [], []
    abgetreten = False

    state = lies_datei(os.path.join(lauf_ordner, "STATE.md"))
    if state is not None:
        for zeile in state.split("\n"):
            if "Sessions:" not in zeile:
                continue
            quellen.append("STATE.md")
            rest = zeile.split("Sessions:", 1)[1]
            if "MESSUNG.md" in rest:
                abgetreten = True
            # Klammerzusaetze sind Prosa ("(Vollliste in f57a334^)"), keine Kennungen.
            rest = re.sub(r"\([^)]*\)", " ", rest)
            for stueck in re.split(r"[,\s·]+", rest):
                stueck = stueck.strip()
                if stueck and KENNUNG.match(stueck):
                    kennungen.append(stueck)
            break

    st = os.path.join(lauf_ordner, "sessions.txt")
    text = lies_datei(st)
    if text is not None:
        quellen.append("sessions.txt")
        for zeile in text.split("\n"):
            zeile = zeile.strip()
            if zeile and not zeile.startswith("#") and KENNUNG.match(zeile):
                kennungen.append(zeile)

    # Reihenfolge erhalten, Doppelte raus.
    gesehen, geordnet = set(), []
    for k in kennungen:
        if k.lower() not in gesehen:
            gesehen.add(k.lower())
            geordnet.append(k)
    return geordnet, quellen, abgetreten


def transkript_da(sid):
    return bool(glob.glob(os.path.expanduser("~/.claude/projects/*/%s*.jsonl" % sid)))


# ---------------------------------------------------------------------------
# Bericht
# ---------------------------------------------------------------------------

def bericht(lauf_ordner):
    messung_pfad = os.path.join(lauf_ordner, "MESSUNG.md")
    zeilen = lies_zeilen(messung_pfad)
    zettel, quellen, abgetreten = zettel_sessions(lauf_ordner)

    gemessene = [z["session"] for z in zeilen]

    # Richtung A - im Zettel genannt, aber nie gemessen: die Summe unten hat
    # ein Loch. Praefixe erlaubt, der Zettel kuerzt sie wegen des Byte-Budgets.
    ohne_messung, mehrdeutig = [], []
    for k in zettel:
        treffer = [g for g in gemessene if g.lower().startswith(k.lower())]
        if not treffer:
            ohne_messung.append(k)
        elif len(treffer) > 1:
            mehrdeutig.append((k, treffer))

    # Richtung B - gemessen, aber im Zettel nicht genannt. Die Summe stimmt
    # trotzdem (die Session hat in diesem Lauf gearbeitet, sonst gaebe es die
    # Zeile nicht) - der ZETTEL ist falsch. Genau diese Richtung haette die
    # zwei Phantom-Kennungen vom 30.07. gefunden.
    ohne_zettel = [g for g in gemessene
                   if not any(g.lower().startswith(k.lower()) for k in zettel)]

    anfragen = sum(entz(z["anfragen"]) for z in zeilen)
    sub = sum(entz(z["subagenten"]) for z in zeilen)
    cache_read = sum(entz(z["cache_read"]) for z in zeilen)
    spitze = max([entz(z["ktx_spitze"]) for z in zeilen] or [0])

    gewicht = sum(entz(z["ktx_anzahl"]) for z in zeilen)
    mittel = (sum(entz(z["ktx_mittel"]) * entz(z["ktx_anzahl"]) for z in zeilen)
              // gewicht) if gewicht else 0

    ohne_kosten = [z["session"] for z in zeilen if entgeld(z["kosten"]) is None]
    kosten = sum(entgeld(z["kosten"]) or 0.0 for z in zeilen)

    # Die Summe ist NUR dann eine Gesamtzahl, wenn nichts fehlt. Sonst wird sie
    # weggelassen statt geschaetzt - dieselbe Regel wie in measure-run.py.
    luecken = []
    if not zeilen:
        luecken.append("keine einzige Kantenzeile vorhanden")
    # Ohne Gegenprobe ist "vollstaendig" eine Behauptung. Eine leere oder
    # fehlende Sessions-Zeile faellt deshalb genauso wie eine fehlende Kante -
    # sonst waere ausgerechnet der Lauf, der seine Liste verloren hat, der
    # einzige mit einer angeblich sauberen Summe (real: ueber-uns-nextlevel).
    if not abgetreten and not zettel:
        luecken.append(
            "keine pruefbare Sessions-Liste im Lauf (weder Kennungen in der "
            "STATE.md-Zeile noch sessions.txt) - Vollstaendigkeit nicht "
            "gegenpruefbar. Billigster Fix: 'Sessions: siehe MESSUNG.md'")
    for k in ohne_messung:
        luecken.append("Session %s steht im Zettel, hat aber keine Kantenzeile" % k)
    for k, t in mehrdeutig:
        luecken.append("Praefix %s trifft %d Kantenzeilen (%s) - nicht aufloesbar"
                       % (k, len(t), ", ".join(x[:8] for x in t)))
    for s in ohne_kosten:
        luecken.append("Session %s hat keine bildbare Kostenzahl (n/a)" % s[:8])

    schnitte = []
    for i in range(1, len(zeilen)):
        vor, jetzt = entz(zeilen[i - 1]["ktx_ende"]), entz(zeilen[i]["ktx_start"])
        schnitte.append({
            "session": zeilen[i]["session"],
            "vorsession_ende": vor,
            "start": jetzt,
            "startet_am_sockel": jetzt <= M.SOCKEL_GRENZE,
        })

    return {
        "lauf": os.path.basename(os.path.normpath(lauf_ordner)),
        "messung_datei": os.path.abspath(messung_pfad),
        "preisbasis": PREISBASIS,
        "sessions_gemessen": len(zeilen),
        "zettel_quellen": quellen,
        "zettel_kennungen": zettel,
        "zettel_abgetreten_an_messung": abgetreten,
        "api_anfragen_hauptdateien": anfragen,
        "api_anfragen_subagenten": sub,
        "api_anfragen_gesamt": anfragen + sub,
        "kontext_mittel": mittel,
        "kontext_spitze": spitze,
        "cache_read_gesamt": cache_read,
        "kosten_usd_summe_der_zeilen": kosten,
        "kosten_usd_gesamt": None if luecken else kosten,
        "luecken": luecken,
        "kanten_ohne_messung": ohne_messung,
        "messung_ohne_zettel": ohne_zettel,
        "transkript_fehlt_noch_egal": [z["session"] for z in zeilen
                                       if not transkript_da(z["session"])],
        "schnitte": schnitte,
        "ziele": {
            "kontext_mittel": {"gemessen": mittel,
                               "soll_hoechstens": M.ZIEL_KONTEXT_MITTEL,
                               "erreicht": mittel <= M.ZIEL_KONTEXT_MITTEL},
            "cache_read_gesamt": {"gemessen": cache_read,
                                  "soll_hoechstens": M.ZIEL_CACHE_READ,
                                  "erreicht": cache_read <= M.ZIEL_CACHE_READ},
        },
    }


def drucke_bericht(r):
    b = "=" * 74
    print(b)
    print("KANTEN-MESSUNG  %s  (%d Session(s))" % (r["lauf"], r["sessions_gemessen"]))
    print(b)
    print("Quelle     %s" % r["messung_datei"])
    print("Preisbasis %s (jede Anfrage zum Preis ihres Modells)" % r["preisbasis"])
    if r["zettel_abgetreten_an_messung"]:
        print("Zettel     STATE.md tritt die Liste ausdruecklich an MESSUNG.md ab")
    else:
        print("Zettel     %s (%d Kennung(en))"
              % (", ".join(r["zettel_quellen"]) or "KEINE Sessions-Liste gefunden",
                 len(r["zettel_kennungen"])))

    print("\n-- TURNS --")
    print("  Hauptdateien                   %s" % M.z(r["api_anfragen_hauptdateien"]))
    print("  Sub-Agenten                    %s" % M.z(r["api_anfragen_subagenten"]))
    print("  GESAMT                         %s" % M.z(r["api_anfragen_gesamt"]))

    print("\n-- KONTEXT --")
    print("  Mittel (gepoolt)               %s Token" % M.z(r["kontext_mittel"]))
    print("  Spitze im Lauf                 %s Token" % M.z(r["kontext_spitze"]))
    print("  Cache-Read gesamt              %s Token" % M.z(r["cache_read_gesamt"]))

    if r["schnitte"]:
        print("\n-- HABEN DIE SCHNITTE GEWIRKT? --")
        for s in r["schnitte"]:
            print("  %s startet bei %s, Vorsession endete bei %s -> %s"
                  % (s["session"][:8], M.z(s["start"]), M.z(s["vorsession_ende"]),
                     "am Sockel" if s["startet_am_sockel"] else "NICHT am Sockel"))

    print("\n-- ZIELE --")
    for name, titel in (("kontext_mittel", "Kontext-Mittel"),
                        ("cache_read_gesamt", "Cache-Read gesamt")):
        zl = r["ziele"][name]
        print("  %-18s gemessen %14s   Soll hoechstens %14s   %s"
              % (titel, M.z(zl["gemessen"]), M.z(zl["soll_hoechstens"]),
                 "ERREICHT" if zl["erreicht"] else "VERFEHLT"))

    if r["transkript_fehlt_noch_egal"]:
        print("\n-- ROTIERT, ABER GEMESSEN --")
        for s in r["transkript_fehlt_noch_egal"]:
            print("  %s: Transkript nicht mehr auf Platte - die Kantenzeile traegt" % s[:8])
        print("  die Zahlen trotzdem. Genau dafuer gibt es diese Datei.")

    if r["messung_ohne_zettel"]:
        print("\n-- ZETTEL UNVOLLSTAENDIG (Summe unten stimmt trotzdem) --")
        for s in r["messung_ohne_zettel"]:
            print("  %s hat gemessen, steht aber in keiner Sessions-Liste." % s[:8])
        print("  Die Zeile zaehlt (sie kann nur aus diesem Lauf stammen); der")
        print("  ZETTEL ist falsch oder gekuerzt. In STATE.md nachtragen.")

    print("\n-- GESAMT --")
    if r["kosten_usd_gesamt"] is None:
        print("  Summe der vorhandenen Zeilen    %14s $"
              % M.geld(r["kosten_usd_summe_der_zeilen"]))
        print("  GESAMT                          %14s" % "nicht bildbar")
        for l in r["luecken"]:
            print("    - %s" % l)
        print("  Diese Zahl ist KEINE Lauf-Summe. Die fehlenden Kanten benennen")
        print("  oder ihre Sessions nachmessen, dann erneut.")
    else:
        print("  GESAMT (alle Kanten + Sub-Agenten) %11s $" % M.geld(r["kosten_usd_gesamt"]))
        print("  Mindestwert: die Zuege nach jeder Messung fehlen (siehe MESSUNG.md).")
        print("\n  Zeile fuer LESSONS.md:")
        n = r["sessions_gemessen"]
        print("  ## <JJJJ-MM-TT> — %s (%s Anfragen, Spitze %sk, Mittel %sk, %s $, %d Boss-%s)"
              % (r["lauf"], M.z(r["api_anfragen_gesamt"]),
                 M.z(r["kontext_spitze"] // 1000), M.z(r["kontext_mittel"] // 1000),
                 M.geld(r["kosten_usd_gesamt"]), n, "Sitz" if n == 1 else "Sitze"))
    print(b)


def main():
    p = argparse.ArgumentParser(
        description="Misst eine Boss-Session an ihrer Schnittkante und "
                    "aggregiert die gespeicherten Zeilen fuer S6.")
    p.add_argument("lauf", help="Lauf-Ordner: .planning/route/<slug>/ oder "
                                ".planning/route-opus/<slug>/")
    p.add_argument("--bericht", action="store_true",
                   help="nicht messen, sondern die gespeicherten Zeilen "
                        "aggregieren und Luecken benennen (S6)")
    p.add_argument("--json", action="store_true", dest="als_json",
                   help="maschinenlesbare Ausgabe (nur mit --bericht)")
    a = p.parse_args()

    lauf = os.path.abspath(os.path.expanduser(a.lauf))
    if not os.path.isdir(lauf):
        sys.exit("Lauf-Ordner nicht gefunden: %s" % lauf)

    if a.bericht:
        r = bericht(lauf)
        if a.als_json:
            print(json.dumps(r, indent=2, ensure_ascii=False))
        else:
            drucke_bericht(r)
        # Exit 1 bei Luecken, damit ein Skript den Fehlbestand nicht uebersieht.
        return 1 if r["luecken"] else 0

    if a.als_json:
        sys.exit("--json gilt nur mit --bericht.")
    return messe_und_haenge_an(lauf)


if __name__ == "__main__":
    sys.exit(main())
