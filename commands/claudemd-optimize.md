---
description: Review einer CLAUDE.md — kompakter Befund mit konkreten Aktionen, max 80 Zeilen Output
argument-hint: [pfad|global]
---

Du bist ein CLAUDE.md Optimierungs-Experte. Dein Job: Eine einzelne CLAUDE.md
systematisch reviewen und **knapp** ruecklieferen — ohne Auto-Fix.

**Mantras (in dieser Reihenfolge anwenden):**
1. *"Every line earns its place."* — Boris Cherny, Creator Claude Code
2. *"For each line, ask: Would removing this cause Claude to make mistakes? If not, cut it."* — Anthropic Best-Practices (Golden-Rule-Test)
3. *"The model should never be the sole enforcer of its own constraints."* — GitHub Issue #32193

Du bewertest aus diesen drei Saetzen heraus. Nicht "ist das informativ?",
sondern "wuerde Claude ohne diese Zeile einen Fehler machen, und ist die
Regel ueberhaupt durchsetzbar wo sie steht?"

Antworte in der Sprache des Users. Technische Begriffe bleiben englisch.

Ziel-Datei: $ARGUMENTS

## Schritt 1: Ziel-Datei bestimmen

- Kein Argument → `./CLAUDE.md` im cwd
- Argument = `global` → `~/.claude/CLAUDE.md`
- Argument = absoluter Pfad → diese Datei
- Argument = relativer Pfad → relativ zum cwd
- Forward-Slashes (Bash unter Windows)
- Datei fehlt → STOPPE: "Datei nicht gefunden: [pfad]. Gib keinen Parameter
  (= ./CLAUDE.md), 'global' oder validen Pfad an."
- Datei-Name ist nicht `CLAUDE.md`, `CLAUDE.local.md` oder `AGENTS.md` →
  STOPPE: "Dieser Skill reviewt nur CLAUDE.md-/AGENTS.md-Files. Fuer andere
  Files: /prompt-audit nutzen." (AGENTS.md ist der spark-Standard: Substanz
  dort, CLAUDE.md daneben ist nur der 1-Zeilen-Pointer `@AGENTS.md`.)

**Disambiguierung bei tiefer Verschachtelung:** Vor dem Lesen der Ziel-Datei
einmal vom Ziel-Datei-Ordner bis Filesystem-Root walken und ALLE
`CLAUDE.md`-Files auf dem Weg listen (Bash: `ls` pro Ebene). Wenn mehr als
eine gefunden wird UND der User kein explizites Argument gegeben hat:
listen, fragen *"welche reviewen?"*, dann fortfahren. Verhindert dass eine
tieferliegende CLAUDE.md still uebersehen wird.

**Rolle der Ziel-Datei bestimmen** (steuert Schritt 5, kein eigener Output). Der
Walk-up aus Schritt 3 liefert die Antwort ohne zusaetzlichen Tool-Call:

- **Wurzel-Datei** — `~/.claude/CLAUDE.md` (global) oder die `CLAUDE.md`/`AGENTS.md` im
  Projekt-Root (die oberste Ebene mit `.git`, sonst der Ordner, ab dem der Walk-up nur
  noch fremde Projekte findet)
- **Bereichs-Datei** — jede `CLAUDE.md` unterhalb dieses Projekt-Roots

Die Rolle entscheidet, was ueberhaupt hineingehoert. Beide Sorten werden hier geprueft,
aber gegen verschiedene Massstaebe.

Lies die Ziel-Datei KOMPLETT mit Read.

## Schritt 2: Metriken

**Schritt 2-5 sind SILENT** — der erste Output ist der Report in Schritt 6.
Aus Schritt 1 sind nur STOPPE-Meldung und Disambiguierungs-Frage erlaubt.

Per Bash (`wc -l`) oder Lesen: Zeilen, Bullets, Sections.
Frontmatter pruefen (falls vorhanden): `paths:` (on-demand-Loading?), `description:` (pruegnant?).

## Schritt 3: Hierarchie-Last + Strukturelle Fallen

Ebenen ADDIEREN sich. Bestimme den vollstaendigen Always-On-Stack via **Walk-up**:

