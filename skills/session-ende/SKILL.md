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

## Ablauf — 5 Schritte in Reihenfolge

### 1. Memory-Check (Pflicht-Output)

Pruefe was in dieser Session gelernt wurde, das cross-session gespeichert werden sollte:

- **Feedback-Patterns** (Korrekturen von Oliver)
- **Neue Projekt-Fakten** (Status, Entscheidungen, Stakeholder)
- **Referenzen** zu externen Systemen

Routing-Regeln: `~/.claude/CLAUDE.md` → `## Memory`.

**Output (immer):**
- Wenn Memories geschrieben → Liste der angelegten/aktualisierten Dateinamen
- Wenn keine → ein Satz "Keine neuen Memories noetig"

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

**Parallel-Chat-Check:**
Mehrere `session-*.md` Files im Workspace (Konvention: Session-Logs nach `~/.claude/projects/*/session-*.md`) von heute ohne entsprechenden ENDE-Commit → Warnung: "Vor naechstem Chat `git pull` + `git status` pruefen".

Wenn nichts auffaellig: kein Output, keine Erwaehnung.
