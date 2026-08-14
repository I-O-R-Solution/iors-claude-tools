---
description: Persoenliche globale CLAUDE.md aus Betriebswissen aufbauen oder warten — Fragen ueber deine Arbeit statt ueber Claude, Sortierung an den richtigen Ort, /context-Check zum Schluss
argument-hint: [leer — der Command fuehrt durch alles]
allowed-tools: Read, Write, Edit, AskUserQuestion, Glob
disable-model-invocation: true
---

Du baust mit dem User seine **persoenliche globale CLAUDE.md** (`~/.claude/CLAUDE.md`).
Sie laedt in JEDER Claude-Code-Sitzung, in jedem Ordner. Sie beschreibt die Person, nicht
ein Projekt.

**Der Kern dieses Ablaufs:** Du fragst den User NICHT, was er von Claude will. Darauf
antwortet ein Einsteiger mit Allgemeinplaetzen ("bei Unsicherheit fragen"), und genau die
Sorte Zeile ist wertlos — Claude tut das ohnehin. Du fragst ihn nach **seiner Arbeit**:
Vokabular, Hoheiten, Empfaengerkreis, Hausregeln. Das kann Claude nicht erraten. Nur daraus
entstehen Zeilen, die etwas aendern.

<!-- Belegbasis, frisch abgerufen 2026-08-14 von code.claude.com/docs/en/memory und
     /docs/en/best-practices:

     ZWECK: Scope-Tabelle — "User instructions | ~/.claude/CLAUDE.md | Personal
     preferences for all projects | ... | Just you (all projects)". Die Achse ist das
     PROJEKT, nicht die Zeit.

     GROESSE: "target under 200 lines per CLAUDE.md file. Longer files consume more
     context and reduce adherence." Gilt ausdruecklich PRO DATEI. Eine summierte
     Obergrenze ueber die Import-Kette ist NICHT belegt — die harte 200-Zeilen/25-KB-
     Grenze gilt laut "This limit applies only to MEMORY.md" nur fuer die Auto-Memory.
     CLAUDE.md wird nie abgeschnitten: "CLAUDE.md files are loaded in full regardless of
     length, though shorter files produce better adherence."

     STREICHTEST: "For each line, ask: 'Would removing this cause Claude to make
     mistakes?' If not, cut it. Bloated CLAUDE.md files cause Claude to ignore your
     actual instructions!" — Das ist das einzige belegte Pruefkriterium pro Zeile.
     ACHTUNG: Der Name "Golden Rule" steht in KEINER der beiden Seiten. Nicht so nennen.

     AUFNAHME: "Add to it when: Claude makes the same mistake a second time ... You type
     the same correction or clarification into chat that you typed last session."
     Und: "Keep it to facts Claude should hold in every session".

     AUSSORTIEREN: "If an entry is a multi-step procedure or only matters for one part of
     the codebase, move it to a skill or a path-scoped rule instead."

     KEINE DURCHSETZUNG: "CLAUDE.md content is delivered as a user message after the
     system prompt, not as part of the system prompt itself." Und: "To block an action
     regardless of what Claude decides, use a PreToolUse hook instead."

     WIDERSPRUECHE: "if two rules contradict each other, Claude may pick one arbitrarily."

     IMPORTE: "Splitting into @path imports helps organization but doesn't reduce
     context, since imported files load at launch."

     ZWEITER ORT: "Personal rules in ~/.claude/rules/ apply to every project on your
     machine. Use them for preferences that aren't project-specific." Ohne
     paths:-Frontmatter laden sie aber genauso mit — sie sparen nichts, sie ordnen nur.

     SPEZIFITAET: "Use 2-space indentation" statt "Format code properly"; "concrete
     enough to verify". Betonung ist erlaubt: "You can tune instructions by adding
     emphasis (e.g., 'IMPORTANT' or 'YOU MUST') to improve adherence" — eine Obergrenze
     dafuer nennt die Doku NICHT.

     NACHWEIS: "/context and check the list under Memory files to verify your CLAUDE.md
     ... loaded."

     NICHT BELEGT und deshalb im Ablauf als SETZUNG gekennzeichnet: das Kontingent von
     15 neuen Zeilen pro Durchgang, die Zurueckhaltung bei ~/.claude/rules/, der Verzicht
     auf /doctor (dessen Trim-Vorschlag laut Changelog erst ab v2.1.206 existiert und
     dessen Version auf einem fremden Rechner ungemessen ist). -->

**Ton.** Antworte in der Sprache des Users. Zielgruppe sind Einsteiger ohne
Programmierkenntnisse. Kurze Saetze. Die Woerter *Hook*, *Rule*, *Skill*, *Scope*,
*Kontext* kommen im Gespraech NICHT vor — nur in `einrichtung-offen.md`, und dort
erklaert.

---

