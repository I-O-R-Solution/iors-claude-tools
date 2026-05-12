---
name: spark
description: Legt ein neues Projekt mit intelligenter Tiefen-Ableitung an — adaptive Eingabe (freie Beschreibung ODER 3-Fragen-Fallback), Excellence-Anchor (3 Schleifstein-Fragen), Craft-Principles als 0er-ADR, Migrations-Modus fuer bestehende Ordner, Living-Doc-Vertrag, Pflicht-Trio (CLAUDE.md/CONTEXT.md/REFERENCES.md) plus README/.gitignore/decisions, conditional Code-Tooling-Skelett (Python/Node-TS/Rust/Go), Idempotenz/Konflikt-Verhalten, Auto-Review der CLAUDE.md via /claudemd-optimize. Triggert bei "neues Projekt", "Projekt anlegen", "Projekt starten", "scaffold", "bootstrap", "spark", "Projekt-Start", "Grundgeruest", "kick off", "neues Repo". Folgt dem TIEFEN-PRINZIP: Genanntes wird in der Struktur sichtbar, Spekulatives weggelassen.
---

# Spark — Projekt-Start mit Tiefe (Schleifstein-Edition)

**Spark ist Quality-First Bootstrap** — Schleifstein am Tag 1, nicht Speed-MVP.
Fuer schnelles Feature-Validieren ohne Anchor-Fragen: `/gsd-new-project`.

Ein Projekt-Bootstrap-Tool das aus einer Beschreibung (oder 3 Fragen) eine
intelligent abgeleitete Ordnerstruktur baut, drei Excellence-Anchor-Antworten
einbrennt, Craft-Principles als 0er-ADR anlegt, das Pflicht-Trio plus README,
.gitignore und decisions/ erstellt, optional Code-Tooling-Skelett, idempotent
gegen Re-Runs/Migration und mit Auto-Review der CLAUDE.md.

**Zweck:** Maximaler Qualitaets-Schliff am Tag 1. Die Axt scharf machen,
bevor gehackt wird.

## TIEFEN-PRINZIP (Kern-Regel)

Unterthemen die der User nennt — in jeder Form (Bullets, Kommas, Prosa) und
Anzahl (eines, zwei, zehn) — sind **Spezifikation**, nicht Stichworte. Sie
muessen in der Struktur sichtbar werden:

- **0 Unterthemen, Bereich nur abstrakt erschlossen** → weglassen
- **0 Unterthemen, Bereich explizit genannt** → leerer Ordner
- **1+ Unterthemen, je ein Konzept-Dokument** → Bereichs-`CLAUDE.md`
- **1+ Unterthemen, je mehrere Artefakte** (Templates/Varianten/Beispiele in
  Mehrzahl) → Bereichs-`CLAUDE.md` plus Sub-Ordner pro Thema

"Im Zweifel weglassen" gilt nur fuer **Spekulatives**. Genanntes wird immer
abgebildet, auch bei nur einem Unterthema.

## Phase 0 — Modus erkennen

### 0.1 Eingangs-Erkennung (kein Frage-Reflex)

Pruefe die User-Eingabe nach `/spark` oder dem Trigger-Satz:

- **Reichhaltig** (≥200 Zeichen UND ≥1 Tool/Service/Audience genannt UND ≥1
  Verb-Aktivitaet) → direkt zu Phase 1, **keine Interview-Fragen**
- **Knapp** (<200 Zeichen oder fehlt Audience/Aktivitaet) → 3-Fragen-Fallback
- **Migrations-Hinweis** im Eingang ("bestehend", "existing", "migration",
  "vorhandenes") → Migrations-Modus aktivieren

### 0.2 3-Fragen-Fallback (nur bei knapper Eingabe)

In EINEM Block nummeriert stellen, alle drei zusammen:

> 1. Was baust du genau und fuer wen? (2-4 Saetze, Problem + Zielgruppe)
> 2. Welche Tools/Plattformen/Services spielen rein? (Liste oder "keine")
> 3. Welche 2-5 regelmaessigen Taetigkeiten passieren im Projekt?

Bei Migrations-Modus zusaetzlich: "Pfad des bestehenden Ordners?"

### 0.3 Modus festlegen

- **Neu**: Zielordner wird angelegt, Trio + README + .gitignore + decisions
- **Migration**: Code/Dateien unangetastet, nur Pflicht-Files + ggf. Sub-
  Ordner-Skelett werden hinzugefuegt (siehe Phase 3.0 Konflikt-Verhalten)

