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

**Herkunft der Klassen:** gemessen an 25+ Arbeitsstücken realer Läufe
(07–08/2026); die Klassen waren danach stabil. Eigene Messzeilen sind
optional — die Schranke fragt nur die Klassen ab. Urteilt sie ZWEIMAL falsch
(ein Stück passte laut Klasse und riss trotzdem die Zone, oder umgekehrt),
wieder messen statt glauben: `vor`/`nach` aus `tools/kontext-jetzt.sh`.

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

## Gemessene Einträge (optional, eigene Läufe)

| Datum | Lauf | Arbeitsstück | vor | nach | Kosten | Klasse |
| --- | --- | --- | --- | --- | --- | --- |
