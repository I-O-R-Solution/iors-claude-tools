---
name: spark
description: Legt ein neues Projekt mit intelligenter Tiefen-Ableitung an — adaptive Eingabe (freie Beschreibung ODER kombinierter Frage-Block), Excellence-Anchor (3 Schleifstein-Fragen), Craft-Principles als 0er-ADR, Migrations-Modus mit Evidenz-Scan des bestehenden Ordners, Living-Doc-Vertrag, Pflicht-Files (AGENTS.md als Substanz + CLAUDE.md-Pointer + CONTEXT.md/REFERENCES.md) plus README/.gitignore/decisions, conditional Code-Tooling-Skelett (Python/Node-TS/Rust/Go), Idempotenz/Konflikt-Verhalten, deterministische Quality-Gates via scripts/verify.sh, Auto-Review der AGENTS.md via /claudemd-optimize, optionaler git init mit Zustimmung. Triggert bei "neues Projekt", "Projekt anlegen", "Projekt starten", "scaffold", "bootstrap", "spark", "Projekt-Start", "Grundgeruest", "kick off", "neues Repo". Folgt dem TIEFEN-PRINZIP: Genanntes wird in der Struktur sichtbar, Spekulatives weggelassen.
---

# Spark — Projekt-Start mit Tiefe (Schleifstein-Edition)

**Spark ist Quality-First Bootstrap** — Schleifstein am Tag 1, nicht Speed-MVP.

Ein Projekt-Bootstrap-Tool das aus einer Beschreibung (oder 3 Fragen) eine
intelligent abgeleitete Ordnerstruktur baut, drei Excellence-Anchor-Antworten
einbrennt, Craft-Principles als 0er-ADR anlegt, AGENTS.md (Substanz) mit
CLAUDE.md-Pointer plus CONTEXT.md, REFERENCES.md, README, .gitignore und
decisions/ erstellt, optional Code-Tooling-Skelett, idempotent
gegen Re-Runs/Migration und mit Auto-Review der AGENTS.md.

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
  Verb-Aktivitaet) → direkt zu Phase 1, **keine Basis-Fragen** (die
  Schleifstein-Fragen aus Phase 1.6 laufen trotzdem)
- **Knapp** (<200 Zeichen oder fehlt Audience/Aktivitaet) → kombinierter
  Frage-Block (0.2)
- **Migrations-Hinweis** im Eingang ("bestehend", "existing", "migration",
  "vorhandenes") → Migrations-Modus aktivieren

### 0.2 Kombinierter Frage-Block (nur bei knapper Eingabe)

ALLE Fragen in EINEM nummerierten Block stellen — die 3 Basis-Fragen UND die
3 Schleifstein-Fragen aus Phase 1.6. Kein zweiter Frage-Durchgang spaeter:
bei knapper Eingabe ist DIES der einzige Ping-Pong.

> 1. Was baust du genau und fuer wen? (2-4 Saetze, Problem + Zielgruppe)
> 2. Welche Tools/Plattformen/Services spielen rein? (Liste oder "keine")
> 3. Welche 2-5 regelmaessigen Taetigkeiten passieren im Projekt?
> 4.-6. Die drei Schleifstein-Fragen — Output-Vision, Mess-Anker,
>    Detail-Beweis (Wortlaut aus Phase 1.6 uebernehmen)

Bei Migrations-Modus zusaetzlich: "Pfad des bestehenden Ordners?"
Bei `--skip-anchor`: nur Fragen 1-3.

### 0.3 Modus festlegen

- **Neu**: Zielordner wird angelegt, Trio + README + .gitignore + decisions
- **Migration**: Code/Dateien unangetastet, nur Pflicht-Files + ggf. Sub-
  Ordner-Skelett werden hinzugefuegt (siehe Phase 3.0 Konflikt-Verhalten)

### 0.4 Evidenz-Scan (nur Migrations-Modus, read-only)

Vor der Tiefen-Pruefung den bestehenden Ordner scannen — nichts schreiben:

- Config-Files suchen (`pyproject.toml`, `package.json` + `tsconfig.json`,
  `Cargo.toml`, `go.mod`) → Code-Profil aus Evidenz ableiten. **Bei Konflikt
  mit der Beschreibung gilt die Evidenz** — was auf der Platte liegt, stimmt.
- Vorhandene README/Docs lesen → Kandidaten fuer CONTEXT.md "Worum geht es"
- Top-Level-Ordner erfassen → als bestehende Bereiche in die Tiefen-Pruefung
  uebernehmen (werden NICHT neu angelegt, nur gemappt)

