# Pflicht-Files Spezifikation — Spark

Wird von `SKILL.md` Phase 3.1 geladen. Konkrete Aufbau-Specs pro Pflicht-File.
Workflow-Regeln (Goldene Regel, Idempotenz, Konflikt-Verhalten) bleiben in
SKILL.md.

---

## 1. AGENTS.md (Substanz, max 60 Zeilen) + CLAUDE.md (Pointer, 1 Zeile)

Die Substanz liegt in `AGENTS.md` — dem Standard, den Codex direkt liest.
`CLAUDE.md` ist NUR ein Pointer, exakt eine Zeile, kein Frontmatter,
kein weiterer Text:

```
@AGENTS.md
```

Claude Code expandiert den Import beim Start und liest damit dieselbe
Substanz. Bereichs-Dateien in Unterordnern bleiben normale `CLAUDE.md`
(Codex-Verhalten bei verschachtelten AGENTS.md ungeprueft — nicht umstellen).

Aufbau AGENTS.md in dieser Reihenfolge:

- Optionales Frontmatter GANZ am Anfang (nur wenn parent-zone abgeleitet
  wurde, siehe SKILL.md Phase 3.3):
  ```yaml
  ---
  parent_zone: <products|clients|capital|knowledge|ops>
  ---
  ```
- H1: Projektname + Halbsatz worum es geht
- Direkt darunter zwei Imports plus eine Klartext-Zeile:
  ```
  @CONTEXT.md
  @REFERENCES.md

  Die `@`-Zeilen sind zugleich Claude-Code-Imports; andere Tools folgen
  der Klartext-Anweisung: CONTEXT.md und REFERENCES.md mitlesen.
  ```
  (Ohne die Imports waeren beide Files unsichtbar fuer Claude.)
- 2-3 Saetze: was genau, fuer wen
- Sektionen die diese vier Informations-Typen abdecken (Sektions-Namen frei):
  - **Project Understanding** — Ziele, getroffene Entscheidungen, harte
    Rahmenbedingungen
  - **People Context** — wer arbeitet mit, fuer wen wird gebaut. Solo:
    "ich + Claude als Sparringspartner"
  - **Working Preferences** — Sprache, Workflow-Regeln, Bestaetigungs-Punkte.
    **Pflicht-Zeile fuer Living-Doc-Vertrag** — Satz frei formulierbar,
    der Anker-Kommentar am Zeilenende ist Pflicht (verify.sh greppt ihn):
    > CONTEXT.md ist Living-Doc — wenn `last_updated` >30 Tage: "Aktueller Stand" review. <!-- spark:living-doc -->
  - **Aktueller Fokus (Stand: <heutiges Datum>)** — max 3 Punkte was JETZT
    dran ist
- Bei 3+ Top-Level-Unterordnern: zusaetzlich **Dokument-Index** (eine Zeile
  pro Top-Level-Ordner)
- **Eine Zeile zu Craft-Principles (Pflicht, Anker am Zeilenende):**
  > Craft-Principles: siehe `decisions/000-craft-principles.md` — bei
  > Konflikt mit einer Saeule: Entscheidung anpassen, nicht Saeulen. <!-- spark:craft -->
- **GANZ ZUM SCHLUSS**: `## IMPORTANT — Critical Rules` mit max 3
  Always-On-Regeln (mehr Marker = Inflation). Pflicht-Eintrag wortwoertlich
  — aber NUR bei Code-Profil ≠ none oder wenn Secrets/APIs vorkommen (bei
  reinen Doku-/Wissensprojekten entfaellt die Zeile):
  > DO NOT commit Geheimnisse — alles in `.env`, `.env` ist in `.gitignore`.

**Goldene Regel** (Boris Cherny): Frag bei jeder Zeile "wuerde Claude ohne
diese Zeile einen Fehler machen?". Wenn nein — weglassen.