## Phase 1 — Tiefen-Pruefung (sichtbar, max 8 Zeilen)

Vor dem Bauen im Output zeigen:

```
TIEFEN-PRUEFUNG
- Top-Level-Bereiche: <name1, name2, ...>
- Pro Bereich Unterthemen: <bereich1: a/b>, <bereich2: ...>
- Tiefen-Entscheidung: <bereich1: flach | bereichs-claude | claude+sub>
- Code-Profil: <python | node-ts | node | rust | go | hybrid | none>
- Annahmen: <max 2 Zeilen, nur falls echt riskant>
```

**Wenn die Eingabe nicht ausreicht** (was wird gebaut, fuer wen, mit welchen
Tools — eines davon fehlt komplett): STOPP. Konkrete Rueckfragen-Liste in
einem Block, nichts anlegen bis Antworten da sind.

## Phase 1.5 — Code-Profil erkennen (conditional)

Aus Beschreibung Sprache/Framework parsen:

- **Python-Signal**: "Python", "FastAPI", "Django", "Flask", "uv", "pytest",
  "Poetry" → Profil `python`
- **Node-Signal**: "Node", "Express", "Next.js", "React", "Vue", "Svelte",
  "Bun", "Deno", "Astro" → Profil `node` (oder `node-ts` wenn TypeScript
  genannt)
- **Rust-Signal**: "Rust", "Cargo", "Axum", "Tokio", "Actix" → `rust`
- **Go-Signal**: "Go", "Golang", "Gin", "Echo", "Fiber" → `go`
- **Mehrsprachig**: mehrere Signale → Profil `hybrid`, pro Sprache eigener
  Top-Level-Ordner (z.B. `backend/` Python, `frontend/` Next.js), Phase 3.5
  laeuft pro Bereich
- **Kein Code-Signal**: Profil `none` → Phase 3.5 ueberspringen

## Phase 1.6 — Excellence-Anchor (Pflicht-Schleifstein, 3 Fragen)

**Zweck:** Die 3 Fragen, die das Qualitaets-Niveau am Tag 1 verankern. Nicht
Risk-Audit, sondern positiver Forcing-Function. Antworten werden Massstab
fuer JEDE spaetere Entscheidung im Projekt.

In EINEM Block nummeriert stellen:

> **Drei Schleifstein-Fragen — werden in CONTEXT.md verankert:**
>
> 1. **Output-Vision.** Wenn das hier in Meisterklasse fertig ist — wie
>    sieht ein einziger Moment damit aus? Keine Beschreibung, ein Bild.
>    Was sieht/erlebt der User konkret?
>
> 2. **Mess-Anker.** An welchen 2-3 konkreten Werken/Produkten/Texten
>    messen wir uns? Nicht "wie Apple" — konkret: "Stripe-Docs Sorgfalt",
>    "McKee-Storytelling-Praezision", "Naval-Tweet-Kompression". Diese
>    werden Massstab fuer JEDE spaetere Entscheidung in diesem Projekt.
>
> 3. **Detail-Beweis.** Was ist das EINE Detail, das wenn es perfekt ist
>    beweist dass wir Meisterklasse erreicht haben? Eines das man
>    sehen/erleben kann — nicht "Feedback ist positiv".

**Skip-Bedingung:** Nur wenn User explizit `--skip-anchor` mitgibt. Sonst
laeuft das IMMER — auch bei reichhaltiger Eingabe. Schleifstein ist nicht
optional.

**Wenn der User pro Frage <30 Zeichen antwortet oder "weiss nicht":**
Kurz nachfragen mit konkretem Beispiel aus aehnlichem Projekt-Typ. Bei
zweitem "weiss nicht": Sektion in CONTEXT.md anlegen mit Marker
`<!-- TODO: Excellence-Anchor — fuellen wenn klar -->` und weitermachen.
Nicht erzwingen wenn der User wirklich noch keinen Klang hat.

## Phase 1.7 — Craft-Principles vorbereiten (extrahieren aus Beschreibung)

Aus Beschreibung + Excellence-Anchor-Antworten 3-5 unverhandelbare
handwerkliche Saeulen extrahieren. Beispiele wie sowas klingt:

- "Das Buch gehoert dem Autor — jede Zeile."
- "Spiegeln statt Ersetzen."
- "Stille waehrend des Schreibens."
- "Authentizitaet > Eleganz."
- "Ehrlichkeit ueber Feature-Reife (experimentell wird als experimentell markiert)."