1. Start: Ordner der Ziel-Datei
2. Walk up bis Filesystem-Root: jede `CLAUDE.md` auf dem Weg in den Stack —
   egal wie tief die Ziel-Datei liegt (Ebene 2, 3, 4, 7), **alle** Zwischen-CLAUDE.md zaehlen.
   **Dedup-Regel:** Eine Pointer-CLAUDE.md (Inhalt = nur `@AGENTS.md` o. ae.
   Import) zaehlt als ihr Import-Ziel, nicht zusaetzlich — sonst werden
   dieselben Zeilen doppelt ins Budget gerechnet
3. Plus `~/.claude/CLAUDE.md` und alle Files in `~/.claude/rules/*.md` (Glob) —
   laedt der Harness automatisch, KEIN Import-Statement noetig
4. Plus `@path`-Imports jeder dieser Files (rekursiv, eine Tiefe)
5. Geschwister-Subdir-CLAUDE.md zaehlen NICHT — nur die Hierarchie Ziel → parent → ... → global

Lies alle relevanten Files per Read/Glob, summiere Zeilen UND geschaetzte Instructions (Zeilen × 0.6, gerundet — Headers/Leerzeilen wiegen weniger als Regel-Bullets).

**Accuracy-Zonen** — primaer auf Instructions bewerten, Zeilen nur als Sekundaer-Indikator.

<!-- Quellen: Anthropic Docs (code.claude.com/docs/en/memory, /best-practices, /context-window) + Jaroslawicz et al. arxiv 2507.11538 (Juli 2025, Compliance vs. Instruction-Count gemessen) + Lakshminp-Benchmark April 2026 + Stulberg April 2026. Zeilen-Spalte ist Faustregel via Faktor 0.6. -->

| Instructions | Zeilen-Faustregel | Compliance | Zone |
|--------------|-------------------|------------|------|
| < 35 | < 60 | ~85-90% | optimal |
| 35-60 | 60-100 | ~80-85% | Sweet Spot (Cherny ~100-Zeilen-Workflow) |
| 60-120 | 100-200 | ~70-80% | Anthropic-Maximum (offizielle Schranke pro File) |
| 120-300 | 200-500 | ~50-65% | Accuracy faellt deutlich |
| 300+ | 500+ | ~30-50% | kontraproduktiv (leere Datei waere besser) |

**Slot-Budget:** ~50 Slots belegt System-Prompt, ~100 Slots fuer eigene
Anweisungen verfuegbar. Slots = Instructions-Schaetzung (derselbe Faktor 0.6).
Warnen bei >100, kritisch >150.

**Anthropic-Original-Schranke:** *"target under 200 lines per CLAUDE.md file"*
gilt **pro File**, nicht fuer die Summe. Single-File-Zone und Hierarchie-Zone
getrennt bewerten.

**Strukturelle Fallen explizit pruefen:**

- **Bereichs-Datei ist nicht always-on:** Eine `CLAUDE.md` im Unterordner laedt ueberhaupt erst, wenn Claude dort eine Datei liest — nicht beim Start. Nach `/compact` verschwindet sie wieder, zusammen mit allen `paths:`-Rules, und kommt erst beim naechsten Lesen zurueck. Zweimal derselbe Ausgang, nicht zwei Probleme. Folge: Eine Regel, die ausnahmslos gelten muss, ist hier falsch platziert — flaggen und auf die Verbindlichkeits-Leiter in Schritt 5 verweisen. Niemals `@`-Import als Ausweg empfehlen (spart nichts, siehe naechster Punkt).
  <!-- Beleg: memory.md#how-claude-md-files-load — "Instead of loading them at launch, they are included when Claude reads files in those subdirectories"; memory.md#compaction — "Nested CLAUDE.md files in subdirectories and rules with paths: frontmatter are not re-injected automatically". Deckungsgleich mit spark/SKILL.md:340. Umgebaut 2026-08-14 — vorher argumentierte der Punkt nur ueber /compact und empfahl @-Import. -->
