# STATE — <slug>

<!--
VORLAGE für den Schnitt zwischen zwei Boss-Sessions. Kopieren in den
lauf-EIGENEN Ordner — .planning/route/<slug>/ ODER .planning/route-opus/<slug>/,
je nachdem, wo der Lauf lebt (der wörtliche route/-Pfad spaltet einen
route-opus-Lauf lautlos) — als STATE.md ausfüllen, ALLE Kommentarblöcke löschen.

WARUM DIE REGELN DAS LÖSCHEN ÜBERLEBEN (Regel-Anker):
Die ausgefüllte STATE.md ist das Einzige, was die neue Session liest. Stünden die
Schreib-Regeln nur in diesen Kommentaren, kennte die Fortsetzungs-Session sie
nicht und schriebe beim nächsten Schnitt eine schlechtere Datei — ein Verfall,
der sich selbst verstärkt. Die Kommentare stehen zu lassen kostet Bytes in genau
der Datei, die klein bleiben muss. Deshalb tragen zwei billige Träger die Regeln
über den Schnitt:
  1. Die Zeile "Regeln:" unter dem Titel — Pfad auf DIESE Datei, 47 B
     (absolut: C:\Users\User\.claude\skills\route\STATE-TEMPLATE.md).
     Die Rehydrierung ruft sie verbindlich auf ("vor dem Schnitt lesen"). Der
     volle Regeltext bleibt hier und wird vor jedem Schreiben neu geholt.
  2. Die Abschnitts-Überschriften tragen ihre Regel im Klammerzusatz (Cap,
     Präfixe, "leer = verdächtig"). Überschriften sind Inhalt, kein Kommentar —
     sie werden nicht mitgelöscht, und die Regel steht dort, wo sie gebraucht
     wird, auch ohne Rückgriff hierher.
Beide wörtlich übernehmen. Wer sie streicht, schaltet die Vererbung ab.

Harte Grenze: 4096 B für die ausgefüllte Datei (v2, 26.07.2026: von 2048
angehoben — das alte Budget erzeugte Trim-Orgien, gemessen 6 Trim-Commits in
einer Woche plus mehrfach "Zettel-Trim (3x)"; die ~500 Token Mehrkosten je
Rehydrierung sind billiger als jede Trim-Runde). Prüfen mit
    python -c "print(len(open('STATE.md','rb').read().replace(b'\r\n',b'\n')))"
Das `replace` ist der Punkt: unter Windows geschriebene Dateien tragen CRLF und
messen ~50 B schwerer, als das Budget annimmt. Ohne Normalisierung schneidet man
Substanz weg, um Zeilenenden zu bezahlen — genau das erzeugte in einem Lauf 15
Nachkorrektur-Commits. Gemessen wird der Inhalt, nicht die Zeilenenden.
RESERVE: 40 B frei lassen. Der Abschluss (S6) setzt "ABGESCHLOSSEN <Datum>" in
Zeile 1 — ein Lauf ging final 24 B über das Limit, weil genau diese Zeile nach
dem letzten Trim dazukam.

PRIORITÄT BEI ÜBERLAUF (damit nicht improvisiert wird — in dieser Reihenfolge):
Reißt du 4096: (1) "Erledigt" verdichten, (2) Belege auf die härteste Zahl
kürzen, (3) Minors/Gates auf je eine Zeile. Narben zuletzt, Abschnitte nie
streichen. Eine Zeile mehr Narbe ist mehr wert als drei Zeilen Historie.

Regeln:
- Eine Zeile pro Sache, kein Umbruch, kein Fließtext. Belege statt Adjektive.
- Prüffrage je Zeile: "Müsste die neue Session das sonst aus dem Gesprächs-
  verlauf rekonstruieren?" Steht es in PLAN.md — weglassen.
- Neu schreiben an jeder Schnittkante: Interview→Plan, Plan+Kritik→Bau,
  Bau→Verifikation, nach jeder Fix-Runde.

