# Changelog

## [1.10.0] — 2026-07-03 — ECL v2.0 adoption (ISE trust-hierarchy, checker handoff, drift kill)

### Added
- **ECL v2.0 vendoring.** `schemas/ecl-envelope.v2.json` — self-contained vendored copy of `eidolons-ecl@v2.0.0`'s `schemas/envelope.v2.json` (spec/ecl-2.0.md §6.5), following the same inlined-enum, self-contained convention as the existing `schemas/ecl-envelope.v1.json`. The v1 file is **retained**, not replaced — it validates inbound v1.x sidecars during the ECL §7.3 compatibility window (through 2027-05-13). Wired into `install.sh` (`copy_tracked` + dry-run echo + `build_skills_json`-adjacent schema copy block).
- **ISE (Intent, Source, Entitlement) emission** on the outbound `reasoning-report` envelope template (ECL v2.0 §6.5). `schemas/reasoning-report.envelope.json` now sets `ise.assertion_grade: "self-attested"` — FORGE's Gate phase is a self-review pass (`skills/verification.md`), not an externally spec-mandated check, so `self-attested` is the honest grade; `validated` is reserved for artefacts a distinct checker has signed off on. `ise.provenance.methodology_version` and `ise.receiver_authorization` (`auto_route: true`, `auto_merge: false`, `auto_deploy: false`) are also set. `skills/verification.md`'s Envelope Construction Checklist gains a matching step.
- **Checker-handoff gate for irreversible verdicts** (`skills/checker-handoff.md`, new). When a recommended action matches one of five mechanically observable irreversibility trigger markers — deploy/release, destructive migration or data deletion, security-boundary change, external spend/commitment, public communication — FORGE sets `requires_checker: true` on the emitted `reasoning-report` instead of letting the verdict flow straight to execution; the orchestrator then routes it to a distinct checker (VIGIL for evidence-based claims, human for judgment calls) before any action. Reversible verdicts are unaffected. `requires_checker` (boolean, default `false`) added to `schemas/reasoning-report-profile.v1.json` and to all five `templates/*.md` frontmatter blocks. `agent.md` gains P0 rule #9 (additive — existing P0s 1–8 unrenumbered): "Checker handoff on irreversible verdicts." FORGE stays tool-less — the hop is expressed via the emitted-artifact marker, never a tool call.
- **Weak-host self-consistency trigger** (`skills/self-consistency.md`, additive). The roster declares FORGE `degraded_mode: sample-select` (`roster/routing.yaml`, routing-1.1) — on a weak or undeclared host, N-sample deliberation + rubric-agreement selection now REPLACES single-trace self-red-teaming (the Pass-3 Deep red-team) as a third gate condition alongside Deep+stakes and explicit opt-in. Skill structure otherwise unchanged.

