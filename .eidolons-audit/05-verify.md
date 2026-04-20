# EIIS-1.0 Verification Report — FORGE / Reasoner

**Date:** 2026-04-20  
**Branch:** `chore/eiis-1.0-conformance`  
**Commit:** `164bd01`

---

## §1 File Existence Checklist

| Check | Status | Notes |
|---|---|---|
| `AGENTS.md` | ✅ PASS | Present |
| `CLAUDE.md` | ✅ PASS | Present, consumer section added |
| `.github/copilot-instructions.md` | ✅ PASS | Created (G-04) |
| `README.md` | ✅ PASS | Unchanged |
| `INSTALL.md` | ✅ PASS | Created (G-05) |
| `CHANGELOG.md` | ✅ PASS | Unreleased section added |
| `DESIGN-RATIONALE.md` | ✅ PASS | Unchanged |
| `agent.md` | ✅ PASS | Unchanged |
| `REASONER.md` (= `<EIDOLON>.md`) | ✅ PASS | Unchanged |
| `install.sh` | ✅ PASS | Patched to §3 contract |
| `hosts/claude-code.md` | ✅ PASS | Created (G-06) |
| `hosts/copilot.md` | ✅ PASS | Created (G-07) |
| `hosts/cursor.md` | ✅ PASS | Created (G-08) |
| `hosts/opencode.md` | ✅ PASS | Created (G-09) |
| `evals/canary-missions.md` | ✅ PASS | Created (G-10) — 3 missions |
| `skills/framing/SKILL.md` | ✅ PASS | Unchanged |
| `skills/deliberation/SKILL.md` | ✅ PASS | Unchanged |
| `skills/verification/SKILL.md` | ✅ PASS | Unchanged |
| `schemas/install.manifest.v1.json` | ✅ PASS | Created (G-03) |

**19/19 required files present.**

## §3 install.sh Contract

| Check | Status | Notes |
|---|---|---|
| `--help` succeeds | ✅ PASS | Exact §3 option list |
| `--version` prints version | ✅ PASS | `1.1.0` |
| `--dry-run` lists expected files | ✅ PASS | Verified output |
| `--target DIR` flag | ✅ PASS | |
| `--hosts LIST` flag | ✅ PASS | |
| `--force` flag | ✅ PASS | |
| `--non-interactive` flag | ✅ PASS | |
| `--manifest-only` flag | ✅ PASS | |
| Idempotency check | ✅ PASS | Version-compare on existing manifest |
| Dispatch file writes | ✅ PASS | Per-host write logic with idempotency guards |
| Manifest emission | ✅ PASS | `install.manifest.json` written |
| Token count print | ✅ PASS | `✓ agent.md: 765 tokens (budget: ≤1000)` |
| Smoke test banner | ✅ PASS | Preserved from original |

## §4 install.manifest.json Schema

| Check | Status | Notes |
|---|---|---|
| `schemas/install.manifest.v1.json` present | ✅ PASS | JSON Schema draft 2020-12 |
| All required properties present | ✅ PASS | eidolon, version, methodology, installed_at, target, hosts_wired, files_written |
| Optional properties included | ✅ PASS | handoffs_declared, token_budget, security |

## §5 AGENTS.md Frontmatter

| Check | Status | Notes |
|---|---|---|
| YAML frontmatter present | ✅ PASS | Python validation passed |
| `name` field | ✅ PASS | `forge` |
| `version` field | ✅ PASS | `1.1.0` |
| `methodology` field | ✅ PASS | `FORGE` |
| `methodology_version` field | ✅ PASS | `1.1.0` |
| `role` field | ✅ PASS | `Reasoner — structured deliberation and decision intelligence` |
| `handoffs.upstream` | ✅ PASS | `[atlas, spectra, apivr]` |
| `handoffs.downstream` | ✅ PASS | `[spectra, apivr, scribe]` |

## §6 Token Budget

| File | Tokens | Budget | Status |
|---|---|---|---|
| `agent.md` | 765 | ≤1000 | ✅ PASS |

## Flagged (not resolved — awaiting human decision)

| Item | File | Status |
|---|---|---|
| G-12: version footer "Reasoner v1.0.0" | `REASONER.md:143` | ⚑ FLAGGED |
| G-13: version footer "Reasoner v1.0.0" | `agent.md:82` | ⚑ FLAGGED |
