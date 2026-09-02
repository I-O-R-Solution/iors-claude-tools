# Route — Kostentabelle für die Start-Schranke

Wozu: die Zonen im Skill verlangen vor dem Beginn eines Arbeitsstücks die Frage
„passt das noch?". Ohne gemessene Kosten je Art von Arbeit ist die Antwort
geraten. Diese Datei macht sie zu einem Nachschlagen.

**Leseart — bindend: Reichweite, nie Sparziel.** Ein Eintrag hier ist kein
Qualitätsurteil. Ein niedriger Wert ist kein Lob, ein hoher kein Tadel: die
teuerste Zeile dieser Tabelle ist teuer, WEIL 27 Live-Proben einzeln gefahren
wurden — das ist der Beweiswert, nicht die Verschwendung. Wer die Tabelle als
Budget liest, kürzt genau die Prüftiefe, die sie schützen soll. Ihr einziger
Zweck ist die Frage vor dem Start: reicht der Rest für dieses Stück ganz? Reicht
er nicht, wird gelandet — nicht kleiner gearbeitet. Prüfschritte werden niemals
gestrichen, um ein Stück in einen zu knappen Rest zu pressen; das Stück wandert
in die nächste Session.

**EINGEFROREN 01.09.2026 (Oliver): keine Anhäng-Pflicht mehr.** Die Tabelle
bleibt als Nachschlagewerk für die Start-Schranke bestehen — die Größenklassen
unten gelten weiter. Grund: 25+ Messpunkte, die Klassen sind stabil; eine
weitere Zeile ändert die Schranke nicht mehr, die Pflicht kostete nur noch
Handgriffe (Olivers Entscheidung: Handarbeit raus, Automatik bleibt).
Wiedereröffnungs-Kriterium, damit das Einfrieren kein Dogma wird: urteilt die
Schranke ZWEIMAL falsch — ein Stück passte laut Klasse und riss trotzdem die
Zone, oder umgekehrt — wird wieder gemessen statt geglaubt, und diese Passage
kehrt als Pflicht zurück. (Historische Regel bis 01.09.: jede Session mit
Worker-Aufruf hängt eine Zeile an; `vor`/`nach` aus `tools/kontext-jetzt.sh`.)

## Größenklassen (das ist, was die Schranke abfragt)

| Klasse | Kosten | Was hineinfällt |
| --- | --- | --- |
| **KLEIN** | < 40k | ein Doku-Fix, eine einzelne Verifikation, ein Commit, eine Kritik-Runde ohne Plan-Umbau, ein Zettel-Schnitt |
| **MITTEL** | 40–120k | Skill- oder Plan-Umbau mit mehreren Edits, Fix-Runde ohne Live-Proben, kleine Etappe |
| **GROSS** | > 120k | Fix-Runde MIT unabhängiger Prüfung und Live-Proben, Etappe mit Worker-Aufruf, Plan + Kritik in einem Zug |

Die Schranke rechnet: `Spielraum = 400k − aktueller Stand − 40k Landereserve`.
Passt die Klasse nicht in den Spielraum, wird sie **nicht begonnen** — landen und
im nächsten Anlauf frisch anfangen. Daraus folgen die Zonen des Skills, sie sind
also keine gesetzten Zahlen: bei 200k bleiben 160k, GROSS passt gerade noch.
Ab 300k gilt die LANDEN-Zone des Skills — nichts Neues beginnen, auch kein
MITTEL; die Rechnung hier lizenziert das nicht, die Zone geht vor. Die
wirksame Decke folgt aus der Reserve: 400k − 40k ≈ 360k, darüber passt auch
KLEIN nicht mehr.

## Gemessene Einträge