### Changed
- **ECL prose drift kill (all → v2.0).** `AGENTS.md` (P0 rule #10), `SPEC.md` (Emit-phase ECL envelope section and §7 ECL compatibility), and `skills/verification.md` (Envelope Construction Checklist header) referenced "ECL v1.0" while the `ECL_VERSION` file already declared `2.0` — reconciled to v2.0 throughout. Schema references updated from `schemas/ecl-envelope.v1.json` to `schemas/ecl-envelope.v2.json` (v1 file retained and referenced for the §7.3 compatibility window). `skills/verification.md` also fixes a stale path left over from the v1.5.0 file move: "The envelope template is at `templates/reasoning-report.envelope.json`" → `schemas/reasoning-report.envelope.json`.
- `schemas/reasoning-report.envelope.json`: `envelope_version` `"1.0"` → `"2.0"`.
- Version-stamp bump to 1.10.0 in the 5 canonical homes (`install.sh` `EIDOLON_VERSION`, `agent.md` frontmatter, `AGENTS.md` frontmatter, `SPEC.md` header, `README.md`). No footer versions touched (already stripped per 1.9.0).

## [1.9.1] — 2026-06-10

### Changed
- `.claude/agents/forge.md` (and its `install.sh` heredoc): `tools: none` → `tools: Read, Grep, Glob, Write`.
  Rationale: "reasoning-only" P0 prohibits codebase mutation and exploration-by-execution, not artifact
  consumption. FORGE's Observe phase and verify-incoming gate read handed-off evidence files and
  `.envelope.json` sidecars; the Emit phase writes its own decision artifact. These are documented
  F-O-R-G-E cycle operations. Nexus MCP wiring appends `mcp__crystalium__*` globs separately; no Bash
  (execution) and no Edit (code mutation) are included. Tool refusals at TRANCE remain immutable.

## [1.9.0] — 2026-06-10

### Changed
- Version-stamp hygiene: all doc/template/host-file footers stripped of version numbers (D1); version lives only in `install.sh` `EIDOLON_VERSION`, `agent.md`/`AGENTS.md` frontmatter `version:`, `SPEC.md` header, README, and CHANGELOG entries.
- Canonical skill frontmatter added to all five skills (`forge-framing`, `forge-deliberation`, `forge-verification`, `forge-self-consistency`, `forge-verify-incoming`) with rich `description`, `metadata.methodology`, and `metadata.phase` fields; `## When to use` sections preserved.
- `tests/verify-incoming.bats`: no-frontmatter assertion inverted — test now asserts frontmatter presence with non-empty `name` and `description`.
- `examples/install.manifest.json`: version bumped to 1.9.0; `self-consistency` and `verify-incoming` skill entries added (EIIS I5).
- `schemas/reasoning-report.envelope.json`: `from.version` bumped `1.3.0` → `1.9.0`.
- `.claude/agents/forge.md`: `methodology_version` updated to `1.9.0`.

## [1.8.0] — 2026-06-04

### Added
- **Blocking symmetric verify-incoming gate (ECL §6.2.2)** — replaces the
  earlier opt-in warn-only posture with a mandatory receiver-side integrity
  gate. `skills/verify-incoming.md` is loaded when an upstream artefact
  arrives with a sibling `.envelope.json`; FORGE MUST NOT process the payload
  unless a `verify_pass` trace event (written by the orchestrator's
  `eidolons verify-envelope --block` pre-step) is on record for the
  `message_id`. On failure the skill REFUSES and hands control back to the
  orchestrator (routed to VIGIL or human — never a silent process-anyway).
  Symmetric distribution: all six Eidolons ship this gate with identical
  semantics. The mechanical SHA-256 check runs at the orchestrator (full Bash);
  FORGE enforces the result using only `Read` — no Bash required.
- `tests/verify-incoming.bats` + `tests/helpers.bash` — bats suite verifying
  skill content posture (blocking, no warn-only), install registration, manifest
  entry, vendor SKILL.md copy, and agent.md token budget compliance.

## [1.7.0] — 2026-06-03

### Added
- **Self-Consistency Mode (G2 / TRANCE)** — operationalizes FORGE's dormant
  TRANCE form into a fully specified, gated, opt-in mode.
  - `skills/self-consistency.md` (new flat skill) — N perspective-diverse,
    mutually-blind reasoning traces (N=3 high-stakes / N=5 irreversible-
    system-wide) over a frozen Frame+Observe inventory, drawn from a fixed
    adversarial-persona table (evidence-max / pre-mortem / constraint-relax /
    inversion / simplest-viable); a structural-agreement judge-merge with the
    60% consensus floor; `[DISPUTED]` emission below floor; and an opt-in
    independent/cross-model verifier HANDOFF as the ceiling-breaker. Confidence
    anchors on cross-trace structural agreement, NOT averaged verbalized
    confidence. Bounded (exactly N, one merge pass; composes with — does not
    extend — the 3-pass/1-REFORGE cap). Loads in place of `skills/deliberation.md`
    for the Reason phase of a G2 run.
  - `SPEC.md §10` — "Self-Consistency Mode (G2 / TRANCE)": the explicit gate
    (Deep-depth complexity AND stakes flag, OR explicit opt-in — never default),
    the reasoning-only refusal restatement (no tool access at TRANCE), and the
    Skill-Loading routing row.
  - `DESIGN-RATIONALE.md §9` — research → decision mapping: perspective-diverse
    over N-identical (R3-04, R3-06); structural agreement over verbalized
    confidence (R5-11, R2-02); opt-in verifier handoff vs naive debate (R2-08),
    reconciled with the prior unbounded-debate exclusion. Token Budget table
    updated.
  - `evals/canary-missions.md` — `self-consistency-merge` DSL mission asserting
    N≥3 diverse traces, structural-agreement merge, the 60% floor, and gated
    opt-in.

### Changed
- `install.sh`: `wire_skill "self-consistency"` registered (plus dry-run echo and
  `build_skills_json` enumeration); `EIDOLON_VERSION` bumped `1.6.0` → `1.7.0`.

### Notes
- `agent.md` body UNTOUCHED — the ≤1000-token P0 budget gate is preserved (~956
  est-tokens); the mode is reachable via `SPEC.md §10` + the SPEC Skill-Loading
  table without entry-point edits. Only the stale `methodology_version` frontmatter
  stamp was normalized (`1.3.0` → `1.7.0`) alongside the rest of the repo's
  release-version footers. `EIIS_VERSION` (`1.4`) and `ECL_VERSION` (`2.0`)
  unchanged — no install-layout or envelope-format change. Mode is opt-in/gated,
  NOT a mandatory critique gate.
- Score delta is a methodology-layer estimate (7.5 → ~8.5, M-confidence,
  unbenchmarked). The benchmark that would lift it past M is a nexus-level eval
  harness, out of scope for this repo.

## [1.6.0] — 2026-06-02

### Added
- **CRYSTALIUM memory pipeline** — embed the recall → plan_checkpoint/plan_replan
  → ingest → session_end protocol into the FORGE methodology.
  - `agent.md` + `skills/framing.md`: recall pre-flight at Frame intake —
    surfaces prior verdicts, fired reversal conditions, and constraint patterns
    before decomposition begins (`k=5`, layers semantic/episodic/procedural).
  - `skills/deliberation.md`: plan checkpoints during Reason — `plan_checkpoint`
    at each pass boundary; `plan_replan` when the winning hypothesis changes or a
    REFORGE revises the leading alternative. Produces an auditable deliberation
    trace at the CRYSTALIUM execution layer (T0/T1 only).
  - `skills/verification.md`: ingest spine at Emit — after the ECL envelope is
    validated, `ingest(envelope, payload=<reasoning-report>)` persists the verdict
    at T1 (`from.eidolon=forge`). Optional `commit(layer=episodic,
    provenance={author_agent:"forge"})` for notable mid-cycle observations.
    `session_end()` triggers Dream consolidation once per deliberation.
  - Graceful-skip contract in every touched skill — absent CRYSTALIUM never
    causes a hard-fail; FORGE remains EIIS-standalone-conformant.
- `SPEC.md §9` — "Memory protocol (CRYSTALIUM)" section: phase-precise placement
  table, FORGE-specific plan_checkpoint rationale, trust-tier note.
- `evals/canary-missions.md` — `memory-round-trip` mission: asserts recall at
  Frame, plan_checkpoint during Reason, ingest at Emit with `author_agent=forge`
  + T1, and graceful-skip when CRYSTALIUM is absent.

### Changed
- `install.sh`: `EIDOLON_VERSION` bumped `1.5.2` → `1.6.0`.

### Notes
- ECL_VERSION (`2.0`) and EIIS_VERSION (`1.4`) unchanged — no envelope-format
  or install-layout changes.
- CRYSTALIUM tools (`mcp__crystalium__*`) are allowlist-injected by the nexus
  shared `.mcp.json` (shipped in nexus v1.2.0); no wiring work in this repo.

## [1.5.2] — 2026-05-27

### Changed
- Patch: migrate evals/canary-missions.md to nexus v1.13.0 DSL format (smoke-default + frame-guard missions). Legacy free-form catalog preserved.

## [1.5.1] — 2026-05-26

### Fixed
- fix: SPEC.md skill path refs updated from subdir-style to flat layout (matches v1.3+ install convention). Three stale `skills/<phase>/SKILL.md` references replaced with `skills/<phase>.md` (`framing`, `deliberation`, `verification`).

## [1.5.0] — 2026-05-26

### Changed
- Declares EIIS v1.4 conformance (`EIIS_VERSION = 1.4`).
- BREAKING (install-target): `SKILL.md` (root Codex dispatch file), `CLAUDE.md`,
  `README.md`, and `DESIGN-RATIONALE.md` are no longer copied to `<target>/`.
  The source-repo files at the FORGE repo root are unchanged. If Codex host
  wiring is added in a future release, the dispatch file will land at
  `./.codex/agents/forge.md` (per EIIS v1.4 §4.2.8).
- `agent.md` is now recorded in `files_written[]` with `role: "agent-profile"`
  (was `"entry-point"`; EIIS v1.4 §1.8.6).
- `.claude/agents/forge.md` heredoc rewritten per EIIS v1.4 §4.2.6: body now
  references both `./.eidolons/forge/agent.md` (P0 rules) and
  `./.eidolons/forge/SPEC.md` (deep spec). Legacy `REASONER.md` and `AGENTS.md`
  references removed.
- `templates/reasoning-report.envelope.json` moved to `schemas/` in the source
  repo and install target (EIIS v1.4 §1.7 whitelist: `templates/` only allows
  `*.md`; JSON envelopes belong under `schemas/` per §1.7.2).
- Manifest: `canonical_inventory_strict: true` added (EIIS v1.4 §2.3).

### Added
- `<target>/ECL_VERSION` is now written by `install.sh` with `role: "ecl-version"`
  (EIIS v1.4 §3.7.1; closes scout G3). FORGE source declares `ECL_VERSION = 2.0`.
- `canonical_inventory_sweep` helper: manifest-driven sweep removes any file under
  `<target>/` not in the current run's `files_written[]` (EIIS v1.4 §6.X).
  Runs after all writes, before the manifest is finalised.
- `LEGACY_SPEC_FILES` extended with `SKILL.md`, `CLAUDE.md`, `README.md`,
  `DESIGN-RATIONALE.md` for the belt-and-braces early sweep (§6.X.5 MAY).

## [1.4.1] — 2026-05-26

### Fixed
- `install.sh` now sweeps legacy v1.2-era artefacts on upgrade: removes stale
  `<TARGET>/REASONER.md`, the dead `<TARGET>/AGENTS.md` install-target copy
  (retired in v1.4.0 — source repo retains `AGENTS.md` for EIIS §1.1 conformance),
  and any `<TARGET>/skills/{deliberation,framing,verification}/` subdir trees left
  behind by pre-v1.3 installs. Fresh installs are unaffected (cleanup is a no-op
  when no legacy files are present).

## [1.4.0] — 2026-05-25 — EIIS v1.3 install-layout normalization

### Changed
- BREAKING: full-spec destination renamed `REASONER.md` → `SPEC.md` (EIIS v1.3 §1.8).
  Source repo file also renamed via `git mv REASONER.md SPEC.md`.
- BREAKING: default `--target` changed from `./agents/reasoner` to `./.eidolons/forge`
  (aligns with nexus `roster/index.yaml` `target_default`; override still works).
- BREAKING: `AGENTS.md` is no longer copied into the install target.
  The source repo retains `AGENTS.md` for EIIS §1.1 vendor-neutral conformance,
  but the install target no longer contains a copy. Nexus agent file's
  `Full rules` reference is replaced by `Full spec: SPEC.md`. Resolves the
  long-standing dead-reference bug (GAP-1).
- Skills layout flattened: `skills/<phase>/SKILL.md` → `skills/<phase>.md`
  (source-of-truth per EIIS v1.3 §4.2.4.3).
- Shared dispatch block and all per-host HEREDOCs updated:
  `REASONER.md` → `SPEC.md`; `AGENTS.md` → `SPEC.md`; skill paths flattened.

### Added
- Skills now dual-written to `.claude/skills/forge-<phase>/SKILL.md` for
  Claude Code auto-load (EIIS v1.3 §4.2.4). `wire_skill` helper added to
  `install.sh`. FORGE previously had no `.claude/skills/` wiring (GAP-4).
- Manifest: `spec_file` field (§1.8) and `skills[]` array (§4.2.4) with
  live SHA-256 for source-of-truth and vendor-copy paths per skill.

### Compliance
- `EIIS_VERSION` bumped `1.1` → `1.3`.
- `EIDOLON_VERSION` bumped `1.3.2` → `1.4.0`.

## [1.3.2] — 2026-05-13 — declare ECL v2.0 conformance

### Changed
- `ECL_VERSION` file: `1.2` → `2.0`. Targets the ECL v2.0 spec
  (`Rynaro/eidolons-ecl@v2.0.0`; see `spec/ecl-2.0.md`, introducing the
  ISE trust hierarchy). FORGE emit envelopes remain byte-compatible
  (ECL v2.0 is backward-compatible per ECL §7.3, window through 2027-05-13).
- `agent.md` frontmatter: `ecl.envelope_version` `"1.2"` → `"2.0"`.
- `install.sh`: `EIDOLON_VERSION` `1.3.1` → `1.3.2` (PATCH bump —
  declaration-only change; no behaviour change, no schema change, no
  envelope-shape change).

### Notes
- Declaration-only patch bump. No envelope-format changes.
- AGENTS.md has no ecl/comm block in its frontmatter (FORGE convention — preserved).
- Companion patches: ATLAS v1.5.2 ✓, SPECTRA v4.3.2 ✓, APIVR-Δ v3.1.2 ✓,
  IDG v1.2.2 ✓ all released; VIGIL follows.

## [1.3.1] — 2026-05-12 — Declare ECL v1.2 conformance

### Changed
- `ECL_VERSION` file: `1.0` → `1.2`. Targets the latest ECL spec
  (`Rynaro/eidolons-ecl@v1.2.0`); FORGE's emit envelopes remain
  byte-compatible (v1.2 is backward-compatible with v1.0 per ECL §1.1.1).
- `agent.md` frontmatter: `ecl.envelope_version` `"1.0"` → `"1.2"`.
- `install.sh`: `EIDOLON_VERSION` `1.3.0` → `1.3.1` (PATCH bump —
  declaration-only change; no behaviour change).

### Notes
- No envelope-format changes. v1.0 envelopes already emitted by older
  FORGE releases are valid under v1.2 conformance.
- FORGE's `reasoning-report` emit edges (forge → apivr / atlas / spectra /
  idg / vigil) use `trust_level=standard` per the contracts in
  `Rynaro/eidolons-ecl@v1.0.1/contracts/`. The new ECL v1.1 gate I-5
  SHOULD-level warn (high+sha256) does not fire for FORGE emissions.
