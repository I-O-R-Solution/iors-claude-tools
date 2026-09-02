#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# SHIM (seit 01.09.2026): der Preflight lebt jetzt anbieter-blind in
# preflight.sh, konfiguriert durch profiles/kimi.conf. Name bleibt fuer
# bestehende Aufrufer (SKILL.md-Zitate in offenen Zetteln, Doku).
#
# Aufruf unveraendert:  kimi-preflight.sh [--quiet]
# Exit-Codes unveraendert: 0 = ja, 1 = nein, 2 = Aufruf-Fehler.
# ---------------------------------------------------------------------------
exec bash "C:/Users/User/.claude/skills/route/preflight.sh" kimi "$@"
