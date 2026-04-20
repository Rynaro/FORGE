# EIIS-1.0 Plan — FORGE / Reasoner

**Date:** 2026-04-20  
**Source:** `.eidolons-audit/02-gaps.md`

---

## 1. Summary

FORGE is structurally sound at the methodology layer: all three skills, all five templates, REASONER.md, agent.md (765 tokens), and the DESIGN-RATIONALE.md are present and well-formed. The gap is entirely in the **install surface**: no host wiring docs, no INSTALL.md, no `evals/`, no `schemas/`, no §5 AGENTS.md frontmatter, and an install.sh that predates the EIIS-1.0 interface contract. After this audit, FORGE will expose the full §3 installer interface (`--target`, `--hosts`, `--force`, `--dry-run`, `--non-interactive`, `--manifest-only`, `--version`), emit a validated manifest, write actual dispatch files in consumer projects, and carry the four per-host wiring docs plus a canary eval. The methodology content (FORGE cycle, templates, skills, P0 rules) is explicitly out of scope — it is not modified except for CLAUDE.md consumer pointer and AGENTS.md frontmatter.

---

## 2. File Change List

### G-01 — PATCH `AGENTS.md` (blocker)

Prepend a YAML frontmatter block (lines 1–11) before the current `# AGENTS.md` heading. The existing document body is preserved unchanged.

```yaml
---
name: forge
version: 1.1.0
methodology: FORGE
methodology_version: 1.1.0
role: Reasoner — structured deliberation and decision intelligence
handoffs:
  upstream:   [atlas, spectra, apivr]
  downstream: [spectra, apivr, scribe]
---
```

Rationale for version: CHANGELOG 1.1.0 is the latest published release. `methodology_version` mirrors `version` since the FORGE cycle itself, markers, and templates have been stable across both releases — any future pure-methodology-spec bump would diverge these fields.

### G-02 — PATCH `install.sh` (blocker)

The existing 130-line script has a working copy-files section (lines 21–46) and a smoke-test banner (115–129). Both are preserved. The following are added/replaced:

1. **Variable declarations block** (after `SCRIPT_DIR`): add `EIDOLON_NAME`, `EIDOLON_VERSION`, `METHODOLOGY`, `TARGET`, `HOSTS`, `FORCE`, `DRY_RUN`, `NON_INTERACTIVE`, `MANIFEST_ONLY` defaults.
2. **`usage()` function** implementing the exact §3 help text.
3. **Argument parsing `while` loop** replacing the current `TARGET="${1:-...}"` single line — handles all 7 flags.
4. **`detect_hosts()` function** (checks `.claude`/`CLAUDE.md`, `.github`, `.cursor`, `.cursorrules`, `.opencode`).
5. **Idempotency check** — read `${TARGET}/install.manifest.json` if present; compare versions; prompt unless `--non-interactive`.
6. **Conditional file copy block** — wrap existing copy logic in `[[ "$MANIFEST_ONLY" != "true" ]]` guard + dry-run guard.
7. **Dispatch file writing block** — replace echo-hint section with actual file writes per detected host:
   - `claude-code`: append `@${TARGET}/REASONER.md` pointer to consumer `CLAUDE.md`
   - `copilot`: create/update `.github/copilot-instructions.md`
   - `cursor`: create `.cursor/rules/reasoner.mdc`
   - `opencode`: create `.opencode/agents/reasoner.md`
8. **Manifest emission** — write `${TARGET}/install.manifest.json` with all required §4 fields.
9. **Token count + budget gate** — `wc -w < "${TARGET}/agent.md" | awk ...` → print + fail if `--non-interactive` and >1000.
10. **Smoke test banner** — preserved from existing; token count line added before it.

The existing file header comment is preserved and updated to reflect new interface.

### G-03 — CREATE `schemas/install.manifest.v1.json` (blocker)

New file at `schemas/install.manifest.v1.json`. Contents: the exact JSON Schema draft 2020-12 from EIIS §4, with `$id` set to `https://eidolons.dev/schemas/install.manifest.v1.json` and `title` set to `"Eidolon Install Manifest v1"`.

### G-04 — CREATE `.github/copilot-instructions.md` (major)

