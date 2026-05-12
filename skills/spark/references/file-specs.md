# Pflicht-Files Spezifikation — Spark

Wird von `SKILL.md` Phase 3.1 geladen. Konkrete Aufbau-Specs pro Pflicht-File.
Workflow-Regeln (Goldene Regel, Idempotenz, Konflikt-Verhalten) bleiben in
SKILL.md.

---

## 1. CLAUDE.md (max 60 Zeilen)

Aufbau in dieser Reihenfolge:

- H1: Projektname + Halbsatz worum es geht
- Direkt darunter zwei Imports:
  ```
  @CONTEXT.md
  @REFERENCES.md
  ```
  (Ohne diese Imports waeren beide Files unsichtbar fuer Claude.)
- 2-3 Saetze: was genau, fuer wen
- Sektionen die diese vier Informations-Typen abdecken (Sektions-Namen frei):
  - **Project Understanding** — Ziele, getroffene Entscheidungen, harte
    Rahmenbedingungen
  - **People Context** — wer arbeitet mit, fuer wen wird gebaut. Solo:
    "ich + Claude als Sparringspartner"
  - **Working Preferences** — Sprache, Workflow-Regeln, Bestaetigungs-Punkte.
    **Pflicht-Zeile fuer Living-Doc-Vertrag (wortwoertlich):**
    > CONTEXT.md ist Living-Doc — wenn `last_updated` >30 Tage: "Aktueller Stand" review.
  - **Aktueller Fokus (Stand: <heutiges Datum>)** — max 3 Punkte was JETZT
    dran ist
- Bei 3+ Top-Level-Unterordnern: zusaetzlich **Dokument-Index** (eine Zeile
  pro Top-Level-Ordner)
- **Eine Zeile zu Craft-Principles (Pflicht):**
  > Craft-Principles: siehe `decisions/000-craft-principles.md` — bei
  > Konflikt mit einer Saeule: Entscheidung anpassen, nicht Saeulen.
- **GANZ ZUM SCHLUSS**: `## IMPORTANT — Critical Rules` mit max 3
  Always-On-Regeln (mehr Marker = Inflation). Pflicht-Eintrag wortwoertlich:
  > DO NOT commit Geheimnisse — alles in `.env`, `.env` ist in `.gitignore`.

**Goldene Regel** (Boris Cherny): Frag bei jeder Zeile "wuerde Claude ohne
diese Zeile einen Fehler machen?". Wenn nein — weglassen.

**Regeln pro CLAUDE.md (Haupt UND Bereichs):**
- Jede Regel ueberpruefbar ("Funktionen max 40 Zeilen" statt "sauber coden")
- Trigger-Action-Format wo moeglich ("Wenn X, tu Y")
- Format-Regeln gehoeren in Linter, nicht hier
- Nur projektspezifische Abweichungen vom Default — den Default kennt Claude

Beispiele fuer echte Abweichungen die rein duerfen:
- "TypeScript: kein `any`, auch nicht `as any`" (geht ueber strict-mode hinaus)
- "Python: Type-Hints auf alle Funktions-Signaturen pflicht, auch Tests"
- "Tests laufen gegen echte Postgres, nicht gegen Mocks"

Reine Defaults wie "verwende async/await" oder "pytest fuer Tests" gehoeren
NICHT in CLAUDE.md.

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

**Genau eines** im Projekt-Root, nirgendwo sonst. Standard-Ignores fuer
Secrets/OS. Bei Code-Profil sprach-spezifisch erweitern (siehe
`references/code-profiles.md`).

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