- **`@`-Import kostet vollen Kontext, spart keinen:** Importierte Files werden beim Launch expandiert und vollstaendig ins Fenster geladen. Aufteilen schafft Ordnung, KEIN Budget. Wer Kontext sparen will, braucht `paths:`-Rules (on-demand), Skills (on-demand) oder Markdown-Links (laden gar nicht). Max Import-Tiefe: 4 Hops. Imports in Backticks werden nicht aufgeloest.
  <!-- Beleg: memory.md#import-additional-files — "Imported files are expanded and loaded into context at launch"; memory.md#my-claude-md-is-too-large — "Splitting into @path imports helps organization but doesn't reduce context". -->
- **`@`-Pfad-Aufloesung:** Relative `@path`-Imports loesen **relativ zur importierenden Datei** auf, nicht zum Workspace-Root. Absolute Pfade und `~/`-Pfade sind erlaubt. Ein Import, dessen Pfad ausserhalb des Working Directory landet (z.B. `@~/.claude/x.md` in einer Projekt-CLAUDE.md), ist ein *external import*: beim ersten Auftreten zeigt Claude Code einen Approval-Dialog; wird er abgelehnt, bleiben die Imports dauerhaft aus. Bei User-Scope-Files (`~/.claude/CLAUDE.md`, `~/.claude/rules/`) entfaellt der Dialog.
  <!-- Beleg: memory.md#import-additional-files. Korrigiert 2026-08-13 — vorher stand hier faelschlich "Imports werden vom Workspace-Root aufgeloest". -->
- **`.claude/rules/` — der dokumentierte Entlastungs-Mechanismus:** Rules OHNE `paths`-Frontmatter laden unconditional beim Launch (gleiche Prioritaet wie `.claude/CLAUDE.md`) und zaehlen voll zum Always-On-Budget. Rules MIT `paths:`-Frontmatter laden nur, wenn Claude eine matchende Datei liest — das ist laut Doku der offizielle Weg, Instruktionen aus dem Always-On-Budget zu nehmen, ohne sie zu verlieren. User-Level-Rules unter `~/.claude/rules/` gelten fuer alle Projekte und laden VOR den Projekt-Rules (Projekt gewinnt bei Konflikt).
  <!-- Beleg: memory.md#organize-rules-with-claude/rules/ + #path-specific-rules + #user-level-rules. Korrigiert 2026-08-13 — vorher stand hier, paths: werde in ~/.claude/rules/ nicht ausgewertet; das steht so nicht in der Doku. -->
- **Nicht behaupten — messen:** Welche Files in einer Session TATSAECHLICH geladen sind, zeigt `/context` unter **Memory files**. Fuer die Frage *wann und warum* ein File laedt (Debugging von `paths:`-Rules und Lazy-Loading in Subdirs) gibt es den `InstructionsLoaded`-Hook. Widerspricht eine Beobachtung diesem Abschnitt: erst messen, dann diesen Command korrigieren — die Doku ist Primaerquelle, dieser Text ist Sekundaerquelle.

## Schritt 4: Bewertung gegen die 9 Prinzipien

**Prinzip 1 — Laenge ist Accuracy:** Jede unnoetige Zeile schadet allen anderen Regeln gleichmaessig.
<!-- Beleg: Jaroslawicz arxiv 2507.11538 — bei 500 Instructions ~43% Compliance bei Sonnet 4. -->



**Prinzip 2 — Was rein gehoert:** Bash-Befehle die Claude nicht erraten kann; Code-Style-Abweichungen von Defaults; Test-Runner; Repo-Etikette; projekt-spezifische Architektur-Entscheidungen (das WARUM); Gotchas/nicht-offensichtliches Verhalten.

**Prinzip 3 — Was NICHT rein gehoert:** Was Claude aus Code lesen kann; Standard-Konventionen; Selbstverstaendliches; Persona-Zuweisungen; lange Tutorials; Datei-fuer-Datei-Beschreibungen; Inhalte die sich oft aendern.

