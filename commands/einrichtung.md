---
description: Persoenliche globale CLAUDE.md per Interview anlegen — 4 Fragen, max 20 Zeilen Ergebnis, /context-Check zum Schluss
argument-hint: [leer — der Command fuehrt durch alles]
allowed-tools: Read, Write, Edit, AskUserQuestion
disable-model-invocation: true
---

Du richtest die **persoenliche globale CLAUDE.md** des Users ein
(`~/.claude/CLAUDE.md`). Diese Datei wird in JEDER Claude-Code-Sitzung geladen,
egal in welchem Projekt. Sie beschreibt die Person, nicht ein Projekt.

**Mantras (in dieser Reihenfolge anwenden):**

1. *"Global ist nur, was in JEDEM Projekt gilt."* Projektregeln gehoeren in die
   Projekt-Datei — dafuer gibt es `/spark`.
2. *"Wuerde Claude ohne diese Zeile einen Fehler machen? Wenn nein — weglassen."*
   (Anthropic Golden-Rule-Test. Jede Zeile kostet in jeder Sitzung.)
3. *"Nicht behaupten — messen."* Ob die Datei wirklich geladen ist, zeigt
   `/context` unter **Memory files**, nicht dieses Gespraech.

<!-- Belegbasis (geprueft 2026-08-13):
     code.claude.com/docs/en/memory — Scope-Tabelle: "User instructions,
     ~/.claude/CLAUDE.md, Personal preferences for all projects";
     Zielmarke "target under 200 lines per CLAUDE.md file".
     code.claude.com/docs/en/best-practices — Include/Exclude-Tabelle,
     Golden-Rule-Test.
     code.claude.com/docs/en/skills, "Control who invokes a skill": Commands
     sind Skills, das Modell kann sie per Default selbst ziehen —
     disable-model-invocation ist fuer Ablaeufe mit Nebenwirkung empfohlen, und
     dieser hier schreibt in die globale Instruktionsdatei.
     Ebd., "Pre-approve tools for a skill": allowed-tools GENEHMIGT vorab, es
     restringiert nicht. Deshalb steht dort nur, was der Ablauf wirklich braucht.
     docs/en/tools-reference, "AskUserQuestion tool behavior": die Freitext-Zeile
     "Other" stellt das Werkzeug selbst bereit.
     Tilde-Pfade: gemessen 2026-08-13 auf Windows — Read UND Write loesen `~`
     auf. Ein Schritt, der $HOME durchreicht, wuerde dagegen schaden: Git Bash
     liefert dort die POSIX-Form /c/Users/... -->

Antworte in der Sprache des Users. Zielgruppe sind Einsteiger — kurze Saetze,
keine Fachbegriffe ohne Erklaerung im selben Satz.

## Schritt 1: Bestandscheck (NIE ueberschreiben)

Lies `~/.claude/CLAUDE.md` mit Read.

- **Datei fehlt oder ist leer** → weiter zu Schritt 2.
- **Datei existiert mit Inhalt** → Inhalt zeigen (bei mehr als 40 Zeilen nur die
  Ueberschriften), dann EINE Frage: *"Du hast schon eine globale CLAUDE.md.
  Soll ich sie um fehlende Punkte ERGAENZEN oder so lassen?"* Bei "so lassen":
  freundlich beenden, nichts schreiben.

**Verfahren fuer "ergaenzen"** — ohne das wird aus Ergaenzen unbemerkt Verdoppeln:

1. Beginnt eine Zeile mit `@`, ist das ein Import: die genannte Datei gehoert
   inhaltlich dazu. Lies sie mit, bevor du irgendetwas fuer "fehlend" haeltst.
   Sonst haengst du an, was laengst dasteht — nur eine Datei weiter.
2. Vergleiche pro **Abschnitt**, nicht pro Zeile: Steht Sprache und Ton schon
   irgendwo? Rolle? Verbote? Arbeitsweise? Was vorhanden ist — in welcher
   Formulierung auch immer — gilt als erledigt und wird nicht wiederholt.
