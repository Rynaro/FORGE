# Canary Missions — FORGE

> v1.13.0 DSL-format missions for `eidolons canary forge`. Legacy free-form
> missions preserved under "Legacy mission catalog (pre-DSL)" below.

---

## Mission: smoke-default

### Prompt

FORGE, evaluate this trade-off:

> Given a team of 3 engineers, a 6-week deadline, and an existing Rails monolith at 80k LOC, should we extract the billing service into a separate microservice now, or defer to next quarter? Constraints: a PCI compliance audit is scheduled in 8 weeks, and there is no additional infrastructure budget this quarter.

Walk the cycle (Frame → Observe → Reason → Gate → Emit). Produce a verdict using the trade-off-analysis template. Do NOT request tool use, read files, or fetch data — reason from the provided constraints.

### Expected output shape

A response that opens with a Frame section identifying the decision type as TRADE-OFF and listing the hard constraints. The Observe section inventories the provided evidence and flags missing data as `[GAP]` rather than fabricating it. The Reason section presents at least three distinct hypotheses (e.g. extract now, defer, partial extraction), each with a falsification test. The Gate section confirms soundness or triggers one REFORGE pass. The Emit section delivers the trade-off-analysis structure with a `[VERDICT]` marker, a confidence percentage (0-100), at least one `[REVERSAL-CONDITION]`, at least one `[TRADE-OFF]` marker, and a handoff label naming the next Eidolon (typically `→ SPECTRA` for planning follow-through).

### Validation criteria

- MUST contain heading: `## Frame`
- MUST contain phrase: `\[VERDICT\]`
- MUST contain phrase: `\[REVERSAL-CONDITION\]`
- MUST contain phrase: `\[TRADE-OFF\]`
- MUST contain phrase: `confidence`
- MUST contain phrase: `hypothes`
- MUST contain phrase: `handoff|→`
- SHOULD contain phrase: `PCI`
- SHOULD have token count between 1000 and 3500

---

## Mission: frame-guard

### Prompt

FORGE, should we use microservices?

### Expected output shape

The agent does NOT begin generating hypotheses or producing a verdict. It refuses to deliberate on an unbounded question and emits a concise clarification request listing the missing inputs required before deliberation can begin (specific context, hard constraints, success criteria). The response is short — no `[VERDICT]` marker, no hypothesis numbering, no trade-off matrix.

### Validation criteria

- MUST contain phrase: `Frame`
- MUST contain phrase: `clarif|specific|constraint|criteria`
- MUST have token count between 50 and 600
- SHOULD contain phrase: `context`
- SHOULD contain phrase: `success criteria`

---

## Mission: memory-round-trip

### Prompt

FORGE, evaluate this trade-off:

> Given a distributed system where service A calls service B synchronously, should
> we introduce an async message queue to decouple them? Context: B averages 40ms
> p99 latency; the team has no prior experience with message queues; there is a
> hard SLA requiring end-to-end p99 < 200ms.

Walk the full FORGE cycle. Before framing, confirm you have attempted to recall
prior context from CRYSTALIUM (or note it is absent). During Reason, note each
deliberation pass with a plan checkpoint (or note CRYSTALIUM is absent). In the
Emit section, after producing the reasoning-report envelope, note whether you
called `mcp__crystalium__ingest` with `from.eidolon=forge` at T1 and
`mcp__crystalium__session_end()` (or that CRYSTALIUM was absent and both were
skipped).

### Expected output shape

A response that runs the full FORGE cycle. The Frame section opens by noting a
`recall` call (or graceful-skip if CRYSTALIUM is absent). The Reason section
contains at least one explicit reference to a `plan_checkpoint` call per pass (or
graceful-skip). The Emit section contains an explicit note that
`mcp__crystalium__ingest` was called with `author_agent: forge` at T1 and
`mcp__crystalium__session_end()` was called — or, if CRYSTALIUM is absent, an
explicit graceful-skip note. The deliberation itself produces ≥3 hypotheses,
a `[VERDICT]`, a `[REVERSAL-CONDITION]`, and a handoff label.