SELBSTTEST VOR DEM STOPP (Pflicht, zwei Minuten):
Lies die fertige STATE.md einmal von oben, als hättest du den Gesprächsverlauf
nie gesehen. Vier Fragen, alle vier müssen "ja" heißen:
  1. Weiß ich ohne Rückfrage, was der nächste Befehl ist — wörtlich?
  2. Ist jede Kennung (E<n>, f<n>, Datei, SHA, UUID) auch ohne Chat auflösbar?
  3. Erkenne ich, ob die letzte Etappe grün oder rot endete — und woran?
  4. Steht kein Satz drin, den ich nur verstehe, weil ich dabei war?
Ein "nein" heißt nachtragen, nicht stoppen. Danach Byte-Größe prüfen.
-->

Regeln: ~/.claude/skills/route/STATE-TEMPLATE.md
Datum: <TT.MM.JJJJ HH:MM> · Boss-S<n> <Modell> · <Standard|RISIKO> · Phase <Interview | Plan+Kritik | Bau E<n> | Verifikation E<n> | Fix f<n> | Abnahme>
Kante: <grün | ROT — <was rot>, kein Commit | GEWAIVT — <gate> <messwert> | n/a — vor dem Bau> · PROBES E<n> <n>/<n> · PLAN <n>k <(+/-n)> · KONTEXT <n>k
Kritik: <b>/<m>/<m> · Wächter <n> · geprüft <k>/<n>
Basis: <sha7 bei Lauf-Beginn> · Sessions: siehe MESSUNG.md
Abgleich: HEAD <sha7> · Branch <name> · Baum <sauber | dirty: pfade>
<!--
Kante = Zustand GENAU an der Schnittkante. "grün" heißt: letzte Etappe verifiziert
UND committet. Sonst ROT nach diesem Muster:
    Kante: ROT — E7 funnel-smoke 228/230 (Preis-Assertions), kein Commit
Wer ROT schreibt, füllt "Nächster Schritt" mit dem Fix-Befehl, nicht mit der
nächsten Bau-Etappe. Die Zeile nie weglassen: fehlt sie, hält die neue Session
einen halben Bau für fertig. GEWAIVT = Oliver hat ein rotes MACHINE-Gate
explizit gewaivt (S4): Messwert bleibt stehen, Commit war erlaubt — RISIKO-
schützende Gates sind nie waivbar. KONTEXT = gemessener Kontextstand
(tools/kontext-jetzt.sh) im Moment der Schnitt-Entscheidung.

PROBES = Rot-Zeugen dieser Etappe (S4-Verifikation): wie viele Maschinen-Prädikate
einmal gegen ihre benannte Mutation rot gesehen wurden, von wie vielen nötig.
Ungleich ⇒ Kante ROT, kein Commit. Ein Prädikat, das nie rot war, hat nie
bewiesen, dass es überhaupt misst — acht von zwölf Läufen sind daran gescheitert.
PLAN = Größe der PLAN.md in KB plus Delta zur Vorsession. Sie rehydriert in
jeder Bau-Session, wächst aber unbeobachtet (gemessenes Maximum 134 KB); die
Zahl ist die einzige Stelle, an der das jemand sieht. Alles gehört in die
Kante-Zeile, nicht in eigene Zeilen — das Byte-Budget hat keinen Platz dafür.

Kritik = Bilanz der EINEN Kritik-Runde (S2 Schritt 3) und Träger der
Wächterliste über die Schnitte: blocker/major/minor, Zahl der Wächter-Punkte
in PLAN.md, davon im Diff-Review abgehakt. Vor der Kritik: "Kritik: —".
Fehlt die Zeile, rollt die neue Session die Einwände als neu wieder auf.

Abgleich = der Wirklichkeits-Test. Eintragen, was beim Schnitt
    git rev-parse --short HEAD · git branch --show-current · git status --porcelain
liefern. Die neue Session vergleicht alle drei, bevor sie irgendetwas anfasst.
Weicht etwas ab, hat eine Parallel-Session gearbeitet — dann gilt STATE.md
nicht mehr ungeprüft. Der Branch ist gleichrangig zu SHA und Baum: drei
verifizierte Etappen landeten einmal auf fremdem Branch, weil nur SHA und
Baum geprüft wurden und beide die ganze Zeit stimmten.

