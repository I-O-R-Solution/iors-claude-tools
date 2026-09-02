#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# SHIM (seit 01.09.2026): der Kimi-Worker lebt jetzt anbieter-blind in
# worker.sh, konfiguriert durch profiles/kimi.conf. Dieser Name bleibt
# stehen, weil laufende Route-Zettel (STATE.md), commands/kimi.md,
# agents/kimi-worker.md und skills/konzept/SKILL.md ihn woertlich aufrufen.
#
# Aufruf unveraendert:
#   kimi-worker.sh <critique|build|resume|chat> <slug> <schema|-> <outfile|-> <prompt>
#
# Alt-Namespace bleibt identisch: profiles/kimi.conf traegt SESSION_PREFIX
# "kimi" und die historischen Marker .kimi-t4-passed/.kimi-t8-passed —
# bestehende Sessions und Gate-Belege gelten unveraendert weiter.
# ---------------------------------------------------------------------------
exec bash "C:/Users/User/.claude/skills/route/worker.sh" kimi "$@"