**Prinzip 4 — Formulierung:** Negativ-Form ("DO NOT X" > "do Y"); Trigger-Action ("When X, do Y"); Emphasis (IMPORTANT/YOU MUST/NEVER) fuer Kritisches — *aber nur fuer 2-3 Regeln, sonst Inflation*; konkret + ueberpruefbar ("2 Spaces" > "schoen formatieren"); `@file`-Pointer/Markdown-Links statt Kopien; Markdown-Bullets statt Prosa.

**Prinzip 5 — Hierarchie:** Ebenen addieren, nicht ersetzen — alle gefundenen Files werden konkateniert, von Filesystem-Root abwaerts zum cwd; naeher am cwd wird zuletzt gelesen, `CLAUDE.local.md` nach `CLAUDE.md` derselben Ebene. Spezifischer schlaegt allgemeiner: Projekt > Global, `.local.md` > `.md`. Rules ohne `paths:` zaehlen voll zum Budget; Rules mit `paths:` nur beim Match (siehe Schritt 3). Entlastungswege in dieser Reihenfolge pruefen: `paths:`-Rule → Skill → Hook (Prinzip 7). In Monorepos koennen fremde Ancestor-CLAUDE.md per `claudeMdExcludes` (Glob, in `.claude/settings.local.json`) ausgeschlossen werden; Managed-Policy-Files sind davon ausgenommen.

**Prinzip 6 — "may-or-may-not"-Problem:** Inhalt kommt als User-Message mit explizitem Hinweis *"may or may not be relevant — should not respond unless highly relevant"*. Anthropic-Framing erlaubt Claude explizit ignorieren. Je laenger, desto mehr wird ignoriert.

**Prinzip 7 — Skills/Hooks > Rules + Zero-Tolerance-Regel:** Skills laden on-demand (-90% Budget vs. Rules-Text laut mindstudio.ai 2026). Hooks sind deterministisch (Harness fuehrt aus, nicht LLM).
- Bei wiederkehrenden Workflows: **Skill** bevorzugen
- Bei Zero-Tolerance-Regeln (irreversibel, Sicherheit, Compliance): **IMMER Hook empfehlen**, niemals nur CLAUDE.md. Anker: GitHub #32193 dokumentiert 13 Verstoesse gegen eine Zero-Tolerance-Regel trotz IMPORTANT-Formatierung. *"The model should never be the sole enforcer of its own constraints."*

**Prinzip 8 — Anti-Patterns + Auto-Generated-Detection:** Style-Guide (gehoert in Linter); Redundanz zu Rules; Personas; nicht-erklaerende Beispiele; Sprach-Mix; Chronicle/Changelog inline; Datei-fuer-Datei-Inventare; Prosa-Wuerste.
- **Auto-Generated-Geruch besonders hart flaggen:** Sektionen wie *"## Common Commands"* mit npm-Defaults oder *"## Architecture"* mit generischer Prosa stammen wahrscheinlich aus naivem `/init` und schaden messbar. Empfehlung: komplett kuratieren oder leeren.
<!-- Beleg: Lakshminp-Benchmark April 2026 — naive /init-Files +20% Inferenz-Kosten + niedrigere Erfolgsrate gegenueber leerer Datei. -->
- **Ordner-Sektion: erst pruefen, dann flaggen.** Eine Sektion ueber die Ordnerstruktur ist NICHT automatisch Auto-Generated-Geruch. **Pruefrage:** Steht neben dem Ort eine Aussage, die man **nicht** aus `ls` ablesen kann — was dort hinein darf, welche Aufgabe dorthin fuehrt, welche Regel dort gilt?
  - **Nein → Inventar.** Datei-fuer-Datei-Liste, spiegelt nur den Ordnerbaum, veraltet beim naechsten `mkdir`. Hart flaggen (Prinzip 3, Lakshminp-Begruendung oben).
  - **Ja → Wegweiser.** Das ist der *Document Index* aus Schritt 5, also das Gegenteil eines Befunds. Stehenlassen, auch wenn er Zeilen kostet. Gilt in **beiden** Rollen: In einer Bereichs-Datei ist eine Karte der *eigenen* Unterordner legitime oertliche Information. Nur flaggen, wenn sie die Uebersicht der Wurzel wiederholt (Schritt 5, "Zu viel").

  Trennlinie an einem Beispiel: `decisions/ — ADRs` ist Inventar. `decisions/ — jede uebernommene oder verworfene Empfehlung, mit Begruendung; hierhin fuehrt "etwas entscheiden"` ist ein Wegweiser.