Basis = HEAD bei Lauf-Beginn (Schritt 0), unverändert bis zum Schluss. Nie
verdichten, nie überschreiben: der Diff-Review (S4) liest `git diff <Basis>..HEAD`.
Nach mehreren Etappen-Commits gibt es sonst keinen Weg zurück zu "was dieser
Lauf geändert hat" — man reviewt die letzte Etappe und hält den Lauf für
geprüft.

Sessions = Claude-Session-IDs aller Boss-Sessions dieses Laufs, komma-getrennt
angehängt. **Empfohlen stattdessen: `Sessions: siehe MESSUNG.md`** (45 statt
~120 B). Jede Session schreibt beim Schnitt ihre eigene Zeile mit VOLLER
Kennung dorthin — `tools/kanten-messung.py <lauf-ordner>`, vom Commit-Gate
erzwungen. Das ist keine Kürzung, sondern eine Abtretung: die Liste steht
vollständig woanders, und der Abschluss-Bericht rechnet ohnehin von dort.
Die Handliste hat gemessen versagt — zwei von drei geprüften Läufen trugen
eine Kennung, die nie eine Datei getragen hat, und in einem dritten drückte
das Byte-Budget die Liste in einen Eltern-Commit.

ABSCHLUSS: S6 setzt Zeile 1 auf "ABGESCHLOSSEN <Datum>", ein Abbruch auf
"ABGEBROCHEN <Datum> — <Grund>". Ohne Marker hält das nächste /route den
fertigen Lauf für eine offene Fortsetzung.

"Kante: n/a — vor dem Bau" gilt an den Kanten Interview→Plan und
Plan→Bau: dort wurde weder verifiziert noch committet, "grün" wäre gelogen.
Ebenso sind leere Narben dort normal — die Regel "leer = verdächtig" greift
erst nach der ersten Bau-Etappe.
-->

## Rehydrierung

<!-- Bleibt wörtlich stehen, inklusive Prüf- und Regel-Zeile. -->
Lies SKILL.md → dies → PLAN.md; sonst nichts — der Rest sind Belege.
Erst HEAD-SHA + `git branch --show-current` + `git status --porcelain` gegen
"Abgleich" — Abweichung = fremde Arbeit, klären statt bauen. Lücke hier ergänzen.
Vor dem nächsten Schnitt: "Regeln:"-Datei lesen — Schreib-Regeln nur dort.

## Erledigt (1/Etappe · >6: älteste sammeln)

<!-- Je Etappe/Fix EINE Zeile: Kennung — Commit-SHA (oder "kein Commit") — härtester
     Prüfbeleg als Ergebnis, nicht als Beschreibung.
     VERDICHTEN ab der 7. Etappe: alles außer den letzten drei zu einer Zeile
     "E0-E4 — <SHA der letzten> — <ein gemeinsamer Prüfbeleg>". Die letzten drei
     bleiben einzeln, weil nur dort noch etwas rückgängig gemacht wird. Ein Lauf
     mit E0-E7 passt sonst nicht ins Byte-Budget. -->
- <E0-E4 — 5def76b — cockpit-eq IDENTISCH, Funnel-Smoke 230/230>
- <E5 — a0a6012 — AGB aus Quelle erzeugt, --verify Absatz-Mapping grün>

## Offen

<!-- Nur Ungebautes, in Reihenfolge, je eine Zeile. Details stehen in PLAN.md. -->
- <E6 AGB-Quelle + Generator>

## Narben (max 6 · VERWORFEN/WIDERLEGT/FALSCH-GRÜN/NEU-GEEICHT · leer = verdächtig)

<!--
DAS ENTSCHEIDENDE FELD: was NICHT aus PLAN.md rekonstruierbar ist — teuer
erkaufte Erkenntnis aus dem Bauen. Fehlt sie, läuft die neue Session in dieselbe
Sackgasse, kippt eine getroffene Entscheidung oder vertraut einem blinden
Wächter. Max 6 Zeilen, je ~85 Zeichen (Byte-Budget oben), Präfix mitschreiben:

