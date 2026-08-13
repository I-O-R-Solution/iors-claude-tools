# Code-Profile — Spark Skelett-Specs

Wird von `SKILL.md` Phase 3.5 geladen wenn Code-Profil aktiv ist.

**Prinzip:** Skelett anlegen, NICHT Tool-Init ausfuehren (`npm install`,
`uv sync` macht der User). Nur minimale Config-Files mit funktionierendem
Default-Inhalt. Keine Dependencies waehlen — nur Geruest.

**Konflikt-Verhalten:** existierende Configs werden NIE ueberschrieben.
Skip mit Hinweis (siehe SKILL.md Phase 3.0).

---

## Profil `python`

- `pyproject.toml`: minimal `[project]` Block (name/version/python-version,
  leere `dependencies`-Liste, optional `[tool.ruff]` + `[tool.pytest.ini_options]`)
- `.python-version` mit aktueller stabiler Version
- `src/<paketname-snake>/__init__.py` (leer)
- `tests/conftest.py` (leer mit Kommentar-Header)
- `.env.example` (Header-Kommentar, keine Werte)
- README "Setup": `uv sync && uv run pytest`
- `.gitignore` ergaenzen: `.venv/`, `__pycache__/`, `*.egg-info/`,
  `.pytest_cache/`, `.ruff_cache/`, `dist/`, `build/`

## Profil `node-ts`

- `package.json`: `scripts.dev/build/test/lint/typecheck`, `type: "module"`,
  leere `dependencies` und `devDependencies`. **Scripts ohne gewaehltes Tool
  sind ehrliche Platzhalter** — nicht ins Leere zeigen lassen:
  `"test": "echo 'Test-Runner waehlen (vitest/jest), dann Script ersetzen' && exit 1"`,
  gleiches Muster fuer ALLE fuenf Scripts (`dev`/`build`/`lint`/`typecheck`
  analog, mit passendem Tool-Hinweis), solange das jeweilige Tool nicht
  gewaehlt ist
- `tsconfig.json`: `strict: true`, `target: ES2022`, `module: ESNext`,
  `moduleResolution: bundler`
- `.nvmrc` mit aktueller LTS
- `src/index.ts` mit `console.log("hello")` Platzhalter
- `tests/example.test.ts` mit einem trivialen `expect(1).toBe(1)` +
  Kommentar-Header "laeuft erst wenn ein Test-Runner gewaehlt und
  `scripts.test` ersetzt ist"
- `.env.example`
- README "Setup": nur `npm install` — `npm run dev` erst nennen, wenn ein
  Dev-Runner gewaehlt und das Platzhalter-Script ersetzt ist (sonst verletzt
  die README die Generic-Regel "ausfuehrbare Befehle" unten)
- `.gitignore` ergaenzen: `node_modules/`, `dist/`, `.next/`, `coverage/`,
  `*.tsbuildinfo`

## Profil `node` (ohne TS)

Wie `node-ts` ohne `tsconfig.json`, `src/index.js`, `tests/example.test.js`.

## Profil `rust`

- `Cargo.toml`: `[package]` Block + leere `[dependencies]`
- `src/main.rs` mit `fn main() { println!("hello"); }`
- `tests/integration.rs` (leer mit Kommentar)
- `.env.example` falls Secrets erwaehnt
- README "Setup": `cargo build && cargo test`
- `.gitignore` ergaenzen: `target/`, `Cargo.lock` (nur bei lib, nicht bin)

## Profil `go`

- `go.mod` mit `module <name>` und Go-Version
- `main.go` mit Hello-World
- `main_test.go` mit einem trivialen `t.Run`
- `.env.example` falls Secrets erwaehnt
- README "Setup": `go mod tidy && go test ./...`
- `.gitignore` ergaenzen: `bin/`, `vendor/`

## Profil `hybrid`

Pro Sprach-Top-Level-Ordner das jeweilige Profil-Set in DIESEN Ordner
schreiben (eigene `pyproject.toml` in `backend/`, eigene `package.json` in
`frontend/`). `.gitignore`: genau EINS im Root, sammelt alle Sprach-Ignores
(SSoT der Regel: Anti-Pattern-Liste in SKILL.md).

## Generic — immer wenn Code-Profil aktiv

- `.env.example` neben `.env`-Eintrag in `.gitignore`
- README hat Setup-Sektion mit ausfuehrbaren Befehlen (kein Platzhalter)

## Anti-Pattern

- Kein Tool-Init ausfuehren, keine Dependencies installieren
- Keine Pakete waehlen — User entscheidet
- Kein CI-Workflow erzeugen (`.github/workflows/`) — der User entscheidet
  ob/wann
