---
name: session-ende
description: Session-Ende-Protokoll. Triggert bei Schluss/Ende/Feierabend (Session-Ende, nicht Aktion-Ende).
---

# Session-Ende-Protokoll

## Trigger

**JA** wenn Oliver die Arbeits-Session beendet:
"Schluss", "Ende", "Feierabend", "das war's fuer heute", "fuer heute reicht's", "wir hoeren auf", "ich bin raus", "ich gehe offline"

**NEIN** wenn das Wort sich auf eine Aktion bezieht:
"ende den Code-Block", "Schluss mit dem Refactor", "beende die Funktion", "ende des Skripts"

Im Zweifel: kurz nachfragen ("Session-Ende oder nur diese Aktion?").

## Ablauf — 6 Schritte in Reihenfolge

### 1. Memory-Check (Pflicht-Output)

Pruefe was in dieser Session gelernt wurde, das cross-session gespeichert werden sollte:

- **Feedback-Patterns** (Korrekturen von Oliver)
- **Neue Projekt-Fakten** (Status, Entscheidungen, Stakeholder)
- **Referenzen** zu externen Systemen

Routing-Regeln: `~/.claude/CLAUDE.md` → `## Memory`.

**Output (immer):**
- Wenn Memories geschrieben → Liste der angelegten/aktualisierten Dateinamen
- Wenn keine → ein Satz "Keine neuen Memories noetig"

### 1.5 Episode-Write (Pflicht-Output, automatisch)

Schreibe eine Session-Episode in den Episodic Memory Layer. Dient als Sammelbecken aus dem `/memory-audit` Achse 7 spaeter Promotion-Kandidaten ableitet.

**Pfad**: `~/.claude/episodes/YYYY-MM/YYYY-MM-DD_<session-id-prefix-8>.md`

- `YYYY-MM` aus heutigem Datum, Verzeichnis ggf. anlegen mit `mkdir -p`
- `session-id-prefix-8` = erste 8 Zeichen der aktuellen Session-ID (aus Konversations-Kontext, falls nicht ermittelbar: `unknown`)
- **Idempotent**: existierendes File mit gleichem Pfad ueberschreiben (nicht doppeln)

**Format** (genau diese Abschnitte, keine Frontmatter):

```markdown
# YYYY-MM-DD — Session <session-id-prefix-8>

**Was passierte**: <1-2 Saetze: Hauptarbeit dieser Session>

**Was gelernt**: <1-2 Saetze: konkrete Erkenntnis, neue Heuristik, korrigierte Annahme. "Nichts Neues" ist valider Output>

**Reibung/Wurzel**: <Wo musste Oliver nachsteuern oder blockte ein Hook? Wurzel-Typ (Taxonomie: `~/.claude/docs/memory-protocol.md` §Korrektur-Reflex-Loop) + ein Satz. Wurzel-Typ als EXAKTES Taxonomie-Token schreiben — die Fruehwarnung in 1.6 zaehlt nur woertliche Treffer. Beleg-basiert — nur was die Session real zeigte, nichts erfinden. "Keine Reibung" ist valider Output>

**Offen**: <kurz: was bleibt offen, oder "nichts">

**Workspace**: <slug aus pwd, gleiche Konvention wie Audit-Command Schritt 1>
```

**Output**: ein-Zeilen-Bestaetigung "Episode geschrieben: `<pfad>`" oder bei Fehler "Episode-Write fehlgeschlagen: `<grund>`" (kein Crash, nur Hinweis).

### 1.6 Wurzel-Typ-Fruehwarnung (automatisch, read-only)

Scanne NACH dem Episode-Write die `**Reibung/Wurzel**`-Zeilen aller Episoden der letzten 30 Tage (deterministisch; `*_blocked_*`-Episoden ausgenommen; Session = erste 8 Zeichen nach dem Datum im Dateinamen):

```bash
bash ~/.claude/hooks/wurzel-fruehwarnung.sh
```

Die Scan-Logik lebt vollstaendig im Script (Source of Truth, nicht hier duplizieren).

- Schwelle: **>=3 Treffer aus >=2 verschiedenen Sessions** pro Wurzel-Typ (identisch zu Audit-Achse 7b) → Kommando-Output 1:1 uebernehmen, eine Hinweis-Zeile pro Typ
- Kein Auto-Fix, kein eigenmaechtiger `/memory-audit`-Lauf — nur Hinweis, Oliver entscheidet
- **Output**: die Hinweis-Zeile(n); leerer Kommando-Output → kein Output, keine Erwaehnung (silent-by-default wie Schritt 5)

### 2. Chronicle-Check

Erfuellt die Session einen Chronicle-Trigger? (Liste in `~/.claude/chronicle/TEMPLATE.md` → "Trigger")

Wenn ja:
- Neue Datei anlegen unter `~/.claude/chronicle/YYYY-MM-DD_titel-mit-bindestrichen.md`
- Inhalt zwischen den `<!-- KOPIER-START -->` und `<!-- KOPIER-ENDE -->` Markern aus `TEMPLATE.md` als Vorlage nehmen
- Felder ausfuellen, niemals direkt in TEMPLATE.md schreiben

### 3. Chronicle-Distill-Check

- Lies Datum aus `~/.claude/chronicle/.last_distilled.txt` (ISO-Format `YYYY-MM-DD`)
- Wenn File fehlt → behandle als "alle Files frisch", schreibe Marker mit aelteltem Chronicle-Datum
- Zaehle Chronicle-Files mit `YYYY-MM-DD_*.md` deren Datum-Praefix > Marker-Datum
- Wenn **≥10 Files** ODER **letzter Distill > 14 Tage** her: Oliver auf Distill hinweisen (NICHT eigenmaechtig ausfuehren)

Marker-Update passiert NACH einem manuellen Distill-Lauf, nicht hier.

### 4. Offene Punkte (festes Output-Format)

Liefere immer in diesem Format:

```markdown
## Heute erledigt
- <Stichpunkt mit Datei/Pfad falls relevant>

## Offen
- [ ] <Task> (Datei/Pfad falls relevant)

## Naechster Schritt
<ein Satz>
```

### 5. Integritaets-Check (silent-by-default)

Nur in Git-Repos mit Commits von heute. Output NUR wenn auffaellig.

**Regressions-Check:**
Pruefe via `git log --since=midnight --name-status`:
Datei wurde heute mit netto **<-50 Zeilen** committet UND in einem **spaeteren** Commit mit netto **>+30 Zeilen** ergaenzt → Warnung mit Hash des Kuerzungs-Commits. (Schwellwerte verhindern False-Positives bei normalen Edits.)

Wenn nichts auffaellig: kein Output, keine Erwaehnung.