**Prinzip 9 — Golden-Rule-Test (Anthropic offiziell):** Pro Zeile fragen: *"Wuerde Claude ohne diese Zeile einen Fehler machen?"* Wenn nein → streichen. Ohne Schuldgefuehl, ohne Ersatz. Das ist das primaere Kuerz-Kriterium und schlaegt jede andere Heuristik.

## Schritt 5: Redundanz, Gap, Konstruktive Fixes

**Redundanz:** Lies `~/.claude/rules/*.md` (Glob) + globale CLAUDE.md (bei Projekt/Bereich) + parent (bei Bereichs-Datei). Doppelungen markieren.

**Die Gap-Pruefung haengt an der Rolle aus Schritt 1.** Was in einer Wurzel-Datei fehlt,
ist in einer Bereichs-Datei zu viel. Wer beide gleich prueft, empfiehlt der Haelfte der
Dateien das Falsche.

### Wurzel-Datei (Projekt-Root oder global)

**Stulbergs 4 Pflicht-Kategorien** (nur flaggen wenn fehlend UND projekt-relevant):

1. **Document Index** — Wo liegt was? Ordnerstruktur **mit Erklaerung** (Wegweiser, nicht Inventar — Prinzip 8), MCP-Server, Pointer auf wichtige Files
2. **People** — Namen, Rollen, Beziehungen (damit "Lisa will pushen" ohne Re-Erklaerung verstaendlich ist)
3. **Identity / Goals** — Was ist das, was sind die Ziele, getroffene Entscheidungen
4. **How you want things done** — Workflows, Guardrails, Praeferenzen

**Gap — projekt-spezifische Befehle:** Build/Run/Test/Deploy-Bash, Test-Runner, Branch-Konventionen, Env/Secrets-Handling, Architektur-Why.

### Bereichs-Datei (Unterordner)

Die vier Kategorien gelten hier **nicht** — sie stehen schon in der Wurzel, und die ist
beim Lesen dieser Datei laengst geladen (Prinzip 5: Ebenen addieren sich, sie ersetzen
einander nicht). Stattdessen genau zwei Fragen:

- **Zu viel?** Projekt-Identitaet, Personen, Ordner-Uebersicht oder Regeln, die schon in der Wurzel stehen → streichen. Das ist ein Befund fuer "Was raus oder kuerzer muss", nicht fuer "Was fehlt".
- **Falscher Ort?** Steht hier eine Regel, die **ausnahmslos** gelten muss? Dann ist die Bereichs-Datei falsch, weil sie erst laedt, wenn Claude hier eine Datei liest (Schritt 3). Verbindlichkeits-Leiter:
  1. *muss immer gelten* → Wurzel-Datei oder Rule **ohne** `paths:` — nur diese beiden sind always-on
  2. *gilt nur fuer diesen Bereich, aber verbindlich* → `.claude/rules/<thema>.md` **mit** `paths:`
  3. *darf nie gebrochen werden* → Hook (Prinzip 7)

  Stufe 2 ist **kein** Ersatz fuer Stufe 1: `paths:`-Rules kommen nach `/compact` genauso wenig zurueck wie eine Bereichs-Datei.

Was hier **hin gehoert**: nur die oertliche Abweichung — was in diesem Bereich anders ist
als in der Wurzel, mit dem Warum. Fehlt das und die Datei enthaelt sonst nur Wiederholung,
lautet die richtige Empfehlung "loeschen", nicht "kuerzen".

**Sprach-Konsistenz:** Datei in einer Sprache? "Antworte auf X"-Regel selbst in X formuliert?

**Konstruktive-Fix-Optionen** (statt nur "RAUS"):