Ergebnis sichtbar zeigen, max 4 Zeilen:

```
EVIDENZ-SCAN
- Code-Profil: node-ts (package.json + tsconfig.json gefunden)
- Doku: README.md vorhanden → fliesst in CONTEXT.md-Vorbefuellung
- Bestehende Bereiche: src/, docs/, scripts/
```

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

**Wenn die Fragen schon in Phase 0.2 mitgestellt wurden** (knappe Eingabe):
NICHT wiederholen — Antworten von dort verwenden, direkt weiter zu 1.7.
Sonst (reichhaltige Eingabe) in EINEM Block nummeriert stellen:

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
Pflicht-Files:       AGENTS.md (Substanz), CLAUDE.md (Pointer), CONTEXT.md,
                     REFERENCES.md, README.md, .gitignore,
                     decisions/TEMPLATE.md, decisions/000-craft-principles.md
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
| `AGENTS.md` / `CONTEXT.md` / `REFERENCES.md` (Haupt) | NIE ueberschreiben. Diff zeigen, fragen "merge / skip / replace" |
| `CLAUDE.md` (Root) ist bereits der 1-Zeilen-Pointer `@AGENTS.md` | Skip — schon konvertiert |
| `CLAUDE.md` (Root) traegt Substanz (Migration/Alt-Bestand) | NIE auto-konvertieren. Diff zeigen, fragen: "Inhalt nach AGENTS.md verschieben + CLAUDE.md wird Pointer?" Bei Nein: unangetastet lassen (Claude liest die Substanz-CLAUDE.md weiter; Pointer-Gate = SKIP) |
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
- CLAUDE.md traegt Substanz   → FRAGE (Inhalt → AGENTS.md + Pointer?)
- pyproject.toml existiert    → SKIP
- .gitignore existiert        → MERGE (5 fehlende Zeilen werden angehaengt)
- decisions/                  → existiert (3 ADRs drin) → behalten

Fortfahren? (j/n)
```

### 3.1 Pflicht-Files im Hauptordner

Konkrete Aufbau-Specs aller 8 Pflicht-Files (AGENTS.md, CLAUDE.md-Pointer,
CONTEXT.md, REFERENCES.md, README.md, .gitignore, decisions/TEMPLATE.md,
decisions/000-craft-principles.md) liegen in `references/file-specs.md`.

**Vor dem Schreiben dieser Files: `references/file-specs.md` lesen** und
exakt nach Spec befuellen mit Inhalt aus Beschreibung + Excellence-Anchor +
Craft-Principles.

Spec enthaelt: Zeilen-Caps, Pflicht-Sektionen, Frontmatter-Vorgaben,
Goldene Regel ("every line earns its place"), Regeln pro Instruktionsdatei,
welche projekt-spezifischen Abweichungen vs Defaults rein duerfen, und
das exakte Template fuer `decisions/000-craft-principles.md`.

**Das Pointer-Muster ist offiziell gedeckt — nicht "wegoptimieren".** Claude
Code liest `CLAUDE.md`, NICHT `AGENTS.md`. Anthropic empfiehlt fuer Repos, die
`AGENTS.md` fuer andere Coding-Agents nutzen, ausdruecklich eine `CLAUDE.md`,
die sie importiert — damit beide Werkzeuge dieselbe Quelle lesen, ohne
Duplikat. Unter **Windows** ausdruecklich der `@AGENTS.md`-Import statt eines
Symlinks (Symlink braucht dort Admin-Rechte oder Developer Mode). Genau das
baut spark. Wer den Pointer entfernt, macht die Datei fuer Claude Code
unsichtbar.
<!-- Beleg: code.claude.com/docs/en/memory#agents-md, geprueft 2026-08-13. -->

**Budget-Rechnung ehrlich halten:** Der Import spart keinen Kontext — er wird
beim Launch vollstaendig expandiert. AGENTS.md + CLAUDE.md-Pointer kosten
zusammen so viel wie eine einzige Datei gleicher Laenge. Der Gewinn ist
Werkzeug-Unabhaengigkeit und Ordnung, nicht Budget. Anthropics Zielmarke sind
**unter 200 Zeilen pro Instruktionsdatei**; sparks 60-Zeilen-Cap fuer AGENTS.md
ist bewusst strenger und bleibt der Massstab.
<!-- Beleg: memory.md#write-effective-instructions ("target under 200 lines per CLAUDE.md file") + #import-additional-files. -->

Echte Budget-Entlastung gibt es nur ueber `paths:`-Rules (Phase 3.2), Skills
und Hooks — nicht ueber weitere `@`-Imports.

**Bei Unsicherheit ueber Ton oder Tiefe der Inhalte:**
`references/example-run.md` lesen — ein kompletter Gold-Standard-Durchlauf
als Massstab. Nicht kopieren, kalibrieren.

### 3.2 Top-Level-Unterordner (kebab-case)

Aus Beschreibung ableiten. Pro Bereich Tiefen-Prinzip anwenden:

- Bereichs-`CLAUDE.md` (max 40 Zeilen):
  - H1 Bereichs-Name + Halbsatz
  - Sektion "Sub-Themen" — eine Zeile pro genanntem Unterthema, mit Pfad
    falls Sub-Ordner und einem Stichwort
  - Sektion "Naechste Schritte" — was pro Sub-Thema entstehen wird (2-3 S.)
  - Optional: "Rules fuer dieses Modul" wenn spezifisch
- KEINE `.gitkeep`-Files. Sub-Ordner bleiben leer.

**Zwei Lade-Mechanismen — den richtigen waehlen (nicht beide fuer dasselbe):**

| Regel haengt an … | Ablage | Laedt |
|---|---|---|
| einem **Ordner** ("wenn hier gearbeitet wird") | `<bereich>/CLAUDE.md` | sobald Claude eine Datei in diesem Ordner liest |
| einem **Dateityp oder Glob** ("alle `*.test.ts`", "alles unter `src/api/`") | `.claude/rules/<thema>.md` mit `paths:`-Frontmatter | sobald Claude eine matchende Datei liest — ordnerunabhaengig |

Beides laedt on-demand und belastet das Always-On-Budget nicht. `.claude/rules/`
nur anlegen, wenn der User Regeln nennt, die an Dateitypen statt an Ordnern
haengen — kein leeres `rules/`-Verzeichnis auf Vorrat (Spekulatives weglassen).
Frontmatter-Form:

```
---
paths:
  - "src/api/**/*.ts"
