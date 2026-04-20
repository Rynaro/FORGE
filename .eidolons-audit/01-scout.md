# EIIS-1.0 Scout Report — FORGE / Reasoner

**Date:** 2026-04-20  
**Repo:** `/Users/henrique/workspace/oss/agents/FORGE`  
**Canonical Eidolon slug:** `forge` (methodology name: `FORGE`, agent name: `Reasoner`)  
**Current version (CHANGELOG):** `1.1.0`  
**Prior EIIS audit:** none (`.eidolons-audit/` did not exist; no `install.manifest.json` found → full audit mode)

---

## §1 — Required File Inventory

| Path | Required | Present | Notes |
|---|---|---|---|
| `AGENTS.md` | ✅ | ✅ | Exists but **NO YAML frontmatter** (§5 violation) |
| `CLAUDE.md` | ✅ | ✅ | Exists; dev-mode only — lacks consumer install pointer (§4) |
| `.github/copilot-instructions.md` | ✅ | ❌ | `.github/` dir exists (has CONTRIBUTING.md + ISSUE_TEMPLATE) but copilot-instructions.md absent |
| `README.md` | ✅ | ✅ | Complete, references all major files |
| `INSTALL.md` | ✅ | ❌ | Absent |
| `CHANGELOG.md` | ✅ | ✅ | Keep-a-Changelog format; latest entry 1.1.0 |
| `DESIGN-RATIONALE.md` | ✅ | ✅ | Present and substantial |
| `agent.md` | ✅ | ✅ | Has YAML frontmatter; **765 tokens ≤ 1000 ✅** |
| `REASONER.md` (= `<EIDOLON>.md`) | ✅ | ✅ | Full methodology, always-loaded |
| `install.sh` | ✅ | ✅ | Exists but **does not match §3 contract** (see below) |
| `hosts/claude-code.md` | ✅ | ❌ | `hosts/` directory absent |
| `hosts/copilot.md` | ✅ | ❌ | `hosts/` directory absent |
| `hosts/cursor.md` | ✅ | ❌ | `hosts/` directory absent |
| `hosts/opencode.md` | ✅ | ❌ | `hosts/` directory absent |
| `evals/canary-missions.md` | ✅ | ❌ | `evals/` directory absent |
| `skills/framing/SKILL.md` | ✅ | ✅ | Present |
| `skills/deliberation/SKILL.md` | ✅ | ✅ | Present |
| `skills/verification/SKILL.md` | ✅ | ✅ | Present |
| `templates/verdict.md` | ✅ | ✅ | Present |
| `templates/trade-off-analysis.md` | ✅ | ✅ | Present |
| `templates/feasibility-assessment.md` | ✅ | ✅ | Present |
| `templates/root-cause-analysis.md` | ✅ | ✅ | Present |
| `templates/conflict-resolution.md` | ✅ | ✅ | Present |
| `schemas/install.manifest.v1.json` | mandatory (§3) | ❌ | `schemas/` directory absent |

**Present:** 13/22 required files (59%)  
**Missing:** 9 required files

---

## §3 — `install.sh` Contract Delta

Current interface: `bash install.sh [target-directory]`

| Required Flag | Present | Notes |
|---|---|---|
| `--target DIR` | ❌ | Uses positional `$1` instead — evidence: `install.sh:13` |
| `--hosts LIST` | ❌ | Absent |
| `--force` | ❌ | Absent |
| `--dry-run` | ❌ | Absent |
| `--non-interactive` | ❌ | Absent |
| `--manifest-only` | ❌ | Absent |
| `--version` | ❌ | Absent |
| `-h / --help` | ❌ | Absent |
| Idempotency check (version compare) | ❌ | No manifest-based check — evidence: `install.sh:20-46` |
| Writes dispatch files per host | ❌ | Prints hints only; does not write files — evidence: `install.sh:53-109` |
| Emits `install.manifest.json` | ❌ | Absent — evidence: `install.sh` (no manifest write) |
| Prints agent.md token count | ❌ | Absent (smoke test present but no token measurement) — evidence: `install.sh:115-129` |
| Smoke test banner | ✅ | Present — evidence: `install.sh:115-127` |
| Host auto-detection logic | ✅ partial | Detects hosts but does not write dispatch files |

---

## §5 — AGENTS.md Frontmatter

`AGENTS.md` starts with `# AGENTS.md — Reasoner / FORGE methodology (v1.0)` — **no YAML frontmatter block at all**.

Required fields missing: `name`, `version`, `methodology`, `methodology_version`, `role`, `handoffs.upstream`, `handoffs.downstream`

---

## §6 — Token Budget

- `agent.md`: 574 words → **765 approximate tokens** (budget: ≤1000) ✅
- `REASONER.md` is always-loaded (~1,150 tokens per CHANGELOG 1.0.0 entry)

---

## Version Inconsistency

| File | Stated Version |
|---|---|
| `CHANGELOG.md` | `1.1.0` (latest entry) |
| `REASONER.md` footer | `Reasoner v1.0.0` |
| `agent.md` frontmatter | `methodology_version: "1.0"` (no `version` field) |
| `AGENTS.md` title text | `(v1.0)` |

The 1.1.0 release (2026-04-16) added AGENTS.md, CLAUDE.md, and security section to REASONER.md — but REASONER.md footer and AGENTS.md title were not updated. The methodology cycle itself did not change.

---

## Findings

- **[FINDING-001]** AGENTS.md lacks YAML frontmatter required by §5 — evidence: `AGENTS.md:1`
- **[FINDING-002]** install.sh uses positional `$1` for target, not `--target DIR` — evidence: `install.sh:13`
- **[FINDING-003]** install.sh missing 7 flags required by §3 contract — evidence: `install.sh` (no argument parsing block)
- **[FINDING-004]** install.sh prints wiring hints but does not write dispatch files — evidence: `install.sh:53-109`
- **[FINDING-005]** install.sh does not emit `install.manifest.json` — evidence: `install.sh` (no manifest generation)
- **[FINDING-006]** install.sh does not print `agent.md` token count on success — evidence: `install.sh:129`
- **[FINDING-007]** `.github/copilot-instructions.md` absent — evidence: `.github/` listing
- **[FINDING-008]** `INSTALL.md` absent — evidence: root dir listing
- **[FINDING-009]** `hosts/` directory absent (all 4 per-host wiring docs missing) — evidence: root dir listing
- **[FINDING-010]** `evals/canary-missions.md` absent — evidence: root dir listing
- **[FINDING-011]** `schemas/install.manifest.v1.json` absent — evidence: root dir listing
- **[FINDING-012]** CLAUDE.md lacks consumer-project install pointer (§4 pattern) — evidence: `CLAUDE.md` (dev-mode only)
- **[FINDING-013]** Version drift: CHANGELOG 1.1.0 vs REASONER.md/AGENTS.md footers/titles showing 1.0/1.0.0 — evidence: `CHANGELOG.md:1`, `REASONER.md:143`, `AGENTS.md:1`
- **[FINDING-014]** agent.md token count: 765 tokens — WITHIN budget ✅ — evidence: `wc -w agent.md = 574`
- **[FINDING-015]** skills/ has 3 phases (framing, deliberation, verification) — PASS ✅
- **[FINDING-016]** templates/ has 5 templates — PASS ✅