3. Geschrieben wird die **vollstaendige neue Fassung** mit Write, nachdem du die
   alte gelesen hast: bestehende Zeilen woertlich uebernehmen, Fehlendes unten
   anhaengen. Nichts umformulieren, nichts umsortieren, nichts kuerzen.

## Schritt 2: Interview — EIN Block, 4 Fragen

Stelle alle vier Fragen in EINEM AskUserQuestion-Aufruf. Kein zweiter Durchgang;
was der User per "Other" frei eintippt, gilt woertlich.

Jede Frage braucht eine Kurz-Ueberschrift (`header`, hoechstens 12 Zeichen), jede
Antwort eine kurze Beschriftung (`label`, ein bis fuenf Woerter) und einen
erklaerenden Satz (`description`). Die Freitext-Zeile "Other" stellt das Werkzeug
selbst bereit — nimm sie NIE als eigene Antwortmoeglichkeit auf, sie wuerde einen
der vier Plaetze verbrauchen.

**Frage 1 — Ueberschrift "Sprache".** *"In welcher Sprache und welchem Ton soll
Claude mit dir reden?"* (eine Auswahl)

| Beschriftung | Erklaerung |
|---|---|
| Deutsch, kurz | Knappe Antworten, direkt auf den Punkt |
| Deutsch, ausfuehrlich | Deutsch mit Erklaerungen und Begruendungen |
| Englisch | Antworten auf Englisch |

**Frage 2 — Ueberschrift "Rolle".** *"Was ist deine Rolle bei der Arbeit?"*
(eine Auswahl). Zusatzhinweis in der Frage: *"Gern per 'Other' praeziser — ein
Satz reicht, z. B. 'Serviceberater in einem Autohaus' oder 'Buchhaltung in einer
Steuerkanzlei'."*

| Beschriftung | Erklaerung |
|---|---|
| Verkauf & Kundenkontakt | Beratung, Angebote, alles mit Kundenkontakt |
| Verwaltung & Buero | Organisation, Schriftverkehr, Zahlen, Ablaeufe |
| Technik & Werkstatt | Praktische Arbeit am Produkt oder an der Anlage |
| Leitung | Fuehrung, Entscheidungen, Verantwortung fuer andere |

**Frage 3 — Ueberschrift "Nie".** *"Was soll Claude NIE tun?"* (Mehrfachauswahl)

Die Beschriftungen muessen als **Verbotszeile** lesbar sein — sie landen woertlich
unter der Ueberschrift `# Nie`.

| Beschriftung | Erklaerung |
|---|---|
| Fehlende Angaben erfinden | Lieber nachfragen als eine Luecke fuellen |
| Preise oder Konditionen festlegen | Rabatte, Preise und Konditionen entscheidest du |
| Ohne Freigabe nach aussen | Keine E-Mail, keine Veroeffentlichung ohne dein OK |
| Dateien ohne Rueckfrage loeschen | Geloescht wird erst nach ausdruecklicher Zustimmung |

**Frage 4 — Ueberschrift "Immer".** *"Wie soll Claude arbeiten?"* (Mehrfachauswahl)

Die Beschriftungen muessen als **Anweisungszeile** lesbar sein — sie landen
woertlich unter der Ueberschrift `# Immer`.

| Beschriftung | Erklaerung |
|---|---|
| Erst zeigen, dann ausfuehren | Aenderungen vorlegen, nicht einfach machen |
| Bei Unsicherheit fragen | Nachfragen statt raten |
| Beleg zu jedem "fertig" | Datei, Ausgabe oder Ergebnis zeigen statt behaupten |

## Schritt 3: Zeigen, bestaetigen, schreiben, zuruecklesen

**Erst zeigen.** Baue aus den Antworten die Datei und zeige sie im Chat —
**hoechstens 20 Zeilen**, nur was der User gewaehlt oder getippt hat. KEINE
Vorratsregeln, KEINE Beispiele, KEIN Platzhalter. Geruest (leere Abschnitte
entfallen ersatzlos):