| Datum | Lauf | Arbeitsstück | vor | nach | Kosten | Klasse |
| --- | --- | --- | --- | --- | --- | --- |
| 25.07.2026 | prozess-guard | Sockel beim Start (Skills, Projektdoku, Systemprompt) | 0 | 66k | 66k | — |
| 25.07.2026 | prozess-guard | Rehydrierung: STATE + PLAN.md (180k Bytes, ausschnittweise gelesen) | 67k | 74k | 7k | KLEIN |
| 25.07.2026 | prozess-guard | Fix-Runde f1 komplett: Befund messen, 3 Plan-Edits, Worker-Aufruf, unabhängige Prüfung, 27 Live-Proben, 4 Commits, Zettel | 67k | 345k | 278k | GROSS |
| 25.07.2026 | route-umbau | Skill-Umbau: eine Datei lesen, 10 Edits, Verifikation mit Rot-Proben | 345k | 402k | 57k | MITTEL |
| 25.07.2026 | route-umbau-2 | Haltepunkte + Start-Schranke + Hook: Kostenkurve messen, 4 Skill-Edits, 3 neue Dateien, 11 Rot-Proben, settings.json | 402k | 460k | 58k | MITTEL |
| 25.07.2026 | prozess-guard | Fix-Runde f2 komplett: Rehydrierung, Worker-Aufruf, Verifikation als Workflow (6 Subagenten, 477k Subagent-Tokens NICHT in dieser Spalte), 22 Live-Proben, Beleg, Zettel, 2 Commits | 72k | 263k | 191k | GROSS |
| 25.07.2026 | ueber-uns-nextlevel | Kritik R3 Sol+Kimi + Plan-Revision (27 Befunde) | 74k | 240k | 166k | GROSS |
| 25.07.2026 | zwei-marken | S4a Messarbeit (Waechter+Netzgate+Nachpruefung+DB-Upgrade+Sol-Review-Handshake) | 71k | 150k | 79k | MITTEL |
| 25.07.2026 | wissens-center | S20 Schritt 6.2 Volldiff + 13 eigene Nachmessungen + E6-Lauf | 75k | 321k | 246k | GROSS |
| 25.07.2026 | ueber-uns-nextlevel | Kritik R4 (Sol 9 + Kimi 8, parallel) + Plan-Revision 17 Befunde + Boss-Eigenfund M3b + Zettel | 74k | 265k | 191k | GROSS |
| 25.07.2026 | prozess-guard | S11 Fix-Runde 3 (Sol resume) + 22 Live-Hook-Proben + 3 Kanarienvoegel + Beleg + Zettel-Trim + Commit | 72k | 209k | 137k | GROSS |
| 25.07.2026 | prozess-guard | S11 Fortsetzung: Kimi-Deadlock-Diagnose + 4 Zitate + Vertragsaenderung P1.14(a) + Nachtrag + Commit | 209k | 259k | 50k | MITTEL |
| 25.07.2026 | zwei-marken | S4b Schritt 6.2 Volldiff (src 2540 Zeilen + FE-Kern + api) + Adjudikation Sol-Review + Befundschrift + STATE | 64k | 260k | 196k | GROSS |
| 25.07.2026 | ueber-uns-nextlevel | PLAN-Kuerzung 83k->74k (25 Edits) + Kritik R5 Sol+Kimi parallel, NICHT ausgewertet | 64k | 258k | 194k | GROSS |
| 26.07.2026 | zwei-marken | S5 zwei Fix-Runden (f1 10 Befunde + f2 4 Nachbefunde) inkl. 2 Volldiff-Reads, 2 eigene Rot-Proben, 3 Guard-Laeufe, 3 Commits + STATE | 71k | 225k | 154k | GROSS |
| 26.07.2026 | wissens-center | S21 Abschluss: E6-Snapshot + 2 Volllaeufe + 4 eigene Rot-Proben + 6-Agent-Workflow + 2 Sol-Fixrunden + Volldiff-Review + 2 Commits + STATE | 74k | 300k | 226k | GROSS |
| 26.07.2026 | prozess-guard | S12 Fix-Runde 4 (Sol resume, Naht) + Verifikation + 9 Live-Hook-Proben inkl. 3 Kanarienvoegel + Beleg + Zettel-Trim (3x) + Commit + Eskalation | 80k | 201k | 121k | GROSS |
| 26.07.2026 | ueber-uns-nextlevel | S5 Behauptungs-Inventar (AGB-Volltext, 27 Zusagen) + 19 R5-Befunde eingearbeitet + M11/M8e neu + Zettel | 75k | 240k | 165k | GROSS |
| 26.07.2026 | prozess-guard | S13 Fix-Runde 5 (Fixpunkt + Zeilen-Scope) + PLAN-Vertrag + Verifikation + 17 Live-Hook-Proben + Beleg + Zettel-Trim (3x) + Commit | 73k | 206k | 133k | GROSS |
| 26.07.2026 | zwei-marken | S5 Fortsetzung: /check auf STATE (2 WICHTIG gefixt) + PERZEPTIV-Abnahme Oliver + STATE-Trim | 225k | 300k | 75k | MITTEL |
| 26.07.2026 | zwei-marken | S6 /simplify-Gate (4 Pruef-Agenten) + 3 Fix-Runden f3/f4/f5 inkl. 6 eigener Rot-Proben + /security-review + Netzgate-Vollaufbau + Test-Diff/Screenshots + 3 Commits + Zettel | 71k | 212k | 141k | GROSS |
| 26.07.2026 | zwei-marken | S7 Schritt 8 (Abschluss: measure-run ueber 12 Transkripte, LESSONS, STATE-Schluss, Commit) | 71k | ~95k | ~24k | KLEIN |
| 26.07.2026 | ueber-uns-nextlevel | S5b Rechtstext-Fix AGB+cockpit (7 Kanzlei- + 3 Paket-Stellen), tsc+build+Commit, Basis-Rebase 13x, STATE | 240k | 300k | 60k | MITTEL |
| 28.07.2026 | prozess-guard | S14 Runde 6 (Sol resume: P1.9(c), Fixture-Manifest, 6 Literal-Zeugen) + Rehydrierung aus 186k-PLAN + Verifikations-Subagent + Neuversiegelung + 10 Live-Hook-Proben + Beleg + Zettel + 2 Commits | 77k | 219k | 142k | GROSS |

