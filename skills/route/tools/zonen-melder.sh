#!/usr/bin/env bash
# Starter fuer den PostToolUse-Zonenmelder. Absichtlich duenn und stumm:
# fehlt Python, passiert nichts - ein Hook darf niemals Werkzeugaufrufe stoeren.
#
# Warum nicht direkt python im settings.json: dort waere ein fehlendes Python
# eine Fehlerzeile je Werkzeugaufruf. Hier ist es Schweigen.
if command -v python >/dev/null 2>&1; then
  python "$HOME/.claude/skills/route/tools/zonen-melder.py" 2>/dev/null || true
elif command -v python3 >/dev/null 2>&1; then
  python3 "$HOME/.claude/skills/route/tools/zonen-melder.py" 2>/dev/null || true
fi
exit 0
