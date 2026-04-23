# Changelog

## [Unreleased]

_Nothing yet._

## [1.1.1] - 2026-04-23 — EIIS-1.0 conformance

### Added
- **`AGENTS.md` YAML frontmatter** — §5-compliant block (name, version, methodology, methodology_version, role, handoffs)
- **`schemas/install.manifest.v1.json`** — JSON Schema draft 2020-12 for install manifest validation
- **`.github/copilot-instructions.md`** — Copilot host pointer with P0 rules and phase table
- **`INSTALL.md`** — Human cross-host install guide (Claude Code, Copilot, Cursor, OpenCode, raw API)
- **`hosts/claude-code.md`**, **`hosts/copilot.md`**, **`hosts/cursor.md`**, **`hosts/opencode.md`** — Per-host wiring docs
- **`evals/canary-missions.md`** — Three smoke missions (trade-off, frame guard, scope escalation)
- **`CLAUDE.md` consumer section** — Consumer-project install pointer pattern

### Changed
- **`install.sh`** — Full EIIS-1.0 §3 interface: `--target`, `--hosts`, `--force`, `--dry-run`, `--non-interactive`, `--manifest-only`, `--version`, `-h/--help`; idempotency check; actual dispatch file writing per host; `install.manifest.json` emission; `agent.md` token count measurement and budget gate

### Unchanged
- FORGE cycle (Frame → Observe → Reason → Gate → Emit)
- Six structural markers, five decision templates, three skills
- 4-factor confidence calibration and bounded deliberation budget

## [1.1.0] - 2026-04-16 — Quality Bar Completion

### Added
- **`AGENTS.md`** at repo root — agents.md open standard; auto-loaded by GitHub Copilot, Cursor, OpenCode
- **`CLAUDE.md`** at repo root — thin pointer for Claude Code hosts (mirrors ATLAS pattern)
- **Security & Privacy Surface section** in `REASONER.md` — addresses Prime Directive D10 with surface table, failure modes, and recommended caller practices
- **Boundary Clarification: FORGE vs SPECTRA Explore** in `DESIGN-RATIONALE.md` — addresses the project's open thread about how FORGE's Reason phase differs from SPECTRA's Explore phase, with composition pattern
- **Acronym Word Choices** subsection in `DESIGN-RATIONALE.md` — documents the choice of Frame/Observe/Reason/Gate/Emit over the project's candidate expansion, with justification per letter

### Rationale
Applied the FORGE methodology to the package itself. The deliberation identified four gaps against the Eidolons quality bar (§7 project instructions) and Prime Directives (§4 D10). Additions were scoped to Prime-Directive-mandated items only; canary missions, formal handoff schemas, and per-host wiring docs were explicitly deferred pending real usage data.

### Unchanged
- FORGE cycle (Frame → Observe → Reason → Gate → Emit)
- Six structural markers
- Five decision templates
- 4-factor confidence calibration
- Bounded deliberation budget (1–3 passes + 1 REFORGE)

## [1.0.0] - 2026-04-15 — Initial Release

### Added
- **FORGE cycle** — Frame → Observe → Reason → Gate → Emit deliberation pipeline
- **REASONER.md** — Agent entry point (~1,150 tokens), always-loaded
- **Three on-demand skills**:
  - `skills/framing/SKILL.md` — Problem decomposition, constraint extraction, deliberation depth scoring
  - `skills/deliberation/SKILL.md` — Hypothesis generation (≥3 minimum), adversarial stress-testing (Inversion, Boundary, Pre-Mortem, Dependency), 5-dimension scoring rubric
  - `skills/verification/SKILL.md` — Fallacy detection, evidence coverage matrix, 4-factor confidence calibration, REFORGE protocol
- **Five decision templates**: verdict, trade-off-analysis, feasibility-assessment, root-cause-analysis, conflict-resolution
- **Six structural markers**: `[VERDICT]`, `[TRADE-OFF]`, `[RISK]`, `[ASSUMPTION]`, `[CONSTRAINT]`, `[REVERSAL-CONDITION]`
- **Adaptive deliberation depth** — 3-dimension scoring (Ambiguity × Reversibility × Blast radius) maps to Simple (1 pass) / Standard (2 passes) / Deep (3 passes)
- **Confidence calibration** — 4-factor decomposition (Evidence quality, Logical coherence, Constraint coverage, Sensitivity analysis) with per-factor and composite reporting
- **DESIGN-RATIONALE.md** — Full research → design decision mapping with 13 sources
- **agent.md** — Cross-host agent descriptor compatible with Claude Code, Cursor, GitHub Copilot, OpenCode
- **install.sh** — Host-detecting installer with wiring hints and smoke test
- **SKILL.md routing card** — Lightweight trigger description (~100 tokens)

### Design Decisions
- Single agent with on-demand skills (not internal multi-agent pipeline) — avoids lazy-agent collapse
- Bounded deliberation (max 3 passes + 1 REFORGE) — evidence from CorrectBench against unbounded reflection
- Stateless by design — no memory subsystem; each invocation receives fresh context
- No tool access — reasoning-only; evidence arrives from upstream agents (ATLAS, SPECTRA, APIVR-Δ)
- Hypothesis falsification tests mandatory — prevents strawman alternatives
- Reversal conditions mandatory — makes verdicts time-bounded and falsifiable

### Token Budget
- Entry point: ~1,150 tokens
- Typical working set: ~2,550 tokens (entry + one skill + one template)
- Consistent with stack envelope (Scribe: ~2,200, ATLAS: ~2,100, APIVR-Δ: ~4,350)
