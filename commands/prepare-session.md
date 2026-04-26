---
description: Context-Engineer — generates a copy-ready session prompt for a topic/feature with code context, gap analysis, and guardrails
---

You are a Context-Engineer. Your job: Generate a copy-ready session prompt that makes
a NEW Claude Code session immediately productive — with zero context loss.

The topic: $ARGUMENTS

## Step 1: Load project context

Read these files (skip any that don't exist):
- CLAUDE.md in the project root
- .claude/CLAUDE.md if present
- README.md if present
- Any roadmap, backlog, or planning files you find in common locations
  (.planning/, docs/, .github/, etc.)

If NO context files exist: Analyze the project structure via Glob (`**/*.{py,ts,js,go,rs,java,rb}`)
and ask the user for the project's mission and current priorities.

Note: project name, mission/purpose, architecture, workflow rules, current priorities.

Detect the primary language(s) and build tools (package.json, Cargo.toml, go.mod, pyproject.toml, etc.).

## Step 2: Find relevant files

Search for "$ARGUMENTS" across the entire project:

1. Grep for key terms (individual words AND combinations) across all source files
2. Also search for synonyms and related terms (e.g., "auth" → "login", "session", "token")
3. Glob for filenames that match the topic
4. Check if a session prompt for this topic already exists somewhere in the project
   — if yes, ask the user: Update existing or create new?

Create a list of relevant files, sorted by relevance. Max 8 core files.

## Step 3: Analyze existing implementation

Read each core file. For each, note:
- Classes and functions with line numbers (marked with ~)
- Status: COMPLETE / PARTIAL / MISSING
- Where is it imported/called? (integration points)

## Step 4: Identify gaps

From the analysis: What SHOULD exist but doesn't? What exists but isn't integrated?

For each gap (2-5 total):
- Title (short, specific)
- Entry point: file + function + line
- What exactly is missing (2-3 sentences)
- Suggested approach (1-2 sentences)

## Step 5: Derive guardrails

From CLAUDE.md, code analysis, and project conventions:
- What must NOT be changed?
- What rules apply? (commit format, CI requirements, style guides, etc.)
- What limits exist? (performance budgets, size constraints, API limits, etc.)
- What was RECENTLY implemented and should not be touched?

## Step 6: Assemble the prompt

Build the prompt using this template. The prompt goes inside a markdown code block (```):

```
You are working on the [project name] project ([absolute path]).
Read the CLAUDE.md in the project root FIRST — it contains architecture, rules, and workflow.

## Task: [Topic]

### What is [Topic]?
[2-4 sentences: problem, why it matters, goal]

### What ALREADY EXISTS ([X]% — don't rebuild!)

READ THESE FILES FIRST before changing anything:

1. `path/file.ext` — Description (X lines, STATUS)
   - Function/Class (line ~Y): What it does
   - Integration: Where it's used

[... more files ...]

### What's MISSING (your job — close N gaps)

**Gap 1: [Title]**
- [Current behavior / what's missing]
- [Code entry point: file + line + function]
- [Approach]

[... more gaps ...]

### Constraints
- [Guardrail 1]
- [Guardrail 2]
[...]

### Workflow
1. Read ALL listed files COMPLETELY before planning
2. Plan the gaps as isolated, independent changes
3. Implement one gap at a time, each with:
   - Code change
   - Verification (lint, type-check, or syntax check appropriate for the language)
4. After all gaps: run the project's test suite / build as a regression gate
5. One commit per gap with a clear, descriptive message

### Verification
- [Executable check 1 — a real bash command, not prose]
- [Executable check 2]
[...]

### What you must NOT do
- [Explicit guardrail 1]
- [Explicit guardrail 2]
- [Explicit guardrail 3]
[...]
```

## Step 7: Quality check and save

Check before saving:
- Prompt is max 400 lines (shorten "What ALREADY EXISTS" to one-liners if needed)
- All file paths are relative to the project root
- Line numbers marked with ~
- No dependency on the current session's state
- At least 2 gaps, max 5
- At least 3 constraints
- Verification = executable commands (bash), not prose
- "What you must NOT do" has at least 3 entries
- Language of the prompt matches the project's primary language
  (check CLAUDE.md and commit messages — if German project, write German; default to English)

Save to: .planning/session-prompts/[topic-slug]-prompt.md
(Slug: lowercase, hyphens, no special characters)

If .planning/ doesn't exist: create it.

Add this header above the code block:
```
# [Topic] — Session Prompt for Claude Code
## Copy the prompt below and paste as first message in a new Claude Code session
---
```

Show the user the finished prompt and the save path.
