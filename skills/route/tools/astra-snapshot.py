#!/usr/bin/env python3
"""Arbeitsbaum-Fingerabdruck fuer astra.sh (17.10.2026).

  astra-snapshot.py snap <repo> <out.json>          Fingerabdruck schreiben
  astra-snapshot.py diff <repo> <vorher.json>       geaenderte Pfade drucken

Erfasst jeden Pfad, den `git status --porcelain -uall` meldet, mit SHA-256
seines Inhalts. Geaendert ist ein Pfad, der neu auftaucht, verschwindet oder
einen anderen Hash hat. So sieht der Boss, was Astra WIRKLICH angefasst hat -
unabhaengig davon, was Astra in changes[] behauptet.
"""
import hashlib
import json
import subprocess
import sys
from pathlib import Path


def stand(repo: str) -> dict:
    roh = subprocess.run(
        ["git", "-C", repo, "status", "--porcelain=v1", "-uall", "-z"],
        capture_output=True, check=True).stdout.decode("utf-8", "replace")
    teile = roh.split("\0")
    pfade, i = [], 0
    while i < len(teile):
        eintrag = teile[i]
        i += 1
        if len(eintrag) < 4:
            continue
        code, pfad = eintrag[:2], eintrag[3:]
        if "R" in code or "C" in code:  # Umbenennung: Quellpfad folgt
            i += 1
        pfade.append(pfad)
    out = {}
    for p in pfade:
        f = Path(repo) / p
        out[p] = hashlib.sha256(f.read_bytes()).hexdigest() if f.is_file() else "FEHLT"
    return out


def main() -> int:
    if len(sys.argv) != 4 or sys.argv[1] not in ("snap", "diff"):
        print(__doc__, file=sys.stderr)
        return 2
    modus, repo, datei = sys.argv[1:]
    jetzt = stand(repo)
    if modus == "snap":
        Path(datei).write_text(json.dumps(jetzt, indent=0), encoding="utf-8")
        return 0
    vorher = json.loads(Path(datei).read_text(encoding="utf-8"))
    for p in sorted(set(vorher) | set(jetzt)):
        if vorher.get(p) != jetzt.get(p):
            # Pfad vorher sauber und jetzt sauber taucht nicht auf; vorher
            # schmutzig, jetzt sauber = zurueckgesetzt -> auch eine Aenderung.
            print(p)
    return 0


if __name__ == "__main__":
    sys.exit(main())
