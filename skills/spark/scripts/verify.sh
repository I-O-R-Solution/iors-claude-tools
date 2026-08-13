#!/usr/bin/env bash
# Spark Quality-Gate-Verifier — deterministische Pruefung der Phase-4-Gates.
# Aufruf: verify.sh <projekt-pfad> [code-profil]
#   code-profil: python | node | node-ts | rust | go | hybrid | none (optional)
# Exit 0 = alle Gates PASS/SKIP, Exit 1 = mindestens ein FAIL, Exit 2 = Aufruf-Fehler.

set -u

ROOT="${1:-}"
PROFILE="${2:-none}"

if [ -z "$ROOT" ] || [ ! -d "$ROOT" ]; then
  echo "USAGE: verify.sh <projekt-pfad> [code-profil]" >&2
  echo "FEHLER: Projekt-Pfad fehlt oder ist kein Ordner: '$ROOT'" >&2
  exit 2
fi

FAILS=0
PASSES=0
SKIPS=0

pass() { echo "PASS  $1"; PASSES=$((PASSES+1)); }
fail() { echo "FAIL  $1"; [ -n "${2:-}" ] && echo "      -> $2"; FAILS=$((FAILS+1)); }
skip() { echo "SKIP  $1 — $2"; SKIPS=$((SKIPS+1)); }

# --- Instruktionsdatei bestimmen -----------------------------------------
# Neu-Standard: AGENTS.md traegt die Substanz, CLAUDE.md ist der 1-Zeilen-
# Pointer "@AGENTS.md". Unkonvertierter (Migrations-)Bestand: CLAUDE.md
# traegt die Substanz — dann laufen die Substanz-Gates auf CLAUDE.md und
# AGENTS.md-/Pointer-Gates werden SKIP, nicht FAIL.
POINTER_OK=0
CLAUDE_SUBSTANZ=0
if [ -f "$ROOT/CLAUDE.md" ]; then
  POINTER_CONTENT=$(tr -d '\r' < "$ROOT/CLAUDE.md" | grep -v '^[[:space:]]*$' || true)
  if [ "$POINTER_CONTENT" = "@AGENTS.md" ]; then POINTER_OK=1; else CLAUDE_SUBSTANZ=1; fi
fi
if [ -f "$ROOT/AGENTS.md" ]; then
  INSTR="AGENTS.md"
elif [ "$CLAUDE_SUBSTANZ" -eq 1 ]; then
  INSTR="CLAUDE.md"
else
  INSTR="AGENTS.md"
fi

# --- Gate 1: Pflicht-Files existieren -----------------------------------
REQUIRED="CLAUDE.md CONTEXT.md REFERENCES.md README.md .gitignore decisions/TEMPLATE.md decisions/000-craft-principles.md"
MISSING=""
for f in $REQUIRED; do
  [ -f "$ROOT/$f" ] || MISSING="$MISSING $f"
done
# AGENTS.md ist Pflicht — ausser auf unkonvertiertem Bestand (Substanz-CLAUDE.md)
if [ ! -f "$ROOT/AGENTS.md" ] && [ "$CLAUDE_SUBSTANZ" -ne 1 ]; then
  MISSING="$MISSING AGENTS.md"
fi
if [ -z "$MISSING" ]; then
  if [ -f "$ROOT/AGENTS.md" ]; then
    pass "Pflicht-Files (8/8 vorhanden)"
  else
    pass "Pflicht-Files (7/7 — unkonvertierter Bestand, Substanz in CLAUDE.md)"
  fi
else
  fail "Pflicht-Files" "fehlend:$MISSING"
fi

# --- Gate 2: Zeilen-Caps -------------------------------------------------
if [ -f "$ROOT/$INSTR" ]; then
  LINES=$(wc -l < "$ROOT/$INSTR")
  if [ "$LINES" -le 60 ]; then
    pass "$INSTR Zeilen-Cap ($LINES/60)"
  else
    fail "$INSTR Zeilen-Cap" "$LINES Zeilen, erlaubt 60"
  fi
fi

# Bereichs-Dateien bleiben bewusst CLAUDE.md (Codex-Verhalten bei
# verschachtelten AGENTS.md ungeprueft) — NICHT auf AGENTS.md umstellen.
BEREICH_FAIL=0
BEREICH_COUNT=0
while IFS= read -r f; do
  BEREICH_COUNT=$((BEREICH_COUNT+1))
  L=$(wc -l < "$f")
  if [ "$L" -gt 40 ]; then
    fail "Bereichs-CLAUDE.md Zeilen-Cap" "$f: $L Zeilen, erlaubt 40"
    BEREICH_FAIL=1
  fi
done < <(find "$ROOT" -mindepth 2 -name "CLAUDE.md" \
  -not -path "*/node_modules/*" -not -path "*/.git/*" \
  -not -path "*/target/*" -not -path "*/.venv/*" 2>/dev/null)