- Inbound `reasoning-request` verification (from any consulting Eidolon)
  continues to accept v1.0/v1.1/v1.2 envelopes.

## [1.3.0] - 2026-05-11 — ECL v1.0 envelope emission

### Added
- **ECL v1.0 conformance** — FORGE now emits ECL v1.0 envelopes
  alongside every `reasoning-report`. New `ECL_VERSION` file at repo
  root. New `schemas/reasoning-report-profile.v1.json` (vendored from
  `eidolons-ecl/schemas/per-eidolon/reasoning-report.v1.json`). New
  `schemas/ecl-envelope.v1.json` (vendored with performative enum and
  `context-delta` body inlined). New
  `templates/reasoning-report.envelope.json` skeleton.
- **Profile validates FORGE P0 floors** — `hypotheses_count >= 3`,
  `1 <= passes_used <= 3`, `reversal_conditions: minItems 1`. A
  conformance check on any emitted `reasoning-report` enforces the
  three non-negotiable rules from outside FORGE's own tooling.
- **`install.manifest.json` `ecl` block** — declares
  `envelope_version`, `outbound_artifacts`, `inbound_artifacts`. Schema
  hand-extended in `schemas/install.manifest.v1.json` until EIIS v1.2
  promotes the field.

### Changed
- **`AGENTS.md` adds P0 rule #10** — ECL envelope on every emission.
- **`REASONER.md` §"E — Emit"** — Emit is now the envelope-bearing
  phase. New §7 ECL compatibility.