## Ehrlichkeits-Grenzen dieser Tabelle

- **Die Klassengrenzen (40k / 120k) stammen aus den ersten fünf Punkten einer
  einzigen Session.** Inzwischen liegen 18 weitere Zeilen aus vier Läufen in
  der Tabelle (25.–28.07., am 30.07. aus Freitext in Tabellenform gebracht,
  Klasse aus `nach − vor` berechnet). Sie stützen die Einteilung, verschieben
  aber ihren Schwerpunkt: 13 der 18 liegen über 120k, nur eine unter 40k. Ein
  Arbeitsstück in diesem System ist im Normalfall GROSS, nicht MITTEL. Wer
  MITTEL plant, plant meist falsch. Beide Grenzen selbst (40k, 120k) sind
  weiter unvalidiert — keine Zeile landet nahe genug an ihnen.
- **Die Landereserve von 40k ist geschätzt, nicht isoliert gemessen.** Sie steckt
  im 278k-Eintrag mit drin. Die nächste Session misst sie sauber: Stand direkt vor
  dem ersten Zettel-Schreiben, Stand nach dem letzten Commit.
- **Die 278k sind ein Extremfall, kein Mittelwert.** In dieser Fix-Runde steckten
  27 Live-Proben als je eigener Werkzeugaufruf, weil ihr Beweiswert am echten
  Hook-Pfad hängt (L-I). Eine Fix-Runde ohne diese Pflicht liegt deutlich
  darunter — wie tief, ist offen.
- **Subagenten fehlen hier vollständig.** Diese Session hatte keine. Sobald
  delegiert wird, gehört ihr Verbrauch in eine eigene Spalte, sonst sieht
  Verlagerung wie Ersparnis aus.
| 09.08.2026 | prozess-guard | Etappe f9 (Sol resume) + Boss-Verifikation (Selftests, Korpus, 10 Rot-Proben, Kanarie) + PLAN-Fix W1 + Commit + Zettel | 78k | 175k | 97k | MITTEL |
| 11.08.2026 | wissens-lotse-etappe1 | S4 Bau E1 (Sol GROSS) + Boss-Verifikation (3 Kernmessungen, 14 Rot-Zeugen via 2 Subagenten + selbst) + Code-Review 65 KB + Fix-Runde f1 + Zettel | 76k | 223k | 147k | GROSS |
| wissens-lotse-etappe1 E2+f3 (Bau+Verify, GROSS) | 73k | 191k |
| 12.08.2026 | wissens-lotse-etappe1 | S4 RISIKO-Diff-Review E2+f3 (voller Diff) + Erstprüfung 63/63 + Stempel (Sol resume) + Boss-Verifikation (Zensus, Drift, Dumps, 5 Rot-Proben) + Zettel | 69k | 324k | 255k | GROSS |
| 13.08.2026 | art4-neufassung | S3 Bau E1 (Sol, Waechter + P4/P5) + Boss-Verifikation (Zensus selbst nachgemessen, 11 Rot-Proben selbst gefahren, Code-Review 538 Zeilen) + Commit + Zettel | 74k | 205k | 131k | GROSS |
| 16.08.2026 | art4-neufassung | S2 Delta-Kritik E3b (Sol read-only) + Triage 0/5/1 -> Waechter 27-32 + Zettel | 94k | 130k | 36k | KLEIN |
