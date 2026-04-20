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