Wenn aus Beschreibung+Anchor keine 3 Saeulen klar extrahierbar sind: Im
Phase-2-Bestaetigungs-Block dem User die extrahierten Kandidaten zeigen
und fragen "passt das, oder welche Saeulen sind die echten?".

## Phase 2 — Bestaetigung vor Write

```
PROJEKT-VORSCHAU
Name:                <kebab-case>
Zielort:             <pfad>
Bereiche:            <liste mit Tiefen-Marker (flach|claude|claude+sub)>
Pflicht-Files:       CLAUDE.md, CONTEXT.md, REFERENCES.md, README.md,
                     .gitignore, decisions/TEMPLATE.md,
                     decisions/000-craft-principles.md
Excellence-Anchor:   <output-vision (kurz) | mess-anker (kurz) | detail-beweis (kurz)>
Craft-Principles:    <3-5 extrahierte Saeulen>
Code-Tooling:        <profil oder "—">
Optionale:           <ROADMAP.md falls Phasen genannt | -->

Anlegen? (j/n/anpassen)
```

Bei `anpassen`: konkret fragen welche Sektion (Anchor / Principles /
Bereiche / Code).

## Phase 3 — Anlegen (Reihenfolge ist Pflicht)

### 3.0 Konflikt-Verhalten / Idempotenz (Pre-Write-Check)

**Bevor irgendwas geschrieben wird:** pro Pflicht-File pruefen ob Existenz.

| File-Typ | Wenn existiert |
|---|---|
| `CLAUDE.md` / `CONTEXT.md` / `REFERENCES.md` (Haupt) | NIE ueberschreiben. Diff zeigen, fragen "merge / skip / replace" |
| `pyproject.toml` / `package.json` / `Cargo.toml` / `go.mod` | NIE ueberschreiben. Skip mit Hinweis "schon vorhanden" |
| `.gitignore` | Zeilenweise mergen — nur fehlende Standard-Zeilen anhaengen, bestehende unangetastet |
| `decisions/000-craft-principles.md` | Skip wenn vorhanden, nicht ueberschreiben |
| `decisions/TEMPLATE.md` | Skip wenn vorhanden |
| `README.md` | NIE ueberschreiben. Skip oder Diff anbieten |
| `.env.example` | Skip wenn vorhanden |
| Bereichs-`CLAUDE.md` in Unterordner | Skip wenn vorhanden |

**Idempotenz-Garantie:** Zweiter `/spark`-Aufruf darf keinen Schaden
anrichten. Identisches Ergebnis bei identischer Eingabe — ausser dass
existierende Files unangetastet bleiben.

**Bei Konflikten zeigen:**
```
KONFLIKT-CHECK
- CLAUDE.md existiert         → SKIP (User-Action: replace? merge?)
- pyproject.toml existiert    → SKIP
- .gitignore existiert        → MERGE (5 fehlende Zeilen werden angehaengt)
- decisions/                  → existiert (3 ADRs drin) → behalten

Fortfahren? (j/n)
```

### 3.1 Pflicht-Files im Hauptordner

Konkrete Aufbau-Specs aller 7 Pflicht-Files (CLAUDE.md, CONTEXT.md,
REFERENCES.md, README.md, .gitignore, decisions/TEMPLATE.md,
decisions/000-craft-principles.md) liegen in `references/file-specs.md`.

**Vor dem Schreiben dieser Files: `references/file-specs.md` lesen** und
exakt nach Spec befuellen mit Inhalt aus Beschreibung + Excellence-Anchor +
Craft-Principles.

Spec enthaelt: Zeilen-Caps, Pflicht-Sektionen, Frontmatter-Vorgaben,
Goldene Regel ("every line earns its place"), Regeln pro CLAUDE.md,
welche projekt-spezifischen Abweichungen vs Defaults rein duerfen, und
das exakte Template fuer `decisions/000-craft-principles.md`.

### 3.2 Top-Level-Unterordner (kebab-case)

Aus Beschreibung ableiten. Pro Bereich Tiefen-Prinzip anwenden:

- Bereichs-`CLAUDE.md` (max 40 Zeilen):
  - H1 Bereichs-Name + Halbsatz
  - Sektion "Sub-Themen" — eine Zeile pro genanntem Unterthema, mit Pfad
    falls Sub-Ordner und einem Stichwort
  - Sektion "Naechste Schritte" — was pro Sub-Thema entstehen wird (2-3 S.)
  - Optional: "Rules fuer dieses Modul" wenn spezifisch