if [ "$BEREICH_FAIL" -eq 0 ]; then
  pass "Bereichs-CLAUDE.md Zeilen-Caps ($BEREICH_COUNT geprueft)"
fi

# --- Gate 3: Platzhalter-Scan (nur Spark-Files, rekursiv) ----------------
# Ausnahmen: decisions/TEMPLATE.md (Platzhalter sind dort Spec),
#            Zeilen mit <!-- (bewusste TODO-/Kommentar-Marker)
# Iteration zeilenweise (while read), nie per Word-Splitting — Pfade mit
# Leerzeichen zerfallen sonst und das Gate meldet PASS ohne zu pruefen.
PLACEHOLDER_HITS=""
while IFS= read -r f; do
  [ -f "$f" ] || continue
  HITS=$(grep -nE '<[a-zA-Z][a-zA-Z0-9 _./-]*>' "$f" 2>/dev/null | grep -v '<!--' || true)
  if [ -n "$HITS" ]; then
    PLACEHOLDER_HITS="$PLACEHOLDER_HITS
$f:
$HITS"
  fi
done < <(
  printf '%s\n' "$ROOT/AGENTS.md" "$ROOT/CLAUDE.md" "$ROOT/CONTEXT.md" \
    "$ROOT/REFERENCES.md" "$ROOT/README.md" \
    "$ROOT/decisions/000-craft-principles.md"
  find "$ROOT" -mindepth 2 -name "CLAUDE.md" \
    -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null
)
if [ -z "$PLACEHOLDER_HITS" ]; then
  pass "Platzhalter-Scan (keine <...>-Reste)"
else
  fail "Platzhalter-Scan" "Reste gefunden:$PLACEHOLDER_HITS"
fi

# --- Gate 4: CONTEXT.md Frontmatter + Excellence-Anchor ------------------
if [ -f "$ROOT/CONTEXT.md" ]; then
  HEAD10=$(head -n 10 "$ROOT/CONTEXT.md")
  if printf '%s' "$HEAD10" | head -n 1 | grep -q '^---$' \
     && printf '%s\n' "$HEAD10" | grep -q '^last_updated:' \
     && printf '%s\n' "$HEAD10" | grep -q '^review_after_days:'; then
    pass "CONTEXT.md Frontmatter (last_updated + review_after_days)"
  else
    fail "CONTEXT.md Frontmatter" "erwartet YAML-Block mit last_updated + review_after_days am Datei-Anfang"
  fi
  if grep -qi 'Excellence-Anchor' "$ROOT/CONTEXT.md"; then
    pass "CONTEXT.md Sektion Excellence-Anchor"
  else
    fail "CONTEXT.md Sektion Excellence-Anchor" "Sektion fehlt (gefuellt oder mit TODO-Marker Pflicht)"
  fi
fi

# --- Gate 5: Living-Doc-Anker + Craft-Principles-Verweis -----------------
# Anker (spark:living-doc / spark:craft) statt Literal-Satz — der Wortlaut
# darf umformuliert werden, ohne das Gate zu brechen. Legacy-Fallback:
# unkonvertierte Bestaende haben noch den woertlichen Satz.
if [ -f "$ROOT/$INSTR" ]; then
  if grep -q 'spark:living-doc' "$ROOT/$INSTR" || grep -q 'CONTEXT.md ist Living-Doc' "$ROOT/$INSTR"; then
    pass "$INSTR Living-Doc-Vertrag (Anker oder Legacy-Zeile)"
  else
    fail "$INSTR Living-Doc-Vertrag" "Anker '<!-- spark:living-doc -->' fehlt"
  fi
  if grep -q 'spark:craft' "$ROOT/$INSTR" || grep -q '000-craft-principles' "$ROOT/$INSTR"; then
    pass "$INSTR Craft-Principles-Verweis"
  else
    fail "$INSTR Craft-Principles-Verweis" "Anker '<!-- spark:craft -->' oder Verweis auf decisions/000-craft-principles.md fehlt"
  fi
fi

# --- Gate 5b: CLAUDE.md-Pointer-Integritaet ------------------------------
# Neu-Standard: CLAUDE.md besteht (nach CR- und Leerzeilen-Strip) aus genau
# "@AGENTS.md". Unkonvertierter Migrations-Bestand: SKIP, nicht FAIL.
if [ -f "$ROOT/AGENTS.md" ] && [ -f "$ROOT/CLAUDE.md" ]; then
  if [ "$POINTER_OK" -eq 1 ]; then
    pass "CLAUDE.md-Pointer (exakt @AGENTS.md)"
  else
    fail "CLAUDE.md-Pointer" "CLAUDE.md muss aus genau '@AGENTS.md' bestehen — Substanz gehoert in AGENTS.md"
  fi