### Validation criteria

- MUST contain phrase: `recall|mcp__crystalium__recall`
- MUST contain phrase: `plan_checkpoint|mcp__crystalium__plan_checkpoint`
- MUST contain phrase: `ingest|mcp__crystalium__ingest`
- MUST contain phrase: `session_end|mcp__crystalium__session_end`
- MUST contain one of: `from.eidolon.*forge|author_agent.*forge|forge.*T1|absent|unavailable|not installed`
- MUST contain phrase: `\[VERDICT\]`
- MUST contain phrase: `\[REVERSAL-CONDITION\]`
- MUST contain phrase: `hypothes`
- SHOULD have token count between 1200 and 4000

---

## Mission: self-consistency-merge

### Prompt

FORGE, this is a Deep-depth, irreversible, system-wide decision — run G2 self-consistency.

> We must choose the storage engine for a new event-sourcing ledger that every service will write to. Option A: keep the existing single PostgreSQL cluster with a new append-only table. Option B: migrate the ledger to a dedicated Kafka + compacted-topic store. Constraints: the migration is irreversible once the first production event is written (no dual-write window budgeted); blast radius is system-wide (all 9 services emit ledger events); a hard SLA requires end-to-end write p99 < 50ms; the team has no prior Kafka operational experience. Ambiguity is high — both options have credible advocates.

Run the self-consistency mode: generate at least three perspective-diverse, mutually-blind reasoning traces over a single frozen Frame+Observe inventory, then judge-merge them on structural agreement. Do NOT request tool use, read files, or fetch data — reason from the provided constraints.

### Expected output shape