---
```

Rules OHNE `paths:` laden unconditional beim Launch und zaehlen voll zum
Budget — in `spark`-Projekten deshalb nie ohne `paths:` anlegen; unbedingte
Regeln gehoeren in AGENTS.md.
<!-- Beleg: code.claude.com/docs/en/memory#path-specific-rules + #how-claude-md-files-load, geprueft 2026-08-13. -->

**Warnung fuer den Bereichs-CLAUDE.md-Pfad:** Nach `/compact` wird nur die
Root-CLAUDE.md neu von Platte eingespielt. Bereichs-Files und `paths:`-Rules
kommen erst zurueck, wenn dort wieder gelesen wird. Was ausnahmslos gelten
muss, gehoert deshalb nach AGENTS.md (Root) oder in einen Hook — nicht in eine
Bereichs-CLAUDE.md.

### 3.3 parent-zone aus Domain-Signal (User wird NICHT gefragt)

Default `products`. Override-Regeln aus Beschreibung:
- "Kunde/Auftraggeber/Client" → `clients`
- "wiederverwendbarer Baustein/Blueprint/Template" → `capital`
- "destilliertes Wissen/Framework/Lessons" → `knowledge`
- "Tool fuer alle Projekte/Chronicle/Automatisierung" → `ops`

(parent-zone optional als Frontmatter in AGENTS.md, nicht als _meta.yml.)

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

### 4.1 Mechanische Gates — Verifier-Script (deterministisch)

```
bash ~/.claude/skills/spark/scripts/verify.sh "<projekt-pfad>" [<code-profil>]
```

Prueft pro Gate mit PASS/FAIL/SKIP:
- Alle Pflicht-Files existieren (AGENTS/CLAUDE-Pointer/CONTEXT/REFERENCES/
  README/.gitignore/decisions/TEMPLATE.md/decisions/000-craft-principles.md)
- AGENTS.md ≤ 60 Zeilen, jede Bereichs-CLAUDE.md ≤ 40 Zeilen
- CLAUDE.md-Pointer-Integritaet (exakt `@AGENTS.md`; unkonvertierter
  Migrations-Bestand mit Substanz-CLAUDE.md → SKIP, nicht FAIL)
- Platzhalter-Scan **rekursiv ueber alle .md** — keine `<...>`-Reste.
  Ausnahmen: `decisions/TEMPLATE.md` (Platzhalter sind dort Spec) und
  bewusste `<!-- TODO: ... -->`-Marker
- CONTEXT.md-Frontmatter (`last_updated` + `review_after_days`) und
  Sektion "Excellence-Anchor"
- AGENTS.md hat Living-Doc-Anker (`spark:living-doc`) + Craft-Anker
  (`spark:craft`) — Wortlaut der Zeilen ist frei, die Anker sind Pflicht
- decisions/000-craft-principles.md hat ≥3 Saeulen (oder TODO-Marker)
- Bei Code-Profil: Config existiert (`pyproject.toml`/`package.json`/
  `Cargo.toml`/`go.mod`), `package.json` JSON-valide, `.env.example`
  existiert wenn `.env` in `.gitignore` (Validierung ohne verfuegbares
  Tool → SKIP, nicht raten)

Script-Output im Chat zeigen. **Wenn das Script fehlt oder crasht:**
fail-loud melden und die Gates oben als manuelle Checkliste durchgehen —
kein stilles Skippen.

### 4.2 Semantische Gates (LLM-Check, Script kann sie nicht pruefen)

- Genannte Unterthemen aus Beschreibung sind alle in der Struktur sichtbar
  (Mapping-Check: pro Unterthema ein Eintrag)
- IMPORTANT-Sektion ≤ 3 Regeln. Die `.env`-Pflicht-Zeile NUR bei Code-Profil
  ≠ none oder wenn Secrets/APIs vorkommen — bei reinen Doku-/Wissensprojekten
  entfaellt sie (kein Noise)
- Bei Code-Profil: README-Setup-Sektion hat ausfuehrbare Befehle
  (keine `<...>`-Platzhalter)

Bei Fehlschlag: konkrete Stelle + Fix zeigen, Phase 4.5 NICHT starten.

## Phase 4.5 — Auto-Review AGENTS.md (Pflicht)

```
Skill(skill: "claudemd-optimize", args: "<forward-slash-pfad-zur-AGENTS.md>")
```

Immer den AGENTS.md-Pfad uebergeben, NIE die Pointer-CLAUDE.md (die hat
nur eine Zeile — das Review liefe leer).

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
  AGENTS.md
  CLAUDE.md          (Pointer: @AGENTS.md)
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

Review AGENTS.md: <N Hinweise. Top 3 oder "sauber">
Vollstaendigen Report sehen? (j/n)

Naechster Schritt fuer dich:
1. In der ersten Session im Projekt `/context` laufen lassen und unter
   **Memory files** pruefen, ob CLAUDE.md (und damit AGENTS.md) wirklich
   geladen ist. Steht sie nicht dort, sieht Claude sie nicht — dann stimmt
   Ablageort oder Import. Diese eine Messung ersetzt jede Annahme.
2. Excellence-Anchor in CONTEXT.md reviewen — passen die 3 Antworten noch?
3. Craft-Principles in decisions/000 reviewen — sind das die echten Saeulen?
4. CONTEXT.md "Aktueller Stand" — erster Satz nach Tag-1
5. <bei Code-Profil: Setup-Befehl aus README ausfuehren>

Git: Soll ich git init + Initial-Commit ("init: <name>") jetzt machen? (j/n)

Brauchst du jetzt einen Fahrplan (Requirements + Phasen + Roadmap)?
Dann `/konzept` fuer die Denkarbeit, `/route` fuer den Bau. Nicht Pflicht.
```