- KEINE `.gitkeep`-Files. Sub-Ordner bleiben leer.

### 3.3 parent-zone aus Domain-Signal (User wird NICHT gefragt)

Default `products`. Override-Regeln aus Beschreibung:
- "Kunde/Auftraggeber/Client" → `clients`
- "wiederverwendbarer Baustein/Blueprint/Template" → `capital`
- "destilliertes Wissen/Framework/Lessons" → `knowledge`
- "Tool fuer alle Projekte/Chronicle/Automatisierung" → `ops`

(parent-zone optional als Frontmatter in CLAUDE.md, nicht als _meta.yml.)

### 3.4 Optional (du entscheidest pro Projekt, nicht fragen)

- ROADMAP.md → wenn User "Phase", "Meilenstein", "Roadmap", "Sprint" nutzt
- PLAN.md → wenn konkreter Start-Plan angedeutet
- Eigene CONTEXT.md im Unterordner → nur wenn dort eigene Stakeholder

Im Zweifel: weglassen.

## Phase 3.5 — Code-Tooling-Skelett (nur wenn Code-Profil ≠ none)

Konkrete Skelett-Specs pro Sprach-Profil (Python, Node-TS, Node, Rust, Go,
Hybrid) liegen in `references/code-profiles.md`.

**Bei Code-Profil aktiv: `references/code-profiles.md` lesen** und
entsprechendes Profil-Set anlegen. Idempotenz und Konflikt-Verhalten folgen
Phase 3.0 (existierende Configs NIE ueberschreiben).

**Anti-Pattern (Pflicht-Hinweis bleibt hier):** Kein Tool-Init ausfuehren,
keine Dependencies installieren, keine Pakete waehlen — User entscheidet.
Kein CI-Workflow erzeugen.

## Phase 4 — Quality-Gates (alle muessen PASS)

- `grep "<" *.md` → keine `<...>`-Platzhalter-Reste (echte HTML/Inline-Code ok,
  bewusste TODO-Marker `<!-- TODO: ... -->` ok)
- CLAUDE.md ≤ 60 Zeilen, jede Bereichs-CLAUDE.md ≤ 40 Zeilen
- IMPORTANT-Sektion ≤ 3 Regeln, Pflicht-Eintrag `.env` vorhanden
- Alle Pflicht-Files existieren (CLAUDE/CONTEXT/REFERENCES/README/.gitignore/
  decisions/TEMPLATE.md/decisions/000-craft-principles.md)
- **CONTEXT.md hat Frontmatter** mit `last_updated` + `review_after_days`
- **CONTEXT.md hat Sektion "Excellence-Anchor"** (gefuellt oder mit
  bewusstem TODO-Marker)
- **CLAUDE.md hat Living-Doc-Vertrag-Zeile** in Working Preferences
- **CLAUDE.md hat Craft-Principles-Verweis-Zeile**
- **decisions/000-craft-principles.md hat ≥3 Saeulen** (oder bewussten
  TODO-Marker mit Datum bis wann gefuellt)
- Genannte Unterthemen aus Beschreibung sind alle in der Struktur sichtbar
  (Mapping-Check: pro Unterthema ein Eintrag)
- **Bei Code-Profil:** `pyproject.toml`/`package.json`/`Cargo.toml`/`go.mod`
  existiert und ist syntaktisch valides JSON/TOML
- **Bei Code-Profil:** `.env.example` existiert wenn `.env` in `.gitignore`
- **Bei Code-Profil:** README-Setup-Sektion hat ausfuehrbare Befehle
  (keine `<...>`-Platzhalter)

Bei Fehlschlag: konkrete Stelle + Fix zeigen, Phase 4.5 NICHT starten.

## Phase 4.5 — Auto-Review CLAUDE.md (Pflicht)

```
Skill(skill: "claudemd-optimize", args: "<forward-slash-pfad-zur-CLAUDE.md>")
```

Pfad-Normalisierung: Backslashes durch Forward-Slashes ersetzen.

Output parsen: Anzahl Befunde + Top 3 in einem Satz. Vollstaendiger Report
intern halten fuer optionale Volltext-Ausgabe.

**Fail-loud bei Problemen:** Skill-Tool-Call fehl → manueller Befehl
`/claudemd-optimize <pfad>` zeigen. Kein Inline-Fallback-Review.
**Kein Auto-Fix.** User entscheidet ob er Vorschlaege anwendet.

## Phase 5 — Abschluss-Output