## Schritt 0 — Messen, bevor gefragt wird

1. `Read` auf `~/.claude/CLAUDE.md`.
2. Jede Zeile, die mit `@` beginnt, ist ein Import: **die genannte Datei mitlesen.** Ohne
   das haeltst du fuer fehlend, was eine Datei weiter laengst dasteht.
3. `Glob` auf `~/.claude/rules/*.md` und `Read` auf `~/.claude/einrichtung-offen.md`
   (beide duerfen fehlen).
4. Zeilen **jeder Datei einzeln** zaehlen und einzeln gegen 200 halten. Die Summe der
   Kette darfst du nennen — aber als Information, NIE als Grenzwert. Ein summiertes
   Budget ist nicht belegt.
5. **Themenliste bauen — der wichtigste Teil dieses Schritts.** Geh die gelesene Kette
   durch und notiere dir, welche der zehn Themen dieses Ablaufs dort **schon geregelt
   sind**, mit Datei und Zeile. Ein Thema gilt als geregelt, wenn es irgendwo in der Kette
   steht — in welcher Formulierung auch immer, in welcher Datei der Kette auch immer.

   Die Themen sind bewusst lang benannt. Kurznamen sind mehrdeutig, und ein Filter, der
   das falsche Thema abhakt, unterdrueckt eine Frage lautlos:

   | Thema | geregelt in |
   |---|---|
   | Beruf des Users und an wen seine Texte gehen | |
   | Antwortsprache, Ton und Antwortlaenge | |
   | Wie in seinem Haus geschrieben wird (Anrede, Aufbau, Grussformel) | |
   | Welche Abkuerzungen und Hausbegriffe bei ihm was bedeuten | |
   | Welche Zahlen und Zusagen nur andere Personen festlegen duerfen | |
   | Welche Angaben in keinem Beispiel und keiner Vorlage stehen duerfen | |
   | Was zu tun ist, wenn eine Angabe zur Aufgabe fehlt | |
   | Aus welchem Programm oder Ordner seine Arbeitsdaten stammen | |
   | Woran der User erkennt, dass ein Text fertig ist | |
   | Was er mit dem Ergebnis macht (Outlook, Word, Ausdruck) | |

   **Im Zweifel gilt ein Thema als NICHT geregelt.** Der Filter darf nur greifen, wenn die
   gefundene Stelle dieselbe Sache meint, nicht nur ein aehnliches Wort benutzt. Eine
   Regel darueber, wie Claude seine eigenen Aussagen kennzeichnet, ist NICHT dasselbe wie
   die Angabe, aus welchem Programm die Arbeitsdaten kommen — auch wenn in beiden das Wort
   "Herkunft" vorkommt. Eine zu viel gestellte Frage kostet zwanzig Sekunden; eine zu
   wenig gestellte kostet eine Schutzregel.

   Diese Liste steuert ab hier den ganzen Ablauf. Ohne sie fragst du ab, was laengst
   dasteht — und der User steigt beim dritten "das steht doch schon da" aus.

Das Ergebnis setzt den Modus:

| Befund | Modus |
|---|---|
| Datei fehlt oder ist leer | **AUFBAU** |
| Datei hat Inhalt | **WARTUNG** |

Ab hier gilt in beiden Modi unverruecklich: **Bestehende Zeilen werden nie umformuliert,
nie umsortiert, nie gekuerzt, nie geloescht. Importierte Dateien werden nie geschrieben.**

---

## Schritt 1 — Rahmen, Umfang, Ausstiegsvertrag

Vier Saetze an den User:

> "Diese Datei gilt in JEDEM Ordner und beschreibt dich, nicht ein Projekt."
> "Ich frage dich nicht, was du von Claude willst — ich frage dich nach deiner Arbeit."
> "Ich schreibe nichts, bevor du die fertige Datei gesehen und Ja gesagt hast."
> "Du kannst nach jedem Abschnitt aufhoeren. Dann schreibe ich, was bis dahin steht.
> Brichst du mittendrin ab, schreibe ich nichts — dann fangen wir beim naechsten Mal neu an."

Der letzte Satz ist woertlich einzuhalten. Es gibt keinen Zwischenspeicher; versprich
keinen.

Dann EINE `AskUserQuestion` zum Umfang. **Keine Minutenangaben** — wie lange es dauert,
ist nicht gemessen:

- Header `Umfang`, Frage: *"Wie ausfuehrlich sollen wir das machen?"*
- *"Nur das Noetigste"* → **KURZLAUF**: Bloecke A und C
- *"Mittel"* → **MITTELLAUF**: Bloecke A, C, D
- *"Ausfuehrlich"* → **VOLLLAUF**: alle vier Bloecke, mit einem Beispieltext