- **`DESIGN-RATIONALE.md`** — new section explaining single outbound
  profile, base-profile-only inbound, and P0-floor encoding choices.
- **All five decision templates** — added YAML frontmatter block
  declaring ECL artefact-kind `reasoning-report` and P0 floor fields.
- **`skills/verification/SKILL.md`** — added Envelope Construction
  Checklist for the Emit phase.

### Cross-cuts
- Tracks `Rynaro/eidolons-ecl@v1.0.1` (the v1.0.1 patch enumerating the
  eight deferred lateral contracts).
- Tracks `Rynaro/eidolons` roster: `forge` versions.latest 1.2.1 →
  1.3.0 in a separate `fix/roster-forge-1-3-0` PR.

## [1.2.1] - 2026-04-26 — Re-vendor EIIS v1.1 schema (codex enum) + release workflow

### Fixed
- `schemas/install.manifest.v1.json` re-vendored from EIIS v1.1 — the previously bundled copy lacked `codex` in the `hosts_wired` enum, causing the EIIS conformance checker's M14 (JSON Schema validation) to fail when a validator (`ajv` / `python -m jsonschema`) was on PATH. Pure schema fix; no install.sh behaviour change.

### Added
- **Release-integrity workflow** — `.github/workflows/release.yml` adopts the eidolons-nexus reusable release template (`Rynaro/eidolons/.github/workflows/eidolon-release-template.yml@main`). On `workflow_dispatch` with a SemVer version input, the workflow runs EIIS conformance against the tagged tree, builds a release manifest (commit, tree, `archive_sha256`, and `manifest_sha256` when `install.manifest.json` exists at repo root — currently `null` for FORGE), creates and pushes the annotated tag, attests artifacts via GitHub's provenance API, and publishes the GitHub Release with `source.tar`, `release-manifest.json`, and `SHA256SUMS`. Pairs with the nexus's `Roster Intake` workflow which ingests the release and opens a PR populating `versions.releases.<X.Y.Z>` in `roster/index.yaml`. Pre-cursor to `eidolons verify` flipping from `integrity.enforcement: warn` to `strict` once all six shipped Eidolons have published release metadata.