**git-init-Frage:** nur im Neu-Modus stellen. Bei `j` ausfuehren
(`git init && git add . && git commit -m "init: <name>"`), bei `n` den
Befehl als Anleitung stehen lassen. Im Migrations-Modus NIE — bestehendes
Repo/Historie nicht anfassen, Frage entfaellt komplett.

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
- Mehrere `.gitignore` — genau EINS im Root, auch bei hybrid (das Root-File
  sammelt alle Sprach-Ignores, keine eigenen in Sprach-Ordnern). Diese Zeile
  ist die einzige Quelle der Regel — file-specs/code-profiles verweisen hierher
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
Ein explizites "keine Tools" ist eine gueltige Antwort — kein Abbruch.

Wenn ein Bereich Unterthemen hat und du nicht entscheiden kannst ob nur
Bereichs-CLAUDE.md oder zusaetzlich Sub-Ordner: NICHT raten. Frag in der
Rueckfragen-Liste welche Variante.

Wenn bei Code-Profil mehrere Sprachen genannt sind aber unklar ist welche
Top-Level-Ordner welche Sprache bekommt: NICHT raten. Frag konkret.

Wenn Excellence-Anchor-Antworten zweimal "weiss nicht" sind: nicht erzwingen.
TODO-Marker setzen, weiterarbeiten — der Anchor wird nachgereicht wenn der
User Klang findet.