New file. Covers:
- One-paragraph FORGE description (lifted from README.md)
- P0 rules (copied from AGENTS.md — not modified, just referenced in copilot format)
- Phase pipeline table (F/O/R/G/E with artifact and skill file)
- Full spec pointer: `AGENTS.md`

### G-05 — CREATE `INSTALL.md` (major)

New file. Human cross-host install guide covering:
- Quick install (bash install.sh)
- Claude Code wiring
- GitHub Copilot wiring
- Cursor wiring
- OpenCode wiring
- Raw API / any LLM (load REASONER.md as system prompt)
- Verification smoke test
- Upgrade instructions

### G-06 — CREATE `hosts/claude-code.md` (major)

New file. Sections: Install, Config (CLAUDE.md pointer + .claude/agents/ symlink), Verify (smoke test), Troubleshooting.

### G-07 — CREATE `hosts/copilot.md` (major)

New file. Sections: Install, Config (.github/copilot-instructions.md + agents/ placement), Verify, Troubleshooting.

### G-08 — CREATE `hosts/cursor.md` (major)

New file. Sections: Install, Config (.cursor/rules/reasoner.mdc frontmatter), Verify, Troubleshooting.

### G-09 — CREATE `hosts/opencode.md` (major)

New file. Sections: Install, Config (.opencode/agents/reasoner.md with mode: primary), Verify, Troubleshooting.

### G-10 — CREATE `evals/canary-missions.md` (major)

New file. At least one smoke mission using the billing-service trade-off scenario already present in install.sh. Format: mission ID, input, expected behavior, pass/fail criteria.

### G-11 — PATCH `CLAUDE.md` (minor)

Append a "Consumer project usage" section after the existing content explaining that after `bash install.sh`, Claude Code finds the agent at `agents/reasoner/agent.md`.

### G-12, G-13 — FLAG (minor)

`REASONER.md` footer and `agent.md` footer say "Reasoner v1.0.0" while CHANGELOG shows 1.1.0. These are methodology content files — no change without explicit human approval. Flagged in this plan for awareness.

---

## 3. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| install.sh patch breaks existing positional-arg usage (scripts calling `bash install.sh ./some/path`) | High | Medium | Keep backward compat: after flag parsing, check if `$1` is a non-flag positional and treat as `--target` for the transition period; add deprecation note in usage() |
| AGENTS.md YAML frontmatter syntax error breaks Copilot/Cursor auto-loading | Medium | High | Validate YAML with `python3 -c "import yaml; yaml.safe_load(open('AGENTS.md'))"` after write |
| install.sh dispatch writes to consumer project mutate files unintentionally | Low | High | All writes guarded by `--dry-run` flag; manifest write is atomic (single `cat > file`) |
| Version 1.0.0 vs 1.1.0 inconsistency in methodology files causes confusion | Low | Low | Flagged G-12/G-13; not touched without approval |

---

## 4. Token Budget Estimate

| File | Current | After Patch | Delta |
|---|---|---|---|
| `agent.md` | 765 tokens | 765 tokens | 0 (not modified) |
| `CLAUDE.md` | ~100 tokens | ~170 tokens | +70 |

Consumer always-loaded budget: `agent.md` stays at 765 (≤1000 ✅). CLAUDE.md addition is a dev-repo file, not consumer-installed.

---

## 5. Rejected Alternatives

**Alternative: Full rewrite of install.sh from the EIIS template skeleton.**  
Rejected because: The EIIS spec explicitly states "If install.sh already exists with substantial content (as in Scribe and Reasoner), do NOT rewrite it from this skeleton." The existing copy-files logic and smoke test banner are correct and tested. A full rewrite introduces unnecessary regression risk.

**Alternative: Create a new `install-v2.sh` and leave `install.sh` unchanged.**  
Rejected because: This would violate the §3 contract requirement that `install.sh` implements the exact interface. A parallel script creates consumer confusion about which to use.

**Alternative: Omit actual dispatch file writing from install.sh (keep hints only).**  
Rejected because: §3 explicitly requires "Creates or appends dispatch files per host" — hints-only fails the contract. The `--dry-run` flag provides a safe inspection mode.
