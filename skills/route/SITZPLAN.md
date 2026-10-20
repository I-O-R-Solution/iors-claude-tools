# Route — Sitzplan (welches Modell sitzt wo, und warum)

Wozu diese Datei: die Sitz-Begründungen standen inline in `SKILL.md`, datiert
auf 25./30.07.2026 — niemand merkt dort, wenn sie veralten. Hier trägt jede
Zeile ihren Beleg MIT Datum und ein Nachmess-Datum. Eine Zeile ohne Beleg ist
ein Defekt dieser Tabelle. `SKILL.md` verweist hierher und trägt nur noch die
Regeln, die nie am Benchmark hängen (Reviewer nie Builder-Modell/-Session, Rot-Zeugen).

**Leseart:** Benchmarks sind Stichproben, keine Wahrheiten. Ein Sitz wechselt
nicht bei 0,5 Punkten Differenz, sondern wenn ein Beleg kippt ODER der Preis
das Verhältnis ändert. Nachmessen heißt: die Quelle neu ziehen und das Datum
erneuern, nicht die Tabelle glauben.

**Nächstes Nachmessen: 2026-12-01** (Quartalsrhythmus; früher bei Modell-Release).

**Standardbesetzung seit 17.10.2026:** Opus 5.5
auf Denkstufe **medium** plant und baut; **GPT-6 Astra (Codex, medium)** prüft
den Plan EINMAL und die Ausführung EINMAL, verbessert direkt — und lässt es,
wenn es gut genug ist. Ein kurzer Prüf-Zirkel, keine Schleife. Fable 5.1 hat
keinen Sitz mehr. Kritiker und Reviewer sind nie Modell UND nie Session des
Builders; die Messlatte tragen weiter MACHINE-Prädikate mit Rot-Zeugen.
Datenfluss: Astra liest das Repo über OpenAI (wie Sol bis 27.09.).