```
Projekt angelegt: <absoluter Pfad>

BAUM (2 Ebenen tief)
<projekt>/
  CLAUDE.md
  CONTEXT.md
  REFERENCES.md
  README.md
  .gitignore
  decisions/
    TEMPLATE.md
    000-craft-principles.md
  <bereich1>/
    CLAUDE.md
    <sub-thema>/
  <bereich2>/

MAPPING (User-Unterthema → Ort)
- <unterthema-1>  →  <bereich>/<ort>
- <unterthema-2>  →  <bereich>/<ort>

EXCELLENCE-ANCHOR (in CONTEXT.md verankert)
- Output-Vision: <kurz>
- Mess-Anker:    <kurz>
- Detail-Beweis: <kurz>

CRAFT-PRINCIPLES (in decisions/000-craft-principles.md)
- <Saeule 1>
- <Saeule 2>
- <Saeule 3>

Annahmen (max 3, nur falls riskant):
- <annahme>

Code-Tooling: <profil + Liste angelegter Configs, oder "—">

Konflikt-Check: <skipped 2 files | clean>

Review CLAUDE.md: <N Hinweise. Top 3 oder "sauber">
Vollstaendigen Report sehen? (j/n)

Naechster Schritt fuer dich:
1. Excellence-Anchor in CONTEXT.md reviewen — passen die 3 Antworten noch?
2. Craft-Principles in decisions/000 reviewen — sind das die echten Saeulen?
3. CONTEXT.md "Aktueller Stand" — erster Satz nach Tag-1
4. <bei Code-Profil: Setup-Befehl aus README ausfuehren>
5. git init && git add . && git commit -m "init: <name>"

Brauchst du jetzt einen Fahrplan (Requirements + Phasen + Roadmap)?
Dann `/gsd-new-project` starten. Nicht Pflicht.
```

## Anti-Patterns (vermeiden)

- Platzhalter-Reste `<...>` stehen lassen (ausser bewusste TODO-Marker)
- IMPORTANT-Sektion mit >3 Regeln (Inflation)
- File-Beschreibungen statt Themen-Anker in Bereichs-CLAUDE.md
- `.gitkeep` anlegen
- 7 Einzelfragen-Interview wenn Eingabe schon reicht
- Auto-Review skippen (Phase 4.5 ist Pflicht ausser bei Phase-4-Fehler)
- **Excellence-Anchor skippen** — laeuft IMMER (ausser `--skip-anchor`)
- **Craft-Principles weglassen** — Pflicht-File `decisions/000-craft-principles.md`
- **Bestehende Files ueberschreiben** — siehe Phase 3.0 Konflikt-Verhalten
- User nach parent-zone fragen — wird abgeleitet
- Mehrere `.gitignore` in Subfolders — genau EINS im Root (Ausnahme: hybrid
  mit getrennten Sprach-Ordnern darf eigene haben)
- Spekulative Bereiche/Ordner anlegen die der User nicht genannt hat
- Tiefen-Pruefung-Output >8 Zeilen aufblaehen
- Tool-Init ausfuehren (`npm install`, `uv sync`, `cargo build`)
- Dependencies pre-waehlen — User entscheidet
- CI-Workflows erzeugen — User entscheidet ob/wann
- **Risk-Framing** (Pre-Mortem, "was kann schiefgehen", riskanteste Annahmen)
  — `/spark` ist Schleifstein, nicht Risk-Audit. Excellence-Anchor stellt
  positive Forcing-Fragen ueber die Spitze, nicht ueber die Falle.

## ABBRUCH-Kriterien

Wenn aus der Beschreibung NICHT erkennbar ist *was* gebaut wird, *fuer wen*,
oder *welche Tools* relevant sind: NICHTS anlegen. Konkrete Rueckfragen-Liste
in einem nummerierten Block. Erst nach Klaerung weiterarbeiten.

Wenn ein Bereich Unterthemen hat und du nicht entscheiden kannst ob nur
Bereichs-CLAUDE.md oder zusaetzlich Sub-Ordner: NICHT raten. Frag in der
Rueckfragen-Liste welche Variante.

Wenn bei Code-Profil mehrere Sprachen genannt sind aber unklar ist welche
Top-Level-Ordner welche Sprache bekommt: NICHT raten. Frag konkret.

Wenn Excellence-Anchor-Antworten zweimal "weiss nicht" sind: nicht erzwingen.
TODO-Marker setzen, weiterarbeiten — der Anchor wird nachgereicht wenn der
User Klang findet.
