#!/usr/bin/env python
# ---------------------------------------------------------------------------
# Erzeugt eine Lauf-spezifische Kopie von kimi-worker-settings.json, in der die
# pauschalen Regeln  Read(**/.planning/**) / Edit(**/.planning/**)  durch eine
# AUFZAEHLUNG ersetzt sind: alles unter .planning/ bleibt gesperrt, NUR das
# Verzeichnis des aktiven Route-Laufs (.planning/route[-opus]/<slug>/) ist offen.
#
# Warum Aufzaehlung statt Ausnahme-Muster: Claude Codes Rechtepruefung kennt
# keine Negation, und Deny schlaegt Allow. Eine Regel "alles ausser X" ist dort
# nicht formulierbar. Die Aufzaehlung wird bei JEDEM Start aus dem echten
# Verzeichnisbaum berechnet - ein neu angelegter Ordner unter .planning/ ist
# damit automatisch gesperrt, ohne dass jemand daran denken muss (fail-safe).
#
# Scheitert hier irgendetwas, ist der richtige Ausgang die pauschale Sperre:
# Exit != 0, der Aufrufer faellt auf die statische Datei zurueck. Fehlschlag
# darf nie MEHR oeffnen, nur weniger.
#
# Aufruf: kimi-planning-ausschnitt.py <statische-settings> <repo-root> <lauf-pfad> <ziel>
#         <lauf-pfad> ist repo-relativ mit /, z. B. .planning/route/wissens-center
# ---------------------------------------------------------------------------
import json
import sys
from pathlib import Path

PAUSCHAL = ("Read(**/.planning/**)", "Edit(**/.planning/**)")
# Zeichen, die als Glob-Metazeichen gelesen wuerden: ein Ordnername mit einem
# solchen Zeichen erzeugt ein Muster, das nicht mehr das meint, was dasteht.
# Dann lieber gar keinen Ausschnitt (Exit != 0 -> pauschale Sperre).
META = set("*?[]!")


def regeln_fuer(pfad_rel: str, ist_ordner: bool) -> list:
    ziel = f"**/{pfad_rel}/**" if ist_ordner else f"**/{pfad_rel}"
    return [f"Read({ziel})", f"Edit({ziel})"]


