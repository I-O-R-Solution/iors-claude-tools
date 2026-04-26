---
name: session-ende
description: Session-Ende-Protokoll mit Memory-Check, Chronicle-Check, Distill-Check, offenen Punkten und Integritaets-Check. Triggert wenn Oliver die Session beendet — "Schluss", "Ende", "Feierabend", "das war's fuer heute", "wir hoeren auf", "ich bin raus", "machen wir Schluss", "fuer heute reicht's". NICHT triggern bei Aktions-Ende ("ende den Block", "Schluss mit dem Refactor", "beende die Funktion") — nur bei Session-Ende.
---

# Session-Ende-Protokoll

## Wann triggert dieser Skill

**Triggert** wenn Oliver die aktuelle Arbeits-Session beendet:
- "Schluss", "Ende", "Feierabend"
- "das war's fuer heute", "fuer heute reicht's"
- "wir hoeren auf", "wir machen Schluss"
- "ich bin raus", "ich gehe offline"

**Triggert NICHT** wenn das Wort sich auf eine konkrete Aktion bezieht:
- "ende den Code-Block" → Aktion, kein Session-Ende
- "Schluss mit dem Refactor" → Aktion-Ende
- "beende die Funktion" → Aktion-Ende
- "ende des Skripts" → technischer Bezug

Im Zweifel: kurz nachfragen ("Session-Ende oder nur diese Aktion?"), nicht blind durchspulen.

## Ablauf — 5 Schritte in dieser Reihenfolge

### 1. Memory-Check

Was wurde in dieser Session gelernt, das cross-session gespeichert werden sollte?
- **Feedback-Patterns** (Korrekturen von Oliver)
- **Neue Projekt-Fakten** (Status, Entscheidungen, Stakeholder)
- **Referenzen** zu externen Systemen

Routing-Regeln siehe `~/.claude/CLAUDE.md` → `## Memory`.

### 2. Chronicle-Check

Erfuellt die Session einen Chronicle-Trigger?
- Erster Erfolg / Durchbruch
- Pivot oder grundlegende Richtungsaenderung
- "perfekt", "geil", "das ist es" vom User
- "Chronicle this" (Sofort-Trigger)
- Start eines neuen Projekts

Wenn ja: Eintrag nach `~/.claude/chronicle/TEMPLATE.md` schreiben.

### 3. Chronicle-Distill-Check

- Datum aus `~/.claude/chronicle/.last_distilled.txt` lesen
- Anzahl Chronicle-Files mit `mtime > last_distilled` zaehlen
- Wenn **≥10 Files** ODER **letzter Distill > 14 Tage** her:
  → Oliver auf Distill hinweisen (NICHT eigenmaechtig ausfuehren)
- Bei Distill-Lauf: Marker-File auf heutiges Datum aktualisieren

### 4. Offene Punkte

Kurze Zusammenfassung:
- Was wurde erledigt?
- Was ist offen?
- Was ist der naechste logische Schritt?

### 5. Integritaets-Check (silent-by-default)

Nur in Git-Repos mit Commits von heute. Output NUR wenn auffaellig:

**Regressions-Check:**
Wurde eine Datei heute erst stark gekuerzt (>50%) und spaeter wieder vergroessert?
→ Warnung mit Hash des Kuerzungs-Commits

**Parallel-Chat-Check:**
Mehrere `session-*.md` von heute ohne entsprechenden ENDE-Commit?
→ Warnung: "Vor naechstem Chat `git pull` + `git status` pruefen"

**Wenn nichts auffaellig:** kein Output, keine Erwaehnung.