- **Volatile/persoenliche Inhalte** (Tagesgeschaeft, Experimente, persoenliche Preferences die nicht ins Team-Repo gehoeren) → **`./CLAUDE.local.md`** vorschlagen (wird zuletzt geladen, gewinnt bei Konflikt, nicht im Git)
- **Maintainer-Notes / Versions-Logs / TODOs an dich selbst** → in **HTML-Block-Kommentare** umbauen (`<!-- ... -->`). Anthropic Docs: *"Block-level HTML comments are stripped before injection"* — kosten 0 Tokens. Statt Loeschen: konstruktiv umbauen.
- **Lange Dokumentation (Architektur, Glossar, Datenmodell)** → auslagern nach `docs/X.md` und als **Markdown-Link** `[Architektur](docs/architektur.md)` einbinden, NICHT als `@`-Import. Ein `@`-Import laedt die Datei beim Launch vollstaendig mit und spart null Budget (Schritt 3); ein Markdown-Link laedt erst, wenn Claude ihn liest. Diese Unterscheidung ist der haeufigste Denkfehler in gewachsenen CLAUDE.md-Setups — explizit ansprechen, wenn du `@docs/`-Pointer findest, die als Sparmassnahme gemeint waren.
- **Instruktionen, die nur fuer einen Teil des Repos gelten** (Frontend-Konventionen, API-Regeln, Test-Vorgaben) → in `.claude/rules/<thema>.md` mit `paths:`-Frontmatter. Laedt nur beim Match, bleibt trotzdem verbindlich. Das ist die einzige Massnahme, die Budget spart, ohne Verbindlichkeit zu verlieren.
- **Wiederkehrende Workflows mit mehreren Schritten** → in einen Skill auslagern
- **Zero-Tolerance-Regeln** → in einen Hook auslagern (Prinzip 7)
- **Bei eingecheckten Projekt-Files zusaetzlich:** `/doctor` schlaegt eigenstaendig Trims vor (schneidet Directory-Layouts, Dependency-Listen und Architektur-Uebersichten weg, behaelt Pitfalls, Rationale und Abweichungen von Defaults) — als Zweitmeinung erwaehnen, nicht als Ersatz fuer diesen Review. Ab Claude Code v2.1.206.

Wenn nichts fehlt: explizit "kein Gap" sagen — nichts erfinden.

## Schritt 6: Output (max 80 Zeilen total)

```
# Review: <pfad>

**<Eine-Zeile-Verdikt>** — <Wurzel-Datei|Bereichs-Datei> — Score X/5 — N Zeilen / ~I Instructions (Zone), Hierarchie-Summe M Z. / ~J Instructions (Zone), ~K Slots

## Was gut ist (nicht anfassen)
- <Section/Aspekt>: <warum>
(max 3 Bullets)

## Was raus oder kuerzer muss
- **<Section-Name>** (N Zeilen): <konkrete Aktion> — <Prinzip #X>
(max 5 Eintraege, sortiert nach Impact, je 1-2 Zeilen. Bei volatilen Inhalten:
.local.md vorschlagen. Bei Maintainer-Notes: HTML-Kommentar vorschlagen.
Bei Zero-Tolerance: Hook vorschlagen. Bei Workflows: Skill vorschlagen.)

## Was fehlt
- <Wurzel-Datei: konkreter Gap aus Stulbergs 4 Kategorien oder projekt-spezifisch.
Bereichs-Datei: nur die fehlende oertliche Abweichung — NIE Identitaet, Personen
oder Ordner-Uebersicht verlangen.>
(oder: "kein Gap")

## Empfehlung
<1-2 Saetze: groesster Hebel zuerst. Bei laufender Maintenance: Cherny-Rhythmus
erwaehnen — "wenn Claude einen Fehler macht, +1 Zeile; alle paar Wochen
Golden-Rule-Test gegen alle Zeilen, was unklar ist, fliegt.">

---
Sag "Setze Empfehlung um" oder "Setze Punkt N um".
Bei mehreren Aenderungen: nach Edits ggf. `/clear` damit neue CLAUDE.md geladen wird.
```

## Schritt 7: Fix (nur nach Freigabe)

Erst wenn der User "Setze Punkt N um" oder "Setze Empfehlung um" sagt:

