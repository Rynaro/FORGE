# EIIS-1.0 Gap Analysis — FORGE / Reasoner

**Date:** 2026-04-20  
**Source:** `.eidolons-audit/01-scout.md`

---

## Gap Table

| Gap ID | File | Class | Severity | Reason | Proposed Action |
|---|---|---|---|---|---|
| G-01 | `AGENTS.md` | PATCH | blocker | Missing §5 YAML frontmatter (name, version, methodology, methodology_version, role, handoffs) | Prepend frontmatter block to existing content |
| G-02 | `install.sh` | PATCH | blocker | Missing entire §3 flag interface; no manifest emission; no dispatch file writes; no token count print; no idempotency check | Patch arg parsing, idempotency, dispatch writes, manifest, token print — preserve existing copy-files logic |
| G-03 | `schemas/install.manifest.v1.json` | CREATE | blocker | §3 requires this schema file committed to repo | Create JSON Schema draft 2020-12 exactly as specified in §3 |
| G-04 | `.github/copilot-instructions.md` | CREATE | major | Required by §1; `.github/` dir exists but file absent | Create with FORGE pointer, P0 rules, phase table |
| G-05 | `INSTALL.md` | CREATE | major | Required by §1; human cross-host install guide | Create covering all 4 hosts + raw API |
| G-06 | `hosts/claude-code.md` | CREATE | major | Required by §1; entire `hosts/` dir absent | Create per-host wiring doc (install, config, verify, troubleshoot) |
| G-07 | `hosts/copilot.md` | CREATE | major | Required by §1 | Create per-host wiring doc |
| G-08 | `hosts/cursor.md` | CREATE | major | Required by §1 | Create per-host wiring doc |
| G-09 | `hosts/opencode.md` | CREATE | major | Required by §1 | Create per-host wiring doc |
| G-10 | `evals/canary-missions.md` | CREATE | major | Required by §1; at least one smoke mission | Create with the existing smoke test invocation as mission 1 |
| G-11 | `CLAUDE.md` | PATCH | minor | Lacks consumer-project `@agents/reasoner/agent.md` pointer pattern (§4) | Append "Consumer project usage" section |
| G-12 | `REASONER.md` footer | FLAG | minor | Footer says "Reasoner v1.0.0" — CHANGELOG says 1.1.0; this is core methodology content | Flag for human: update footer to 1.1.0 iff desired; do not touch unless approved |
| G-13 | `agent.md` footer | FLAG | minor | Footer says "Reasoner v1.0.0" — same version drift; methodology content | Flag for human: update footer to 1.1.0 iff desired |

---

## Summary Counts

| Class | Count | Gap IDs |
|---|---|---|
| CREATE | 7 | G-03, G-04, G-05, G-06, G-07, G-08, G-09, G-10 |
| PATCH | 3 | G-01, G-02, G-11 |
| REWRITE | 0 | — |
| FLAG | 2 | G-12, G-13 |

| Severity | Count |
|---|---|
| blocker | 3 (G-01, G-02, G-03) |
| major | 7 (G-04–G-10) |
| minor | 3 (G-11, G-12, G-13) |