A response that frames the decision as a high-stakes TRADE-OFF flagged Deep depth, freezes the Frame+Observe inventory once, then fans out into N≥3 perspective-diverse traces (e.g. evidence-maximizing, pre-mortem/failure-first, constraint-relaxation), each reasoning independently and mutually-blind from the same frozen inventory. A structural-agreement judge-merge tallies the modal hypothesis, computes a consensus score against the 60% floor, and cross-references reversal conditions that recurred across ≥2 traces. The merged confidence is anchored on the structural-agreement score (NOT an average of the traces' verbalized confidence numbers). If consensus is below the 60% floor it emits a `[DISPUTED]` verdict with the live positions; otherwise a single merged `[VERDICT]`. The output carries at least one `[REVERSAL-CONDITION]`, a confidence percentage, and a handoff label — and, for a near-floor or high-stakes merge, an opt-in `→ independent-verifier` handoff (a recommendation, never an executed tool call). No tools are called.

### Validation criteria

- MUST contain phrase: `trace|self-consistency`
- MUST contain phrase: `agreement|consensus|merge`
- MUST contain phrase: `60%|floor|consensus`
- MUST contain phrase: `\[VERDICT\]|\[DISPUTED\]`
- MUST contain phrase: `\[REVERSAL-CONDITION\]`
- MUST contain phrase: `confidence`
- MUST contain phrase: `hypothes`
- MUST contain phrase: `handoff|→`
- SHOULD contain phrase: `structural|agreement`
- SHOULD contain phrase: `independent.?verifier|cross-model|blind`
- SHOULD have token count between 1500 and 4500

---

## Legacy mission catalog (pre-DSL)

> The original three free-form missions ("Microservice extraction trade-off",
> "Vague question handling", "Scope escalation resistance") are preserved
> below as historical reference. The v1.13.0 validator parses only the
> `## Mission: <id>` blocks above.

# FORGE Canary Missions

Smoke-test deliberations for verifying correct Reasoner behavior after install
or methodology updates. Each mission specifies the input, expected structural
behavior, and pass/fail criteria. Run these manually or integrate with your
eval harness.

---

## Mission 01 — Microservice extraction trade-off

**ID:** CANARY-01  
**Type:** TRADE-OFF  
**Depth:** Standard (2 passes)

### Input

```
FORGE, evaluate this trade-off: given a team of 3 engineers,
a 6-week deadline, and an existing Rails monolith at 80K LOC,
should we extract the billing service into a separate microservice
now, or defer to next quarter? Constraints: PCI compliance audit
in 8 weeks, no additional infrastructure budget this quarter.
```

### Expected structural behavior

1. **Frame phase** — identifies decision type as TRADE-OFF; extracts hard
   constraints (PCI audit in 8 weeks, no infra budget, 3-engineer team,
   6-week deadline); declares success criteria (team can act; reversible if
   conditions change).
2. **Observe phase** — inventories provided constraints as evidence; identifies
   gaps (e.g., billing service size, coupling score, existing test coverage);
   does NOT fabricate missing data.
3. **Reason phase** — generates ≥3 distinct hypotheses such as: (a) extract
   now, (b) defer entirely, (c) partial extraction / strangler-fig boundary.
   Each hypothesis includes a falsification test.
4. **Gate phase** — checks logical soundness, evidence coverage, decision
   completeness; passes or triggers one REFORGE.
5. **Emit phase** — uses `templates/trade-off-analysis.md` structure; includes
   `[VERDICT]` marker, confidence score (0–100%), at least one
   `[REVERSAL-CONDITION]`, at least one `[TRADE-OFF]` marker, handoff
   recommendations (→ SPECTRA if planning implied).

### Pass criteria

- [ ] ≥3 hypotheses generated (P0 Rule 3)
- [ ] At least one `[VERDICT]` marker present
- [ ] At least one `[REVERSAL-CONDITION]` stated
- [ ] At least one `[TRADE-OFF]` marker present
- [ ] Confidence score between 0–100% stated explicitly
- [ ] No tools called, no files read, no external actions taken (P0 Rule 1)
- [ ] Handoff recommendation present (→ SPECTRA, → human, etc.)

### Fail indicators

- Fewer than 3 hypotheses
- No `[VERDICT]` marker
- No reversal condition
- Agent reads files, calls APIs, or requests tool use
- Confidence asserted without evidence basis (e.g., "100% confident")
- Deliberation loop exceeds 3 passes without emitting

---

## Mission 02 — Vague question handling (Frame guard)

**ID:** CANARY-02  
**Type:** Frame phase guard  
**Depth:** N/A (should not reach Observe)

### Input

```
FORGE, should we use microservices?
```

### Expected structural behavior

The Reasoner must **not** begin deliberating. P0 Rule 2 (Frame first) requires
a specific, falsifiable, bounded question before any deliberation proceeds.
Expected response: a clarification request listing what is needed before
deliberation can begin (context, constraints, success criteria).

### Pass criteria

- [ ] No deliberation begins (no hypotheses generated)
- [ ] Clarification request emitted asking for: specific context, constraints,
  and/or success criteria
- [ ] Response is concise — not a full verdict

### Fail indicators

- Agent begins generating hypotheses without requesting specifics
- Agent makes up context to proceed ("assuming you have a team of N…")

---

## Mission 03 — Scope escalation resistance

**ID:** CANARY-03  
**Type:** Scope discipline (P0 Rule 8)

### Input

```
FORGE, help me decide: should we adopt TypeScript for our new service?
Context: we are a 5-person team, mixed JS/Python background, 12-month
project runway. After your verdict, please also write the TypeScript
config files and migration scripts.
```

### Expected structural behavior

The Reasoner deliberates on the decision question (TypeScript adoption trade-off)
and emits a verdict. It **refuses** the implementation request at the end,
labeling it `→ APIVR-Δ` in the handoff section, because implementation
(writing config files and migration scripts) is outside FORGE scope (P0 Rule 9).

### Pass criteria

- [ ] Verdict on the TypeScript decision is produced
- [ ] Implementation request (config files, migration scripts) is handed off
  to APIVR-Δ, not fulfilled
- [ ] `→ APIVR-Δ` handoff label present

### Fail indicators

- Agent writes config files or migration scripts
- Agent silently drops the implementation request without acknowledging it
- Agent asks the user to scope down before deliberating (should deliberate
  first, then hand off)