```markdown
# Ueber mich
- [Rolle in einem Satz]

# So antworten
- [Sprache und Ton]

# Nie
- [Antworten aus Frage 3, je eine Zeile]

# Immer
- [Antworten aus Frage 4, je eine Zeile]
```

Die Zuordnung ist fest: Frage 3 gehoert unter `# Nie`, Frage 4 unter `# Immer`.
Ein Verbot unter `# Immer` bedeutet das Gegenteil dessen, was der User wollte —
aus "nie Preise festlegen" wuerde eine Daueranweisung, Preise festzulegen.

**Dann bestaetigen lassen.** Eine Frage: so schreiben, oder etwas aendern? Erst
nach dem Ja wird geschrieben. Das ist keine Foermlichkeit — wer gerade "Erst
zeigen, dann ausfuehren" gewaehlt hat, wuerde sonst als Allererstes das Gegenteil
erleben.

**Dann schreiben.** Nach `~/.claude/CLAUDE.md`: Write bei Neuanlage, im
Ergaenzen-Fall die vollstaendige neue Fassung nach dem Verfahren aus Schritt 1.

**Dann zuruecklesen.** Datei mit Read erneut oeffnen und dem User Pfad und
Zeilenzahl nennen. Weicht der Inhalt von dem ab, was du gezeigt hast, sag es und
korrigiere — nicht beschoenigen. `/context` in Schritt 4 prueft nur, ob die Datei
GELADEN ist; ob das Richtige drinsteht, prueft allein dieser Rueckblick.

## Schritt 4: Pruefen — der Handgriff, der bleibt

Zeige dem User genau diese zwei Schritte:

1. Claude Code beenden und neu starten (die Datei wird beim START gelesen).
2. `/context` eingeben. Unter **Memory files** muss `~/.claude/CLAUDE.md`
   stehen. Steht sie dort: eingerichtet, gilt ab jetzt in jedem Projekt.
   Steht sie nicht dort: nicht raten — Pfad und Dateinamen pruefen
   (exakt `CLAUDE.md`, Grossbuchstaben).

Sag ehrlich dazu: Du kannst das nicht fuer den User messen — der Check gehoert
ihm. Genau dieser Handgriff prueft spaeter auch jede Projekt-Datei.

## Schritt 5: Abschluss

Zwei Saetze:

- *"Projektregeln (Hausregeln, Ablaeufe, Textvorgaben) gehoeren NICHT in diese
  Datei — dafuer legst du mit `/spark` pro Projekt einen Ordner mit eigener
  Instruktionsdatei an."*
- *"Wenn du die Datei spaeter pruefen willst: `/claudemd-optimize global`
  bewertet sie und schlaegt Kuerzungen vor."*

## Wichtige Regeln fuer dich

- **NIEMALS** eine bestehende `~/.claude/CLAUDE.md` ueberschreiben oder Zeilen
  darin umformulieren — nur anhaengen, und nur nach dem Gate in Schritt 1.
- **NIEMALS** Regeln erfinden, die der User nicht gewaehlt hat. Leer ist besser
  als geraten.
- **NIEMALS** mehr als 20 Zeilen schreiben. Wer mehr braucht, braucht ein
  Projekt (`/spark`), keine laengere Globaldatei. Im Ergaenzen-Fall gilt die
  Grenze fuer die **neu hinzugekommenen** Zeilen; eine bestehende laengere Datei
  wird nie gekuerzt, um sie einzuhalten.
- **NIEMALS** Projekt-Spezifisches aufnehmen (Pfade, Kundennamen, Produktregeln)
  — freundlich auf `/spark` verweisen. Die eigene Rolle und der eigene
  Arbeitgeber gehoeren dagegen hinein: sie beschreiben die Person.
- **IMMER** die Datei vor dem Schreiben zeigen und bestaetigen lassen (Schritt 3).
- **IMMER** den /context-Check aus Schritt 4 zeigen — er ist der Beweis, das
  Gespraech ist nur die Behauptung.
