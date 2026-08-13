---
description: Persoenliche globale CLAUDE.md per Interview anlegen — 4 Fragen, max 20 Zeilen Ergebnis, /context-Check zum Schluss
argument-hint: [leer — der Command fuehrt durch alles]
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion
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
     Golden-Rule-Test. -->

Antworte in der Sprache des Users. Zielgruppe sind Einsteiger — kurze Saetze,
keine Fachbegriffe ohne Erklaerung im selben Satz.

## Schritt 1: Bestandscheck (NIE ueberschreiben)

Lies `~/.claude/CLAUDE.md` mit Read.

- **Datei fehlt oder ist leer** → weiter zu Schritt 2.
- **Datei existiert mit Inhalt** → Inhalt zeigen (bei mehr als 40 Zeilen nur die
  Ueberschriften), dann EINE Frage: *"Du hast schon eine globale CLAUDE.md.
  Soll ich sie um fehlende Punkte ERGAENZEN oder so lassen?"* Bei "so lassen":
  freundlich beenden, nichts schreiben. Bei "ergaenzen": Interview laeuft, aber
  am Ende werden nur Zeilen ANGEHAENGT, die inhaltlich noch fehlen — bestehende
  Zeilen bleiben woertlich unangetastet.

## Schritt 2: Interview — EIN Block, 4 Fragen

Stelle alle vier Fragen in EINEM AskUserQuestion-Aufruf. Kein zweiter Durchgang;
was der User per "Other" frei eintippt, gilt woertlich.

1. **Sprache & Ton** (eine Auswahl):
   Deutsch, kurz und direkt / Deutsch, ausfuehrlicher mit Erklaerungen /
   Englisch / andere Sprache (Other)
2. **Rolle** (eine Auswahl + Other fuer den eigenen Wortlaut):
   Verkauf & Kundenkontakt / Verwaltung & Buero / Technik & Werkstatt /
   Leitung. Zusatzhinweis in der Frage: *"Gern per 'Other' praeziser — ein
   Satz reicht, z. B. 'Serviceberater im Autohaus X'."*
3. **Was Claude NIE tun darf** (Mehrfachauswahl):
   Fehlende Angaben erfinden — stattdessen nachfragen /
   Preise, Rabatte oder Konditionen selbst festlegen /
   Etwas nach aussen schicken (E-Mail, Veroeffentlichung) ohne Freigabe /
   Dateien loeschen ohne Rueckfrage
4. **Arbeitsweise** (Mehrfachauswahl):
   Aenderungen erst zeigen, dann ausfuehren /
   Bei Unsicherheit fragen statt raten /
   Zu jedem "fertig" den Beleg zeigen (Datei, Ausgabe, Ergebnis)

## Schritt 3: Datei schreiben

Baue aus den Antworten die Datei — **hoechstens 20 Zeilen**, nur was der User
gewaehlt oder getippt hat. KEINE Vorratsregeln, KEINE Beispiele, KEIN Platzhalter.
Geruest (leere Sektionen entfallen ersatzlos):

```markdown
# Ueber mich
- [Rolle in einem Satz]

# So antworten
- [Sprache und Ton]

# Immer
- [gewaehlte Verbote und Arbeitsweisen, je eine Zeile]
```

Schreibe nach `~/.claude/CLAUDE.md` (Write bei Neuanlage, Edit/Anhaengen im
Ergaenzen-Fall aus Schritt 1).

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
  Projekt (`/spark`), keine laengere Globaldatei.
- **NIEMALS** Projekt-Spezifisches aufnehmen (Pfade, Kundennamen, Produktregeln)
  — freundlich auf `/spark` verweisen.
- **IMMER** den /context-Check aus Schritt 4 zeigen — er ist der Beweis, das
  Gespraech ist nur die Behauptung.