1. Vorab einmal: `git status --porcelain -- <ziel>` — hat die Ziel-Datei schon
   uncommitted Aenderungen, EINE Warnzeile ("git diff mischt jetzt alte und
   neue Aenderungen"). Ist die Datei gar nicht git-getrackt: warnen, dass es
   kein Rollback gibt, und auf Bestaetigung warten.
2. Ein Punkt = ein Edit. Danach eine Zeile: `fixed: <ziel>:<zeile> — <was>`.
3. Bei mehr als 3 Punkten in einem Rutsch: TodoWrite-Liste, pro Fix abhaken.
4. Danach einmal (nie pro Edit) Commit anbieten — Format nach git-workflow-Skill.
   NIEMALS ungefragt committen.

## Optionaler Anhang — Diagnose-Trick (nur wenn der User berichtet "Claude haelt sich nicht dran")

Wenn der User waehrend des Reviews mitteilt, dass eine konkrete Regel ignoriert wird:

1. Regel aus CLAUDE.md kopieren und als direkte Chat-Message senden
2. Wenn Claude sich jetzt dran haelt → **Lieferweg-Problem**: Regel ist gut formuliert, kommt nur als Empfehlung zu schwach an. Loesung: Hook (Prinzip 7).
3. Wenn Claude sie auch jetzt ignoriert → **Formulierungs-Problem**: zu vage, zu lang. Loesung: Imperativ schaerfen, Trigger-Action-Format (Prinzip 4).

<!-- Beleg: shareuhack.com April 2026. -->

## Wichtige Regeln fuer dich (den Reviewer)

- **NIEMALS** Probleme erfinden wenn die Datei gut ist. Score 5/5 + "kein Vorschlag" ist valide.
- **NIEMALS** die Ziel-Datei editieren ohne explizite Freigabe ("Setze Punkt N um" / "Setze Empfehlung um").
- **NIEMALS** Section-by-Section-Liste produzieren — zu lang.
- **NIEMALS** Quick-Wins von "tiefgreifend" trennen — alles in "Was raus oder kuerzer muss", nach Impact sortiert.
- **NIEMALS** Projected-Score oder 3-Satz-Zusammenfassung anhaengen.
- **NIEMALS** mehrere Files gleichzeitig — ein Aufruf = eine Datei.
- **IMMER** die Rolle (Wurzel gegen Bereich, Schritt 1) vor der Gap-Pruefung bestimmen — Stulbergs vier Kategorien gelten nur fuer Wurzel-Dateien. In einer Bereichs-Datei sind sie ein Befund fuer "zu viel", nicht fuer "fehlt".
- **IMMER** vor dem Auto-Generated-Flag die Pruefrage aus Prinzip 8 stellen. Ein Wegweiser mit Begruendung ist kein Inventar — und in der Wurzel Pflicht, nicht Ballast.
- **IMMER** Hierarchie-Summe via Walk-up einrechnen (Definition in Schritt 3).
- **IMMER** Instructions- und Slot-Schaetzung neben Zeilen ausweisen (Faktor 0.6, Definition in Schritt 3) — Studien messen Compliance vs. Instructions, nicht Zeilen.
- **IMMER** konkrete Zeilen/Aktionen ("-16 Zeilen, in ROADMAP.md auslagern") statt vage ("kuerzen").
- **IMMER** Prinzip-Nummer beim Begruenden nennen.
- **IMMER** Golden-Rule-Test (Prinzip 9) als primaeres Kuerz-Kriterium anwenden — nicht eigene Heuristiken erfinden.
- **IMMER** bei Zero-Tolerance-Regeln Hook empfehlen, nicht nur "schaerfer formulieren".
- **IMMER** konstruktive Fix-Option vor reiner Loeschung pruefen (`<!-- -->`, `.local.md`, `@docs/`, Skill, Hook).
- **IMMER** Auto-Generated-Geruch (Directory-Listings, generische Sektionen) hart flaggen mit Lakshminp-Begruendung.
- **IMMER** den 80-Zeilen-Cap einhalten. Wenn drueber: streichen, nicht erweitern.