**Stand Astra 17.10.2026 (gemessen):** `codex exec -m gpt-6-astra` → 400 „not
supported when using Codex with a ChatGPT account" — mit CLI 0.144.1, 0.163.0
und der VS-Code-Binary 0.162.0-alpha.17.2; am 14.10. lief Astra im selben Konto
noch (Rollout-Log). Bekannter Konto-Fehler bei OpenAI (GitHub openai/codex
#45380, #46304, #49619), kein Fehler hier. Ersatz nur mit Ja des Nutzers je Lauf:
`ASTRA_MODEL=gpt-5.6-terra` (am 17.10. erreichbar; mit ihm liefen die Tests).

## Die Sitze

| Sitz | Modell | Beleg (Zahl · Quelle · Datum) | Preis $/1M in/out |
| --- | --- | --- | --- |
| Plan-Review + Verbesserung (S2), Ausführungs-Review + Fix (S4) | **GPT-6 Astra, medium** (nur über `astra.sh`) | Sitzwahl 17.10.2026, kein Benchmark-Beleg erhoben. Wert: fremde Modellfamilie auf Claude-Arbeit. Mechanik am 17.10. mit Ersatz Terra belegt: guter Plan → GUT_GENUG, 0 Änderungen · Lücken-Plan → VERBESSERT, nur PLAN.md · gute Ausführung → GUT_GENUG · fehlerhafte Ausführung → VERBESSERT, danach 3/3 Plan-Prüfungen grün. Rot-Zeugen per Stub: fremde Datei, GUT_GENUG-Lüge, VERBESSERT-Lüge → je Exit 5 | ChatGPT-Abo (Codex) |
| Boss (Interview, Plan, Verifikation, Diff-Lesung) | **Opus 5.5, medium** (`/model claude-opus-5-5`, `/effort medium`) | Launch-Tabelle: vor Fable 5.1 auf allen 9 Benchmarks, u. a. Terminal-Bench 4.0 66,4 vs 55,8 · CursorBench 4.0 57,8 vs 51,8 · FrontierCode 54,4 vs 50,3 · the-decoder.com · 22.09.2026. benchlm.ai Overall 86,98 = vor Fable 5.1 (83) · 27.09.2026. Denkstufe medium = Olivers Auftrag 17.10.; die Prüftiefe tragen Astra und die Prädikate | 4 / 20 |
| Builder (S3 + die eine Fix-Runde S5, headless `claude -p --effort medium`) | **Opus 5.5, medium** | wie oben; Terminal-Bench und CursorBench messen genau agentisches Bauen. Vorbehalt: Artificial Analysis misst ~119k Output-Token je Aufgabe (the-decoder.com, 22.09.2026) — Kosten je Aufruf in `WORKER-KOSTEN.md` | 4 / 20 (Claude-Quota) |
| Zweitkritik RISIKO + GROSS (S2, read-only, parallel zu Astra) | **Opus 5.5, medium, Linse Repo-Verifikation** | Wert kommt aus der anderen LINSE (jede Faktbehauptung am Repo prüfen) und dem frischen Kontext, nicht aus dem Modell | 4 / 20 |
| Mechanische Prüfung mit Prädikat | **Sonnet 5 / Haiku 4.5-Subagent** | Messen heißt Befehl ausführen und Zahl ablesen — keine Urteilsarbeit. Sonnet 5 benchlm.ai Overall 67,01 (27.09.2026) reicht dafür, kostet die Hälfte von Opus 5.5 | 2 / 10 · 1 / 5 |
| Shell-freie Fleißarbeit (Klassen-Suche, Auswertung) | **Sonnet 5 / Haiku 4.5-Subagent** | wie oben | 2 / 10 · 1 / 5 |

**Warum Sonnet 5 NICHT baut:** Overall 67 vs 87 (benchlm.ai, 27.09.2026) ist ein
kategorischer Abstand. Jede zusätzliche Fix-Runde kostet mehr als der halbe
Token-Preis spart — beim Bauen zählt Kosten je fertiger Etappe, nicht je Aufruf.

**Stillgelegte Sitze:** Sol (Codex, GPT-5.6) als Builder, Kimi K3 als
Zweit-Builder und Zweitkritik. Stand ihrer Belege bei Stilllegung: Sol
Terminal-Bench v2.1 89,5 %, Kimi Coding-Index 79,6 (beide 31.08.2026). Ihre
Dateien sind nicht Teil dieser Ausgabe; Reaktivierung = Sitzwechsel hier.

## Geprüft und VERWORFEN (damit die Frage nicht wiederkehrt)

| Modell | Entscheidung | Begründung |
| --- | --- | --- |
| **DeepSeek V4** | **kein Sitz** (01.09.2026) | (1) Bau: 80,6 % SWE-bench Verified vs Opus 96 % · benchlm.ai/webscraft · 08/2026 — kategorischer Abstand. (2) Fleißarbeit: sonnet/haiku laufen im Abo quasi kostenfrei mit; der Spareffekt (0,435/0,87 $/1M) trägt den Pflegeaufwand nicht (Key, T4/T8, ToS-Lektüre, Export-Freigabe je Lauf). (3) Drittkritik: Runde 1 fängt alle Katastrophen (Messung 07/2026), Kimi ist bereits die fremde Familie und das stärkere Modell (Coding-Index 79,6). Die Tür bleibt billig: `profiles/deepseek.conf` liegt inaktiv bereit — ein Sitz wäre eine Conf-Datei plus scharfe Gates, kein Umbau |
| Claude Mythos 5 | Beobachtung, kein Sitz | Coding-Index 82,7 = #1 · benchlm.ai · 31.08.2026 — aber in dieser Installation nicht als Modell wählbar (verfügbar 31.08.: opus-5, fable-5, sonnet-5, haiku-4-5). Vor jeder Nutzung Verfügbarkeit prüfen |

## Kosten-Ehrlichkeit

Worker und Kritiker laufen als eigene `claude -p`-Sessions und fehlen in der
Transkript-Messung der Boss-Session — aber sie belasten dieselbe Claude-Quota.
Jeder Aufruf liefert `total_cost_usd` im JSON-Umschlag; der Boss hängt ihn als
Zeile an `WORKER-KOSTEN.md` im Lauf-Ordner. S6 nimmt diese Summe ZUSÄTZLICH zur
`kanten-messung.py`-Auswertung in die `LESSONS.md`-Zeile auf; fehlt sie, trägt
die Zahl den Zusatz **„nur Boss-Kosten, Worker unerfasst"**.
`measure-run.py` rechnet mit expliziten Vier-Satz-Preisen je Modell (seit
27.09.2026 auch opus-5-5, fable-5-1; Sonnet 5 korrigiert auf 2/10);
unbekannte Kennungen fallen markiert auf Fable-Sätze zurück.
