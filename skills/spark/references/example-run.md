# Gold-Standard-Durchlauf — Spark Beispiel

Kalibrier-Referenz fuer Ton und Tiefe. NICHT kopieren — das fiktive Projekt
"stimmgabel" zeigt, wie gefuellte Outputs aussehen. Wird von SKILL.md
Phase 3.1 bei Unsicherheit referenziert.

---

## Eingabe (reichhaltig, kein Frage-Block noetig)

> /spark Ich baue stimmgabel — ein Python-CLI-Tool fuer Podcast-Produzenten,
> das Interview-Audios per Whisper transkribiert und daraus zitierfaehige
> Passagen extrahiert. Drei Bereiche: Transkription (Whisper-Anbindung,
> Formate), Zitat-Extraktion (Scoring, Auswahl-Regeln), Export (Markdown,
> Notion). Regelmaessig: Audios verarbeiten, Zitate reviewen, Exports pruefen.

## Excellence-Anchor-Antworten (Beispiel-Qualitaet)

1. **Output-Vision:** "Produzent zieht eine 90-Minuten-Folge rein, trinkt
   einen Kaffee, kommt zurueck und sieht 12 Zitate, von denen er 10 sofort
   posten wuerde."
2. **Mess-Anker:** Descript-Praezision bei Timestamps, Readwise-Sorgfalt
   bei Zitat-Auswahl, ripgrep-Geschwindigkeitsgefuehl im CLI.
3. **Detail-Beweis:** Jedes exportierte Zitat hat einen klickbaren
   Timestamp, der auf die Sekunde genau sitzt.

## Tiefen-Pruefung (wie sie im Chat aussieht)

```
TIEFEN-PRUEFUNG
- Top-Level-Bereiche: transkription, zitat-extraktion, export
- Pro Bereich Unterthemen: transkription: whisper/formate · zitat-extraktion: scoring/auswahl-regeln · export: markdown/notion
- Tiefen-Entscheidung: alle drei: bereichs-claude (je 2 Unterthemen, je 1 Konzept)
- Code-Profil: python
```

## Baum (Ergebnis)

```
stimmgabel/
  AGENTS.md
  CLAUDE.md          (Pointer: @AGENTS.md)
  CONTEXT.md
  REFERENCES.md
  README.md
  .gitignore
  .python-version
  pyproject.toml
  decisions/
    TEMPLATE.md
    000-craft-principles.md
  src/stimmgabel/__init__.py
  tests/conftest.py
  transkription/CLAUDE.md
  zitat-extraktion/CLAUDE.md
  export/CLAUDE.md
```

## AGENTS.md (gekuerzt — so klingt gefuellt)

Daneben liegt `CLAUDE.md` mit exakt einer Zeile: `@AGENTS.md`.

```markdown
# stimmgabel — Zitierfaehige Passagen aus Podcast-Interviews

@CONTEXT.md
@REFERENCES.md

Die `@`-Zeilen sind zugleich Claude-Code-Imports; andere Tools folgen
der Klartext-Anweisung: CONTEXT.md und REFERENCES.md mitlesen.

CLI-Tool fuer Podcast-Produzenten: Whisper-Transkription rein,
posting-fertige Zitate mit exakten Timestamps raus.

## Project Understanding
- Whisper laeuft lokal, kein Cloud-Upload von Audios (Entscheidung, fix)
- Zielgruppe: Solo-Produzenten ohne Schnitt-Team

## Working Preferences
- CONTEXT.md ist Living-Doc — wenn `last_updated` >30 Tage: "Aktueller Stand" review. <!-- spark:living-doc -->

## Aktueller Fokus (Stand: 2026-07-05)
- Whisper-Anbindung: erstes Transkript aus echter Folge

Craft-Principles: siehe `decisions/000-craft-principles.md` — bei
Konflikt mit einer Saeule: Entscheidung anpassen, nicht Saeulen. <!-- spark:craft -->

## IMPORTANT — Critical Rules
- DO NOT commit Geheimnisse — alles in `.env`, `.env` ist in `.gitignore`.
- Timestamps sind heilig: jede Pipeline-Stufe reicht sie unveraendert durch.
```

Beachte: keine Fuellsaetze, jede Zeile verhindert einen konkreten Fehler.
Die Timestamp-Regel kommt direkt aus dem Detail-Beweis — so wandert der
Anchor in die Regeln.

## 000-craft-principles.md (gekuerzt)

```markdown
# Craft-Principles — stimmgabel
Status: Active
Datum: 2026-07-05

## Saeulen
1. Timestamps auf die Sekunde — oder das Zitat fliegt raus.
2. Lieber 10 posting-fertige Zitate als 40 Kandidaten.
3. Audio bleibt lokal — keine Cloud, kein Upload, keine Ausnahme.

## Wir wuerden lieber X als Y
- Lieber ein Zitat verwerfen als einen wackligen Timestamp shippen.
- Lieber laengere Laufzeit als Audio in fremde Haende.

## Anti-Beispiele — was passt NICHT zu uns
- "Top 50 Highlights" als Zitat-Flut — Kuratierung ist das Produkt.
- Cloud-Transkription als Speed-Option anbieten.
```

## Woran man den Gold-Standard erkennt

- Saeulen sind Ein-Zeilen-Entscheidungen, keine Werte-Prosa
- Anchor-Antworten tauchen wortnah in Regeln und Saeulen wieder auf
- Bereichs-Struktur spiegelt exakt die genannten Unterthemen — nicht mehr
- Kein einziger `<...>`-Platzhalter im Ergebnis