**Regeln pro Instruktionsdatei (AGENTS.md UND Bereichs-CLAUDE.md):**
- Jede Regel ueberpruefbar ("Funktionen max 40 Zeilen" statt "sauber coden")
- Trigger-Action-Format wo moeglich ("Wenn X, tu Y")
- Format-Regeln gehoeren in Linter, nicht hier
- Nur projektspezifische Abweichungen vom Default — den Default kennt Claude

Beispiele fuer echte Abweichungen die rein duerfen:
- "TypeScript: kein `any`, auch nicht `as any`" (geht ueber strict-mode hinaus)
- "Python: Type-Hints auf alle Funktions-Signaturen pflicht, auch Tests"
- "Tests laufen gegen echte Postgres, nicht gegen Mocks"

Reine Defaults wie "verwende async/await" oder "pytest fuer Tests" gehoeren
NICHT in AGENTS.md.

---

## 2. CONTEXT.md (~40 Zeilen)

Hintergrund und Why. **Pflicht-Frontmatter am Datei-Anfang:**
```yaml
---
last_updated: <heute>
review_after_days: 30
---
```

Sektionen in dieser Reihenfolge:

- **Worum geht es** — 2-4 Saetze, was und fuer wen
- **Excellence-Anchor** (aus Phase 1.6 — drei Sub-Sektionen):
  - Output-Vision: <Antwort 1>
  - Mess-Anker: <Antwort 2>
  - Detail-Beweis: <Antwort 3>
- **Stakeholder/Mitwirkende**
- **Erfolgskriterien** (aus Detail-Beweis ableiten falls leer)
- **Aktueller Stand** (initial: "Tag 1 — Geruest steht.")

Mit Inhalt aus Beschreibung gefuellt — leer wo User nichts gesagt hat.

---

## 3. REFERENCES.md

Externe Quellen: API-Doku, Tools, Doku-Links, Repos. **Keine API-Keys**
(gehoeren in `.env`).

Sektionen:
- **Externe Systeme** (APIs/DBs/Services aus Beschreibung)
- **Inspirations-Quellen** — die Mess-Anker aus Excellence-Anchor:
  Werke/Produkte/Personen an denen wir uns messen, mit Link wenn vorhanden
  und einer Zeile warum

---

## 4. README.md

Fuer Menschen, GitHub-sichtbar:
```
# <Projektname>
<Ein Absatz Erklaerung>
## Setup
<konkrete Befehle wenn Code-Profil aktiv, sonst weglassen>
```

---

## 5. .gitignore

Anzahl-Regel (genau eines im Root, auch bei hybrid): SSoT ist die
Anti-Pattern-Liste in SKILL.md. Standard-Ignores fuer Secrets/OS. Bei
Code-Profil sprach-spezifisch erweitern (siehe `references/code-profiles.md`).

---

## 6. decisions/TEMPLATE.md

ADR-Stil mit Pflicht-Feldern: Title, Status, Context, Decision,
Consequences. Platzhalter in spitzen Klammern.

---

## 7. decisions/000-craft-principles.md (Pflicht)

```
# Craft-Principles — <Projektname>
Status: Active
Datum: <heute>

Die unverhandelbaren handwerklichen Saeulen dieses Projekts. Wenn eine
Entscheidung diese verletzt — Entscheidung anpassen, nicht Saeulen.

## Saeulen

1. <Saeule 1 — eine Zeile, kraftvoll>
2. <Saeule 2>
3. <Saeule 3>
(4-5 wenn extrahiert)

## Wir wuerden lieber X als Y

(Konkrete Tradeoff-Beispiele wie das Projekt sich entscheiden wuerde.
Pro Saeule mindestens ein Beispiel — kein "Was wenn", sondern "Wir wuerden
lieber X als Y".)

## Anti-Beispiele — was passt NICHT zu uns

(Was wuerden wir nicht tun, auch wenn andere Projekte das machen. Pro
Saeule mindestens eines.)
```

Saeulen, Tradeoffs und Anti-Beispiele aus Beschreibung + Excellence-Anchor
extrahieren. Bei zu wenig Material: Kandidaten zeigen + User fragen.