elif [ "$CLAUDE_SUBSTANZ" -eq 1 ]; then
  skip "CLAUDE.md-Pointer" "unkonvertierter Bestand (Migration) — Konvertierung nicht erzwungen"
fi

# --- Gate 6: Craft-Principles ≥3 Saeulen (oder TODO-Marker) --------------
CP="$ROOT/decisions/000-craft-principles.md"
if [ -f "$CP" ]; then
  SAEULEN=$(grep -cE '^ *[0-9]+\.' "$CP" || true)
  if [ "$SAEULEN" -ge 3 ]; then
    pass "Craft-Principles ($SAEULEN Saeulen)"
  elif grep -q '<!-- TODO' "$CP"; then
    pass "Craft-Principles (TODO-Marker gesetzt, bewusst offen)"
  else
    fail "Craft-Principles" "nur $SAEULEN nummerierte Saeulen, erwartet ≥3 oder TODO-Marker"
  fi
fi

# --- Gate 7: Code-Profil (nur wenn Profil ≠ none) ------------------------
# Validierung liest per stdin — vermeidet Pfad-Probleme (Git-Bash vs. Windows)
json_valid() {
  if command -v node >/dev/null 2>&1; then
    node -e "JSON.parse(require('fs').readFileSync(0,'utf8'))" < "$1" >/dev/null 2>&1 && return 0 || return 1
  elif command -v python >/dev/null 2>&1; then
    python -m json.tool < "$1" >/dev/null 2>&1 && return 0 || return 1
  fi
  return 2
}

toml_valid() {
  if command -v python >/dev/null 2>&1; then
    python -c "import tomllib,sys; tomllib.load(sys.stdin.buffer)" < "$1" >/dev/null 2>&1 && return 0 || return 1
  fi
  return 2
}

check_config() {
  # $1 = Datei relativ zum Root, $2 = json|toml|plain
  local rel="$1" kind="$2" file="$ROOT/$1"
  if [ ! -f "$file" ]; then
    fail "Code-Config $rel" "Datei fehlt"
    return
  fi
  case "$kind" in
    json) json_valid "$file"; rc=$? ;;
    toml) toml_valid "$file"; rc=$? ;;
    *) rc=0 ;;
  esac
  case "$rc" in
    0) pass "Code-Config $rel (vorhanden + valide)" ;;
    1) fail "Code-Config $rel" "syntaktisch NICHT valide" ;;
    2) skip "Code-Config $rel Validierung" "kein node/python verfuegbar, Existenz ok" ;;
  esac
}

case "$PROFILE" in
  python)  check_config "pyproject.toml" toml ;;
  node|node-ts) check_config "package.json" json ;;
  rust)    check_config "Cargo.toml" toml ;;
  go)      check_config "go.mod" plain ;;
  hybrid)
    FOUND=0
    while IFS= read -r f; do
      FOUND=1
      case "$f" in
        *.json) rel="${f#$ROOT/}"; check_config "$rel" json ;;
        *.toml) rel="${f#$ROOT/}"; check_config "$rel" toml ;;
        *)      rel="${f#$ROOT/}"; check_config "$rel" plain ;;
      esac
    done < <(find "$ROOT" -maxdepth 2 \( -name "pyproject.toml" -o -name "package.json" -o -name "Cargo.toml" -o -name "go.mod" \) -not -path "*/node_modules/*" 2>/dev/null)
    [ "$FOUND" -eq 0 ] && fail "Code-Configs (hybrid)" "keine Sprach-Config in Ebene 1-2 gefunden"
    ;;
  none|"") ;;
  *) skip "Code-Profil '$PROFILE'" "unbekanntes Profil, keine Config-Pruefung" ;;
esac

# .env.example-Gate: nur bei aktivem Code-Profil
if [ "$PROFILE" != "none" ] && [ -n "$PROFILE" ]; then
  if [ -f "$ROOT/.gitignore" ] && grep -qE '^\.env$|^\.env[^.]' "$ROOT/.gitignore"; then
    if [ -f "$ROOT/.env.example" ] || find "$ROOT" -maxdepth 2 -name ".env.example" -not -path "*/node_modules/*" 2>/dev/null | grep -q .; then
      pass ".env.example vorhanden (.env ist ignoriert)"
    else
      fail ".env.example" ".env steht in .gitignore, aber .env.example fehlt"
    fi
  fi
fi

# --- Summary --------------------------------------------------------------
echo "----------------------------------------"
echo "ERGEBNIS: $PASSES PASS / $FAILS FAIL / $SKIPS SKIP"
if [ "$FAILS" -gt 0 ]; then
  echo "GATES NICHT BESTANDEN — Phase 4.5 nicht starten."
  exit 1
fi
echo "Alle mechanischen Gates bestanden."
exit 0
