Aktiviere den Skill `spark` (liegt unter `~/.claude/skills/spark/SKILL.md`)
und fuehre den Bootstrap-Prozess gemaess TIEFEN-PRINZIP durch.

Wenn der User nach dem Befehl noch Text mitgibt — egal ob kurzer Hinweis
(`/spark mein-projekt`) oder ausfuehrliche Beschreibung (`/spark <mehrere Saetze>`)
— behandle den Text als Eingang fuer Phase 0.1 (Eingangs-Erkennung):

- Sieht der Text aus wie ein Projekt-Name (kebab-case, einzelne Woerter)? →
  als Vorschlag fuer den Projekt-Namen behandeln, restliche Phasen normal
- Enthaelt der Text "bestehend" / "existing" / "migration" / "vorhandenes" /
  "bestehender Ordner"? → Phase 0 direkt auf Migrations-Modus stellen
- Enthaelt der Text "neu" / "new" / "fresh" / "neues Projekt"? → Phase 0
  direkt auf Neu-Modus stellen
- Ist der Text ≥200 Zeichen UND enthaelt Tools/Audience/Aktivitaet? → als
  Reichhaltige Beschreibung behandeln, direkt zu Phase 1, KEINE Interview-Fragen
- Sonst → Phase 0 normal starten (3-Fragen-Fallback)

Der Skill-Inhalt (SKILL.md) ist die verbindliche Quelle — folge dem Workflow
dort. Dieser Command ist nur Trigger + Vor-Ausfuellung.