def main() -> int:
    if len(sys.argv) != 5:
        print("Aufruf: kimi-planning-ausschnitt.py <settings> <repo-root> <lauf-pfad> <ziel>",
              file=sys.stderr)
        return 2
    quelle, repo_root, lauf_rel, ziel = sys.argv[1:5]
    repo = Path(repo_root)
    planning = repo / ".planning"
    lauf = repo / lauf_rel

    if not planning.is_dir():
        print("KEIN .planning/ - Ausschnitt nicht noetig", file=sys.stderr)
        return 3
    if not lauf.is_dir():
        print(f"LAUF-ORDNER FEHLT: {lauf_rel}", file=sys.stderr)
        return 3
    # Der Lauf-Ordner MUSS unterhalb von .planning/ liegen, sonst greift die
    # Aufzaehlung an der falschen Stelle und oeffnete .planning/ vollstaendig.
    teile = lauf_rel.split("/")
    if len(teile) != 3 or teile[0] != ".planning":
        print(f"UNERWARTETER LAUF-PFAD: {lauf_rel}", file=sys.stderr)
        return 3

    eltern = teile[1]          # route | route-opus
    slug = teile[2]

    # --- Aufzaehlung: alle Geschwister sperren, den Lauf-Ordner auslassen ----
    gesperrt = []
    for ebene, basis in ((".planning", planning), (f".planning/{eltern}", planning / eltern)):
        for eintrag in sorted(basis.iterdir()):
            name = eintrag.name
            if META & set(name):
                print(f"GLOB-METAZEICHEN IM NAMEN: {ebene}/{name}", file=sys.stderr)
                return 3
            rel = f"{ebene}/{name}"
            if rel == f".planning/{eltern}":        # Elternpfad selbst: nicht pauschal sperren,
                continue                            # seine Kinder werden einzeln aufgezaehlt
            if rel == lauf_rel:                     # der aktive Lauf: genau das ist der Ausschnitt
                continue
            gesperrt.extend(regeln_fuer(rel, eintrag.is_dir()))

    daten = json.loads(Path(quelle).read_text(encoding="utf-8"))
    deny = daten.get("permissions", {}).get("deny")
    if not isinstance(deny, list) or not all(r in deny for r in PAUSCHAL):
        print("STATISCHE DATEI UNERWARTET: pauschale .planning-Regeln nicht gefunden",
              file=sys.stderr)
        return 3

    neu = [r for r in deny if r not in PAUSCHAL]
    neu.extend(gesperrt)

    # --- Gegenprobe im Skript selbst ----------------------------------------
    # (1) Kein erzeugtes Muster darf den Lauf-Ordner treffen.
    # (2) Die bekannten Kronjuwelen muessen weiterhin von einem Muster gedeckt
    #     sein - sonst hat die Aufzaehlung sie stillschweigend verloren.
    # Regeln ohne Klammer (WebFetch, WebSearch) tragen keinen Pfad - uebergehen.
    def pfad_von(regel: str):
        if "(" not in regel or not regel.endswith(")"):
            return None
        return regel[regel.index("(") + 1:-1]

    for regel in neu:
        inhalt = pfad_von(regel)
        if inhalt is None:
            continue
        if inhalt.startswith("**/"):
            inhalt = inhalt[3:]
        if inhalt.rstrip("/*").rstrip("/") == lauf_rel:
            print(f"AUSSCHNITT VERFEHLT: {regel} trifft den Lauf-Ordner", file=sys.stderr)
            return 3
    gedeckt = {p for p in (pfad_von(r) for r in neu) if p is not None}
    # Die Kronjuwelen-Liste ist repo-uebergreifend (die Namen stammen aus dem
    # Cockpit-Repo). Geprueft wird deshalb nur, was in DIESEM Repo existiert:
    # ein Name, den es hier gar nicht gibt, kann von der Aufzaehlung auch nicht
    # verloren worden sein. Ihn trotzdem zu verlangen machte den Ausschnitt in
    # jedem anderen Repo unmoeglich und fiel still auf die pauschale Sperre
    # zurueck - gemessen am 24.07.2026 im Repo dnd-solo-gm, wo dadurch die
    # Kimi-Zweitmeinung einer Plan-Kritik komplett ausfiel (Kimi meldete
    # "permission denied" statt Befunden). Existiert der Name hier, bleibt die
    # Gegenprobe unveraendert scharf und ein Verlust weiterhin Exit 3.
    for name in ("PREMIUM-STRATEGIE.md",):
        if not (planning / name).exists():
            continue
        pflicht = f"**/.planning/{name}"
        if pflicht not in gedeckt and f"{pflicht}/**" not in gedeckt:
            print(f"NICHT GEDECKT: {pflicht}", file=sys.stderr)
            return 3

    daten["permissions"]["deny"] = neu
    daten["$comment_ausschnitt"] = (
        f"ERZEUGT, NICHT VON HAND PFLEGEN. Quelle: {quelle}. Die pauschalen "
        f".planning-Regeln sind durch eine Aufzaehlung ersetzt; offen ist genau "
        f"{lauf_rel}/ (Lauf {slug}). Alles andere unter .planning/ bleibt gesperrt, "
        f"neue Eintraege werden beim naechsten Start automatisch mitgesperrt."
    )
    Path(ziel).write_text(json.dumps(daten, ensure_ascii=False, indent=2) + "\n",
                          encoding="utf-8")
    print(f"AUSSCHNITT: {lauf_rel} offen | {len(gesperrt)} .planning-Regeln erzeugt")
    return 0


if __name__ == "__main__":
    sys.exit(main())