VERWORFEN:   Alternative/Sol-Vorschlag abgelehnt + Grund. Sol schlägt es sonst
             erneut vor und der neue Boss nimmt es arglos an.
WIDERLEGT:   Plan- oder Doku-Annahme hat sich beim Bauen als falsch erwiesen.
FALSCH-GRÜN: Prüfung grün ohne Aussagekraft (blinder Wächter) ODER rot ohne
             echten Fehler. Immer mit Grund — sonst wird es neu "gefixt".
NEU-GEEICHT: Golden/Baseline bewusst verschoben. Diff ist gewollt, kein Drift.

Leer lassen ist fast immer falsch. Nach einer Bau-Etappe gibt es Narben.
Sind es mehr als 6: die schwächste streichen, nicht die neueste.
-->
- <VERWORFEN: Entwurf-Banner in AGB — stattdessen Gate-Liste im Kopf (Oliver)>
- <WIDERLEGT: Runbook "seit 12.07. live" — real standen alte Preise>
- <FALSCH-GRÜN: gen-...py --verify rot = Provenienz-Zyklus, kein Inhaltsdrift>
- <NEU-GEEICHT: goldens/ nach E1 neu; nur Basis darf abweichen, Overlay nicht>

## Offene Minors

<!-- Aus der Plan-Kritik bewusst nicht umgesetzt. Ohne diese Liste rollt die neue
     Session sie als "neue Einwände" wieder auf. -->
- <...>

## Codex

<!-- Ohne Session-UUID ist die Fix-Kette nach dem Schnitt nicht sicher fortsetzbar.
     "Sol nie .git" heißt: der Boss committet je Etappe, Sol fasst .git nie an
     (Windows index.lock). Beide Zeilen wörtlich übernehmen.
     Hat eine Etappe per Worker-Wahl (S3) Kimi als Worker, kommt EINE Zeile dazu:
         Worker: Kimi (E<n>) — resume nur via kimi-worker.sh (T8-Gate), sonst build
     Die Kimi-Session-ID liegt im SKILL-Ordner (.kimi-session-<slug>.build),
     nicht in .planning/ — ihr Fehlen dort ist keine Divergenz. -->
Sandbox: Kritik read-only · Bau workspace-write (resume erbt, kein -s) · Sol nie .git
Resume: <live|keine> · <UUID|-> · nie `resume --last` (Parallel-Sessions)
<!--
UUID SOFORT nach dem ERSTEN codex exec dieses Laufs eintragen, nicht erst beim
Schnitt — dann ist der exec-Output oft schon aus dem Kontext gefallen. Quelle:
der exec-Output selbst oder der Dateiname unter
~/.codex/sessions/JJJJ/MM/TT/rollout-*-<UUID>.jsonl.
`--last` erwischt in diesem Projekt eine fremde Parallel-Sitzung. Sol-Etappen
immer (globales -C VOR dem Subcommand — resume erbt das Arbeitsverzeichnis
NICHT, danach die workdir:-Logzeile gegen das Zielrepo prüfen):
    codex -C <repo> exec resume <UUID> "<delta>"
Kimi-Etappen: kimi-worker.sh resume <slug> … — das T8-Gate im Worker
entscheidet; blockt es (Exit 6), frischer build mit Delta + PLAN.md/STATE.md.
Noch kein exec gefahren: "Resume: keine · -".
-->

## Gates Oliver

<!-- Was ohne den Menschen nicht weitergeht. Sonst baut die neue Session daran vorbei. -->
- <Sichtabnahme E2 offen; kein Deploy, kein Push>

## Nächster Schritt

<!-- EIN Imperativ + wörtlicher Befehl. Kein "man könnte", keine Optionen.
     Bei "Kante: ROT" steht hier der Fix, nicht die nächste Etappe. -->
<Baue E6: codex exec resume <UUID> mit dem Delta aus PLAN.md, Abschnitt E6.>