## [1.2.0] - 2026-04-26 — EIIS-1.1 conformance + Codex host + drift closures

### Added
- **OpenAI Codex host support** (EIIS v1.1 §4.5) — `--hosts codex` writes a marker-bounded section into root `AGENTS.md` and a per-Eidolon `.codex/agents/forge.md` subagent file with required `name` / `description` frontmatter. Body mirrors the Claude subagent prompt. `--hosts all` now expands to include `codex`.
- **`EIIS_VERSION`** file at repo root, declaring conformance with EIIS v1.1 (closes drift D-6).

### Changed
- **`install.sh` parses `--shared-dispatch` / `--no-shared-dispatch`** per EIIS §2 (closes drift **D-1**). Default is `--shared-dispatch` when `codex` is wired (override-with-warn for `--no-shared-dispatch`); for non-codex flows the legacy default is preserved.
- **All shared-host writes are now marker-bounded** (closes drift **D-4**) — every block FORGE emits into `CLAUDE.md`, `.github/copilot-instructions.md`, and `AGENTS.md` lives inside `<!-- eidolon:forge start --> … <!-- eidolon:forge end -->`. `eidolons remove` can now strip FORGE cleanly. Legacy non-marker FORGE content from v1.1.1 is left intact and a new marker-bounded block is appended; consumers can manually delete the legacy paragraph if desired.
- **`install.manifest.json` `files_written`** is now populated with one entry per file written, each with `path`, `sha256`, and `role` (closes drift **D-3**).
- **EIIS conformance** — `bash conformance/check.sh` against this repo now exits **0** (was exit 2 hard-fail on D-4 in v1.1.1).
- Version bumped across `install.sh`, `agent.md`, `AGENTS.md`, `README.md`, `REASONER.md`, `DESIGN-RATIONALE.md`, `SKILL.md`, all `templates/*.md`, and `skills/*/SKILL.md`.

### Cross-cuts

- Tracks `Rynaro/eidolons-eiis@v1.1.0` (Codex addendum) and `Rynaro/eidolons#21` (nexus codex host wiring).

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
