# Route — Sitzplan (welches Modell sitzt wo, und warum)

Wozu diese Datei: die Sitz-Begründungen standen inline in `SKILL.md`, datiert
auf 25./30.07.2026 — niemand merkt dort, wenn sie veralten. Hier trägt jede
Zeile ihren Beleg MIT Datum und ein Nachmess-Datum. Eine Zeile ohne Beleg ist
ein Defekt dieser Tabelle. `SKILL.md` verweist hierher und trägt nur noch die
Regeln, die nie am Benchmark hängen (Fremdfamilien-Prinzip, kein Claude-Builder).

**Leseart:** Benchmarks sind Stichproben, keine Wahrheiten. Ein Sitz wechselt
nicht bei 0,5 Punkten Differenz, sondern wenn ein Beleg kippt ODER der Preis
das Verhältnis ändert. Nachmessen heißt: die Quelle neu ziehen und das Datum
erneuern, nicht die Tabelle glauben.

**Nächstes Nachmessen: 2026-12-01** (Quartalsrhythmus; früher bei Modell-Release).

## Die Sitze

| Sitz | Modell | Beleg (Zahl · Quelle · Datum) | Preis $/1M in/out |
| --- | --- | --- | --- |
| Boss (Plan, Review, Verifikation) | **Opus 5** (`/model claude-opus-5`) | Artificial-Analysis-Index 63 = #1 von 178 · artificialanalysis.ai · 31.08.2026. SWE-bench Verified 96 % = #1 · benchlm.ai · 31.08.2026 | 5 / 25 |
| Plan schreiben (S2) bei RISIKO/GROSS | **Fable 5** (`/model claude-fable-5`) | Coding-Index 82,4 vs Opus 79,3 · benchlm.ai · 31.08.2026 — reines Denken ist hier das Produkt | 10 / 50 |
| RISIKO-Diff-Review (S4, frische Session) | **Fable 5** | wie oben; zusätzlich Sitz-Prinzip: nie dieselbe Session, die den Bau sah | 10 / 50 |
| Builder Standard (S3) | **Sol** (Codex, GPT-5.6) | Terminal-Bench v2.1 89,5 % = #1 (Opus 5: 89,1) · artificialanalysis.ai · 31.08.2026. Tragende Begründung bleibt die FREMDE Familie: Claude-Review auf Claude-Arbeit wäre blind | 5 / 30 (eigene Quota) |
| Builder-Alternative (je Etappe) | **Kimi K3** | Coding-Index 79,6 ≈ Sol 79,9 bei halbem Preis · benchlm.ai · 31.08.2026. Frontend Arena #1 (07/2026) bleibt als Spezial-Beleg. NICHT nur Frontend — als Zweit-Builder allgemein anbietbar, WENN die Etappe keine Shell braucht (Kimi hat keine) | 3 / 15 (eigene Quota) |
| Zweitkritik RISIKO + GROSS (S3-Kritik) | **Kimi K3** | Fremdfamilien-Prinzip; METR maß bei Sol Rekord-Reward-Hacking (07/2026) — Sol soll nicht allein Pläne kritisieren, die Sol baut | 3 / 15 |
| Mechanische Prüfung mit Prädikat | **sonnet/haiku-Subagent** (unverändert) | Messung verlangt das AUSFÜHREN des Befehls — der Worker hat konstruktionsbedingt in keinem Modus eine Shell (`worker.sh`, SCHLUSSSTRICH 18.07.2026). Kein Fremd-Worker bekommt diesen Sitz | Claude-Quota |
| Shell-freie Fleißarbeit (Klassen-Suche, Auswertung von Boss-Ausgaben) | **sonnet/haiku-Subagent** (unverändert) | läuft im Claude-Abo mit — ein Fremd-Worker würde sparen, wo real kaum Kosten anfallen (Begründung unten bei DeepSeek) | Claude-Quota |

## Geprüft und VERWORFEN (damit die Frage nicht wiederkehrt)

| Modell | Entscheidung | Begründung |
| --- | --- | --- |
| **DeepSeek V4** | **kein Sitz** (Oliver, 01.09.2026) | (1) Bau: 80,6 % SWE-bench Verified vs Opus 96 % · benchlm.ai/webscraft · 08/2026 — kategorischer Abstand. (2) Fleißarbeit: sonnet/haiku laufen im Abo quasi kostenfrei mit; der Spareffekt (0,435/0,87 $/1M) trägt den Pflegeaufwand nicht (Key, T4/T8, ToS-Lektüre, Export-Freigabe je Lauf). (3) Drittkritik: Runde 1 fängt alle Katastrophen (Messung 07/2026), Kimi ist bereits die fremde Familie und das stärkere Modell (Coding-Index 79,6). Die Tür bleibt billig: `profiles/deepseek.conf` liegt inaktiv bereit — ein Sitz wäre eine Conf-Datei plus scharfe Gates, kein Umbau |
| Claude Mythos 5 | Beobachtung, kein Sitz | Coding-Index 82,7 = #1 · benchlm.ai · 31.08.2026 — aber in dieser Installation nicht als Modell wählbar (verfügbar: opus-5, fable-5, sonnet-5, haiku-4-5). Vor jeder Nutzung Verfügbarkeit prüfen |

## Kosten-Ehrlichkeit

Fremd-Worker laufen auf eigener Quota und fehlen in jeder Transkript-Messung.
Seit v2.2 schreibt `worker.sh` je Aufruf eine Zeile nach `WORKER-KOSTEN.md`
im Lauf-Ordner (Fallback: stderr). S6 nimmt diese Summe ZUSÄTZLICH zur
`kanten-messung.py`-Auswertung in die `LESSONS.md`-Zeile auf; fehlt sie, trägt
die Zahl den Zusatz **„nur Boss-Kosten, Fremd-Quota unerfasst"**.
`measure-run.py` rechnet seit v2.2 mit expliziten Vier-Satz-Preisen je Modell
(auch kimi-k3, deepseek-v4, opus-5); unbekannte Kennungen fallen markiert auf
Fable-Sätze zurück.