**Nenne die Fragenzahl erst NACH dem Bestandsfilter — und nur die, die wirklich kommen.**
Ungefiltert waeren es 10, 17 und 19; wie viele davon uebrig bleiben, ergibt erst der
Abgleich mit der Themenliste aus Schritt 0. Rechne das aus, bevor du eine Zahl nennst.
Eine angesagte Zahl, die dann nicht stimmt, ist schlimmer als gar keine.

**Kuendige vor jedem Block die verbleibende Zahl an** ("Block C: drei Fragen, danach
kannst du aufhoeren"). Ein User, der nicht weiss, wie viel noch kommt, steigt in der Mitte
aus.

**Im Modus WARTUNG zusaetzlich, vor der Umfangsfrage:**

Zeige die Ueberschriften **der ganzen Kette**, jede mit ihrer Herkunftsdatei — nicht nur
die der `CLAUDE.md`. Steht die Substanz in einer per `@` geholten Datei, sieht der User
sonst eine fast leere Liste und haelt alles fuer ungeregelt, was eine Datei weiter
ausformuliert dasteht.

Dann die Themenliste aus Schritt 0 zeigen: was schon geregelt ist und wo. Sag dazu den
Satz: *"Diese Themen frage ich nicht noch einmal."*

Existiert `einrichtung-offen.md`, ihre offenen Punkte ZUERST zeigen und *"die offenen
Punkte jetzt nachholen"* als erste Antwortmoeglichkeit anbieten. Dann fragen: nachholen,
ergaenzen, oder nur pruefen. Bei *nur pruefen* nichts schreiben, direkt zu Schritt 12.

**Ausstiegsvertrag, ab hier nach JEDEM Block** — eine Frage mit drei Antworten:
*"Passt, weiter"* / *"Aendern"* / *"Reicht mir, speichern"*. Bei der dritten sofort zu
Schritt 9, ohne Ueberredung.

**Genervt-Erkennung:** Nur **freier Text** zaehlt als Signal — zweimal hintereinander
"egal"/"ist mir gleich", Ein-Wort-Antworten ohne Inhalt, oder die Frage "wie lange noch".
Ein Klick auf *"Passt, weiter"* ist ausdruecklich KEIN Abbruchsignal, sondern Zustimmung.
Bei Verdacht nicht still abbrechen, sondern einmal nachfragen: *"Sollen wir hier
aufhoeren und das Bisherige sichern?"*

**HARTE REGEL: Aus einer Nicht-Antwort wird NIE eine Zeile.** Einzige Ausnahme: die
Antwortsprache darf aus dem Gespraech abgeleitet werden — und du sagst, dass du das tust.

---

## Schritt 2 bis 5 — Die vier Bloecke

**BESTANDSFILTER, gilt fuer JEDE Frage aller vier Bloecke.** Bevor du eine Frage stellst,
sieh in der Themenliste aus Schritt 0 nach. Steht das Thema dort als geregelt: **Frage
still ueberspringen.** Nenne am Ende des Blocks in einem Satz, was du warum uebersprungen
hast — *"Nach Sprache und Ton habe ich nicht gefragt, das steht in `AGENTS.md` Zeile 30."*

Bleibt von einem Block keine einzige Frage uebrig, entfaellt der ganze Block samt
Vorsatz. Das ist kein Mangel, sondern das erwuenschte Ergebnis: Der Ablauf fragt nur nach
Luecken. Sind alle zehn Themen geregelt, sag das offen und geh direkt zu W1 und W2 — die
laufen immer, weil sie nach Wirkung fragen, nicht nach Inhalt.

**Ausnahme:** Ist das Thema zwar geregelt, aber die bestehende Zeile nennt keinen
Wortlaut, keine Zahl, keinen Namen und keinen Pfad, darfst du EINMAL nachschaerfen —
nicht neu fragen, sondern die bestehende Zeile zitieren und um die fehlende Konkretisierung
bitten. Die alte Zeile wird dadurch nie ersetzt (siehe harte Regeln); es entsteht eine
zusaetzliche.

Vor jedem Block, der uebrig bleibt, **ein Satz, was ohne diese Angaben passieren KANN**.
Das ersetzt die Fehlererfahrung, die ein User am ersten Tag noch nicht hat. Formuliere als
Moeglichkeit, nicht als Tatsachenbehauptung ueber dein eigenes Verhalten — gemessen ist es
nicht.

**Werkzeugwahl, wichtig:** `AskUserQuestion` ist ein AUSWAHL-Werkzeug und braucht
vorgegebene Antworten. Offene Fragen stellst du als normale Chat-Frage. Wo du Auswahl
nutzt, erlaube Mehrfachnennung und ergaenze *"kommt auf den Vorgang an"*. Ein angeklickter
Optionstext ist nie ein woertliches Zitat des Users.

### Block A — Vokabular setzen (im Modus AUFBAU Pflicht, im Modus WARTUNG gefiltert)

Vorsatz: *"Ohne diese Angaben halte ich dich moeglicherweise fuer einen Programmierer,
gebe dir Formatierungszeichen zurueck und benutze Fachwoerter ohne Erklaerung."*

Offene Chat-Fragen:

- **A1** "Was steht auf deiner Visitenkarte — und was machst du davon an einem normalen
  Dienstag wirklich?"
- **A2** "An wen gehen deine Texte meistens: Privatkunde, Firmenkunde, Werkstatt,
  Hersteller, Versicherung?"
- **A3** "Siezt oder duzt ihr eure Kunden — und wie redet ihr intern miteinander?"

Als Auswahl:

- **A4** Zeig ZWEI Antworten auf dieselbe Beispielfrage — eine mit drei Saetzen, eine mit
  einer halben Seite. Frage: *"Welche haettest du lieber, und was fehlt der kurzen?"*
  Frag NIE "wie lang sollen Antworten sein" — darauf sagt jeder "kurz" und meint es nicht.
  Aus der Antwort muss eine ZAHL werden ("hoechstens fuenf Saetze").
- **A5** "Was machst du mit dem Ergebnis — in Outlook einfuegen, in Word weiterbearbeiten,
  ausdrucken?"

Die Antworten aus A liefern die Beispiele, mit denen du **jede** spaetere offene Frage
bebilderst. Ohne Beispiel aus seiner eigenen Welt friert ein Einsteiger bei einer offenen
Frage ein.

**Faellt Block A dem Bestandsfilter zum Opfer, nimm die Beispiele aus dem Bestand** —
Rolle, Empfaengerkreis und Anrede stehen dann ja bereits in der Kette. Ein uebersprungener
Block A darf nie dazu fuehren, dass spaetere Fragen unbebildert gestellt werden.

### Block B — Material (nur VOLLLAUF)

Vorsatz: *"Wie ihr schreibt, kann ich nicht raten — ich kann es nur ablesen."*

- **B1** "Kopier mir EINEN Text herein, den du letzte Woche verschickt hast und mit dem du
  zufrieden warst. Umbrueche stoeren nicht."
  **Die Anonymisierung buerdest du NICHT dem User auf.** Sag zu: *"Namen, Kennzeichen und
  Nummern ersetze ich beim Lesen durch Platzhalter — die landen in keiner Datei."* Und halte
  das ein. Frag nicht nach einem Dateipfad; ein Serviceberater weiss nicht, was das ist.
- **B2** "Und ein Text, bei dem dich jemand korrigiert hat — was war der Vorwurf?"

Aus B1 leitest du **3 bis 6 beobachtete** Konventionen ab, jede mit der Stelle, an der sie
sichtbar ist (Anrede, Laenge, Grussformel, Reihenfolge, Umgang mit Preisen). Der User hakt
nur ab oder streicht. Aus B2 entstehen Verbotszeilen.

Wird der Block uebersprungen, **benenne das im Abschluss** ("Formregeln fehlen, weil kein
Beispieltext vorlag") — nicht stillschweigend auslassen.

### Block C — Einarbeitungs-Rahmen (im Modus AUFBAU Pflicht, im Modus WARTUNG nach W1/W2 und gefiltert)

Vorsatz: *"Du kennst meine Fehler noch nicht — aber die eines neuen Kollegen kennst du
auswendig. Es sind oft dieselben."*

Offene Chat-Fragen, jede mit einem Beispiel aus Block A bebildert:

- **C1** "Ein neuer Kollege faengt bei dir an. Was erklaerst du ihm am ersten Tag, weil er
  es sonst garantiert falsch macht?"
- **C2** "Was musstest du deinem letzten Neuen ZWEIMAL sagen?"
- **C3** "Welche drei Abkuerzungen benutzt ihr taeglich, die ein Aussenstehender nicht
  kennt?"
- **C4** "Welche zwei Dinge werden bei euch staendig verwechselt — auch von Kollegen?"
- **C5** "Gibt es ein Wort, das viele benutzen, das bei euch aber falsch ist?"

C2 ist die **Uebertragung** des Doku-Aufnahmetriggers auf menschliche Einarbeitung — die
Doku meint Korrekturen an Claude, nicht an Kollegen. Nenne das so, wenn es zur Sprache
kommt; behaupte nicht, es sei dasselbe.

Spiegele jede Antwort SOFORT als Kandidatenzeile zurueck, damit der User den Sprung von
seiner Formulierung zur Regel sieht.

### Block D — Hoheiten und Grenzen (MITTELLAUF und VOLLLAUF)

Vorsatz: *"Fehlt mir eine Zahl, koennte ich die Luecke hilfsbereit mit einem plausiblen
Wert fuellen. Welche Felder das nicht vertragen, weisst nur du."*

- **D1** "Welche Zahlen in deinem Alltag darf niemand ausser einer bestimmten Person
  festlegen — und wer ist das?"
- **D2** "Welche Zusage darfst du selbst nicht machen — Termin, Garantie, Kulanz,
  Lieferzeit?"
- **D3** "Woher kommen die Angaben, mit denen du arbeitest — welches Programm, welcher
  Ordner?"
- **D4** "Welche Angaben duerfen in keinem Beispiel und keiner Vorlage stehen?"
- **D5** "Bei welcher Sorte fehlender Angabe soll ich stehenbleiben — und wo darf ich
  selbst entscheiden?"
- **D6** "Woran erkennst DU, dass ein Text fertig ist — was pruefst du als Letztes?"
- **D7** "Welche Aufgabe machst du jede Woche gleich, in mehreren Schritten nacheinander?"

D7 erzeugt bewusst KEINE Zeile in der Datei, sondern einen Eintrag in der offenen Liste —
mehrschrittige Ablaeufe gehoeren laut Doku nicht in die CLAUDE.md.

**Wird Block D uebersprungen (KURZLAUF), sag diesen Satz woertlich:** *"Was du NICHT
entscheiden darfst — Preise, Zusagen, Kundendaten — haben wir heute nicht besprochen. Bis
wir das nachholen, pruef diese Stellen selbst nach."*

### WARTUNG-Zusatz — ersetzt Block C als Einstieg

- **W1** "Welche Zeile in deiner Datei hat in den letzten vier Wochen tatsaechlich einen
  Fehler verhindert — und welche faellt dir gerade zum ersten Mal wieder auf?"
- **W2** "Welche Korrektur hast du in den letzten drei Sitzungen mehr als einmal getippt?"

W2 ist der belegte Aufnahmetrigger. W1 erzeugt eine **Streichliste** — die wird gezeigt und
in `einrichtung-offen.md` notiert, aber **nichts wird geloescht** (siehe harte Regeln).

---

## Schritt 6 — Herkunftsstempel (intern, nie im Chat)

Jede Kandidatenzeile traegt intern drei Felder:

| Feld | Inhalt |
|---|---|
| `woher` | woertliches Zitat des Users · Beobachtung am Material · Ableitung |
| `ohne sie passiert` | konkreter Schaden |
| `Zielort` | wird in Schritt 7 gesetzt |

**Ohne zitierbaren Ursprung entsteht keine Zeile.**

Ableitungen formulierst du NIE als Vorschlag, sondern als Frage mit eingebautem Ausstieg,
negativ gestellt: *"Du hast X gesagt. Was ginge schief, wenn ich das NICHT taete? Und gilt
das immer, oder war das nur dieser eine Fall?"* Auf "willst du das?" sagt jeder Ja.

Diese Schadensfrage stellst du **nur bei echten Ableitungen** — nicht bei woertlichen
Angaben wie Abkuerzungen, Anrede oder Programmnamen. Die tragen ihre Herkunft im Zitat.
Und biete bei Bedarf zwei konkrete Folgen zur Auswahl an, statt offen nach dem Schaden zu
fragen: Ein User, der Claude gestern installiert hat, kennt die Folgen nicht.

"Kann man so machen" und Zoegern zaehlen als Nein. Nur ein aktives "ja, genau so" haelt
eine Zeile. **Formuliert wird in SEINEN Woertern** — Umformulieren ist die getarnte Form
des Erfindens.

---

## Schritt 7 — Der stille Router: vier Tore

Der User hoert keines dieser Woerter. Du sortierst im Kopf.

| Tor | Frage | Bei Nein |
|---|---|---|
| **1 Ordner-Test** | "Gilt die Zeile in JEDEM Ordner, in dem du heute arbeitest?" | Projekt-Notiz, Verweis auf `/spark` |
| **2 Fakt oder Verfahren** | Ist es ein Fakt fuer jede Sitzung? | Mehrschrittig → Skill-Notiz. Nur ein Teilbereich → Rule-Notiz |
| **3 Streichtest** | "Wuerde ihr Wegfall einen Fehler erzeugen?" | streichen |
| **4 Bitte oder Schloss** | Muss es ausnahmslos gelten? | Hook-Notiz — die Zeile bleibt als Bitte, aber Schritt 12 sagt den ehrlichen Satz dazu |

Tor 1 fragt nach dem **Ordner**, nicht nach der Ewigkeit. Frag NIE, ob eine Zeile einen
Jobwechsel ueberlebt — der Ewigkeitstest streicht genau die wertvollen Zeilen
(Systemname, Preisliste, Freigabekette) und behaelt die wertlosen.

Nur was alle vier Tore passiert, wird eine Zeile.

---

## Schritt 8 — Widerspruchspruefung gegen den Bestand

**Pflicht, auch im Modus AUFBAU** (dort gegen eine etwaige importierte Datei).

Halte jede Kandidatenzeile gegen die in Schritt 0 gelesene Kette: Ist dasselbe Thema schon
geregelt? Bei Treffer zeigst du dem User **beide Zeilen als Paar** — alte und neue — und
fragst: gilt die neue zusaetzlich, oder ersetzt sie die alte?

Bei *ersetzt*: Die alte Zeile wird trotzdem NICHT geloescht (siehe harte Regeln). Notiere
sie stattdessen in `einrichtung-offen.md` unter "Streichkandidaten" und sag dem User, dass
er sie selbst entfernen muss.

Belegt: *"if two rules contradict each other, Claude may pick one arbitrarily."* Ein
Widerspruch ist schlimmer als eine fehlende Regel.

---

## Schritt 9 — Schaerfen und deckeln

- **Jede Zeile enthaelt einen Wortlaut, eine Zahl, einen Namen, einen Befehl oder einen
  Pfad.** Sonst zurueck mit einer konkretisierenden Frage: "kurz halten" → "hoechstens wie
  viele Zeilen?" Doku-Massstab: *concrete enough to verify*.
- **Eine Regel = ein Bullet** unter einer thematischen Ueberschrift. Keine Fliesstext-
  Absaetze mit mehreren Regeln.
- **Betonung** (`IMPORTANT`, Grossbuchstaben) nur auf Zeilen, deren Bruch Geld, Kunden oder
  Daten kostet. Sind es mehr als eine Handvoll, ist die Datei zu voll — nicht die Betonung
  zu knapp. *(Eine Obergrenze nennt die Doku nicht; dass Betonung wirkt, ist belegt.)*
- **Kontingent: hoechstens 15 neue Zeilen pro Durchgang.** Ueberschuss wandert in die
  offene Liste. **Sag im Chat dazu, dass diese Zahl eine Setzung ist, kein Doku-Fakt** —
  belegt ist nur die Zielmarke von unter 200 Zeilen pro Datei.
- **SINNUMKEHR-GUARD.** Wortform allein genuegt nicht. Lies dem User vor dem Schreiben jede
  Verbots- und Erlaubniszeile einmal **als ausgefuehrte Anweisung rueckwaerts** vor:
  *"Heisst das: ich werde ab jetzt ...?"* Nur diese Rueckwaertslesung faengt die Umkehr.
  *(Eine Vorfassung dieses Ablaufs schrieb abgefragte Verbote unter die Ueberschrift
  `# Immer` — aus "nie Preise festlegen" wurde eine Daueranweisung, Preise festzulegen.)*
- **DATENHYGIENE-GUARD.** Kandidatenzeilen aus Block B gegen echte Namen, Kennzeichen,
  Fahrgestell- und Telefonnummern pruefen und durch Platzhalter ersetzen. Was aus einem
  eingefuegten Text stammt, darf nie roh in eine Datei, die in jedem Ordner mitlaedt.

---

## Schritt 10 — Gegenlesen am Entwurf

Nimm den Entwurf als Vorgabe, loese eine kleine echte Aufgabe des Users damit (mit
Platzhaltern statt echter Kundendaten), zeig das Ergebnis und frag: *"Was wuerdest du daran
aendern?"* Jede Korrektur wird eine neue Zeile oder entlarvt eine bestehende als
wirkungslos.

**Nenne das nicht eine Messung.** Die Datei ist noch nicht geschrieben und damit nicht als
Instruktionsdatei geladen — der Entwurf wirkt hier nur als Gespraechsinhalt. Sag ehrlich:
*"Das ist ein Gegenlesen am Entwurf, kein Beweis."* Echte Wirkung zeigt sich erst nach dem
Neustart, und das ist der zweite Durchgang.

**Im Modus WARTUNG** laeuft das Gegenlesen gegen die **bestehende** Datei und zeigt
zusaetzlich, welche vorhandenen Zeilen nicht gegriffen haben. Diagnose in dieser
Reihenfolge: (1) Datei zu lang, Regel geht unter → kuerzen vorschlagen; (2) Formulierung
mehrdeutig → schaerfen; (3) muss ausnahmslos gelten → Hook-Notiz.

---

## Schritt 11 — Zeigen, bestaetigen, schreiben

**Erst zeigen.** Die vollstaendige Datei im Chat. Im Modus WARTUNG jede neue Zeile als
**NEU** markiert, der Bestand woertlich unveraendert daneben. Zeilenzahl jeder Datei der
Kette einzeln gegen 200 stellen, Summe nur als Information.

**Dann bestaetigen lassen.** EINE Frage: so schreiben, oder etwas aendern? Erst nach dem Ja
wird geschrieben. Wer gerade diktiert hat, dass nichts ohne seine Freigabe passiert, darf
das nicht als Erstes gebrochen sehen.

**Dann den Dialog ansagen** — vor dem Schreiben, woertlich:

> "Gleich fragt dich Claude, ob es ausserhalb deines Arbeitsordners schreiben darf. Sag Ja
> — deine persoenliche Datei liegt dort, das ist so gewollt."

Lehnt der User ab: nicht abbrechen. Die fertige Datei im Chat stehen lassen und den Pfad
nennen, damit er sie selbst anlegen kann.

**Dann schreiben.**

| Modus | Werkzeug |
|---|---|
| **AUFBAU** (Datei fehlt) | `Write` auf `~/.claude/CLAUDE.md` |
| **WARTUNG** (Datei existiert) | ZUERST `Write` einer Sicherung nach `~/.claude/CLAUDE.md.bak-<JJJJ-MM-TT>`, dann **`Edit`** — neue Bloecke ans Dateiende anfuegen |

Der Suffix mit Bindestrich und Datum ist Absicht: `~/.claude` ist bei manchen Nutzern ein
Git-Repo, und dessen `.gitignore` faengt Sicherungen ueblicherweise ueber das Muster
`*.bak-*`. Eine Datei `CLAUDE.md.bak` ohne Suffix bliebe unversioniert im Arbeitsverzeichnis
liegen und taucht ab da in jedem `git status` auf.

**Im Modus WARTUNG ist `Write` auf die CLAUDE.md verboten.** `Write` ersetzt die Datei
vollstaendig; der Bestand muesste durch deine Hand rekonstruiert werden, und dabei geht
zuverlaessig etwas verloren oder wird stillschweigend umformuliert. `Edit` fasst nur an,
was du ausdruecklich benennst.

Importierte Dateien (`@`-Zeilen) werden NIE geschrieben.

Danach `Write` auf `~/.claude/einrichtung-offen.md` — nur wenn nicht leer. Existiert sie
schon, mit Datums-Ueberschrift **anhaengen** statt ueberschreiben.

---

## Schritt 12 — Zurueckmessen und Takt setzen

`Read` auf die geschriebene Datei. Pfad und Zeilenzahl nennen. Weicht der Inhalt von dem
ab, was du gezeigt hast, sag es und korrigiere — nicht beschoenigen. Im Modus WARTUNG
zusaetzlich pruefen, dass **jede** bestehende Zeile noch woertlich dasteht.

Dann der Handgriff, woertlich vorgegeben:

> "Tipp `/exit` und Enter. Dann im selben Fenster `claude` eingeben und Enter. Dann
> `/context`. Unter **Memory files** muss `~/.claude/CLAUDE.md` stehen."

Sag dazu: In der **jetzigen** Sitzung taucht sie dort noch nicht auf — das ist normal, die
Datei wird beim Start gelesen. Steht sie nach dem Neustart nicht dort: nicht raten, Pfad
und exakte Schreibweise `CLAUDE.md` in Grossbuchstaben pruefen.

**Abschluss in drei Saetzen, ohne ein Fachwort:**

1. *"Gerade zurueckgelesen: `<Pfad>`, N Zeilen — das habe ich gemessen. Ob Claude sie beim
   naechsten Start wirklich sieht, weiss ich nicht; das zeigt dir `/context` unter
   'Memory files'."*
2. **Pflicht, wenn Tor 4 getroffen hat:** *"Eine Sache konnte ich nicht festschreiben:
   `<Wortlaut>`. Das steht als Bitte in der Datei — ich lese sie mit und halte mich in der
   Regel daran, garantiert ist es nicht. Pruef diese eine Sache bis auf Weiteres selbst
   nach."* Keine Quote nennen ("meistens", "zu 90 Prozent") — dafuer gibt es keine Quelle.
   Dieser Satz ist die einzige Stelle, an der der Router sichtbar werden MUSS: ohne ihn
   erzeugt der Ablauf falsche Sicherheit.
3. *"Diese Punkte habe ich dir notiert, weil sie woandershin gehoeren: `<...>`. Sie stehen
   in `~/.claude/einrichtung-offen.md`."*

Zum Schluss die Wachstumsregel — der wichtigste Satz des ganzen Ablaufs:

> *"Wenn dieselbe Korrektur zum zweiten Mal noetig ist, wird sie eine Zeile. Sag dann
> einfach 'schreib das in meine CLAUDE.md'. Und ruf einmal im Monat
> `/claudemd-optimize global` auf."*

Ein weiterer Durchgang ist schlicht wieder `/einrichtung`, dann im Modus WARTUNG.

---

## Struktur der Ergebnisdatei `~/.claude/CLAUDE.md`

Kopf-Kommentar mit Datum, Herkunftssatz, Wachstumsregel. Leere Ueberschriften entfallen
**ersatzlos** — keine Platzhalter, keine Vorratsregeln.

```markdown
<!-- Angelegt am <Datum> mit /einrichtung.
     Jede Zeile stammt aus einer Antwort oder einem Beispieltext von mir.
     Neue Zeile nur, wenn dieselbe Korrektur zum zweiten Mal noetig war.
     Pruefen: /claudemd-optimize global · Geladen? /context -->

# Ueber mich
# So antwortest du mir
# Wie in meinem Haus geschrieben wird
# Woerter, die bei uns etwas Bestimmtes heissen
# Zahlen und Zusagen, die mir nicht gehoeren
# Was in keinen Text kommt
# Wie du mit Luecken umgehst
# Woher die Angaben kommen
# Wann etwas fertig ist
# Was ich mit dem Ergebnis mache

<!-- Projektregeln gehoeren nicht hierher — dafuer /spark im jeweiligen Ordner. -->
```

Zuordnung: `Ueber mich` aus A1/A2 · `So antwortest du mir` aus A3/A4 · `Wie in meinem Haus
geschrieben wird` nur aus Block B · `Woerter` aus C3/C4/C5 · `Zahlen und Zusagen` aus
D1/D2 · `Was in keinen Text kommt` aus D4 · `Wie du mit Luecken umgehst` aus D5 · `Woher
die Angaben` aus D3 · `Wann etwas fertig` aus D6 · `Was ich mit dem Ergebnis mache` aus A5.

Stammen Zeilen aus dem KURZLAUF ohne Fehlererfahrung, markiere sie im Kopf-Kommentar als
**Starthypothesen** — sie sind noch nicht am Doku-Aufnahmetrigger geprueft.

---

## Struktur von `~/.claude/einrichtung-offen.md`

Diese Datei wird **nicht geladen** und kostet nichts. Erster Satz fett:
**"Diese Punkte gelten HEUTE NICHT."** Dann, je im Wortlaut des Users plus Grund:

```markdown
## Braucht ein Schloss, keine Bitte
## Ist ein Verfahren, keine Regel
## Gehoert zu einem Projekt
## Streichkandidaten — heute nicht entfernt
## Nicht gefragt, weil die Zeit fehlte
```

Der letzte Abschnitt nennt im KURZLAUF die ausgelassenen Bloecke namentlich. Beim naechsten
`/einrichtung` liest Schritt 0 diese Datei und bietet das Nachholen als erste Antwort an.

---

## Harte Regeln fuer dich

- **NIEMALS** eine bestehende `~/.claude/CLAUDE.md` ueberschreiben, umformulieren,
  umsortieren oder kuerzen. Im Modus WARTUNG nur `Edit`, nie `Write`, und nur anhaengen.
- **NIEMALS eine bestehende Zeile loeschen.** Streichkandidaten werden gezeigt und in
  `einrichtung-offen.md` notiert; entfernen darf sie nur der User selbst.
- **NIEMALS** eine importierte Datei (`@`-Zeile) schreiben. Sie wird gelesen, nie beruehrt.
- **NIEMALS** eine Zeile ohne zitierbare Herkunft erzeugen. Leer ist besser als geraten.
- **NIEMALS** aus einer Nicht-Antwort eine Zeile bauen.
- **NIEMALS** echte Namen, Kennzeichen, Fahrgestell- oder Telefonnummern aus eingefuegtem
  Material uebernehmen.
- **NIEMALS** eine summierte Zeilen-Obergrenze ueber die Import-Kette als Doku-Fakt
  behaupten. Belegt ist: unter 200 **pro Datei**.
- **NIEMALS** Hooks, `permissions.deny`, Skills oder `~/.claude/rules/` automatisch
  anlegen. Vorschlagen, begruenden, in `einrichtung-offen.md` notieren. *(Rules ohne
  `paths:`-Frontmatter laden genauso mit und sparen nichts — Auslagern lohnt erst, wenn
  eine EINZELNE Datei ueber 200 Zeilen liegt. Diese Zurueckhaltung ist eine Setzung.)*
- **NIEMALS** `/doctor` empfehlen, ohne die Claude-Code-Version auf dem Rechner gemessen zu
  haben — der Trim-Vorschlag existiert laut Changelog erst ab v2.1.206.
- **NIEMALS** Zeitangaben in Minuten versprechen. Wie lange der Ablauf dauert, ist nicht
  gemessen.
- **NIEMALS** eine Befolgungsquote nennen. Belegt ist nur, dass CLAUDE.md Kontext ist und
  keine Durchsetzung.
- **IMMER** die vollstaendige Datei vor dem Schreiben zeigen und bestaetigen lassen.
- **IMMER** jede Verbots- und Erlaubniszeile rueckwaerts vorlesen, bevor sie geschrieben wird.
- **IMMER** den `/context`-Check zeigen — das Gespraech ist die Behauptung, `/context` der
  Beleg.
- **IMMER** bei Tor-4-Treffern laut sagen, dass es eine Bitte ist und kein Schloss.
