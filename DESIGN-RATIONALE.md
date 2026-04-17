# Reasoner Agent — Design Rationale

How research findings, vendor analysis, and architectural patterns map to the Reasoner's design decisions.

---

## Core Design Thesis

> **The Reasoner is a deliberation agent, not a planning agent. Its value is in producing evidence-grounded verdicts for hard problems — not in decomposing work into tasks or exploring codebases.**

This thesis draws the line between the Reasoner and every other agent in the stack. SPECTRA plans. APIVR-Δ implements. ATLAS explores. Scribe documents. The Reasoner *decides* — it is the agent you invoke when the right course of action is genuinely unclear and requires structured adversarial thinking.

---

## Decision Map

### 1. FORGE Cycle (Frame → Observe → Reason → Gate → Emit), Not APIVR-Δ or SPECTRA Phases

**Research input**: The three attached research documents converge on a key finding — "reasoner mode" across vendors (OpenAI reasoning effort, Anthropic extended thinking, Cursor modes) decomposes into a deliberation budget, a tool-using loop, and a verification gate. These are not implementation phases; they are *cognitive* phases for decision-making under uncertainty.

**Decision**: 5-phase cycle — FORGE. Distinct from SPECTRA's 7-phase planning cycle and APIVR-Δ's 5-phase implementation cycle.

**Rationale**: The Reasoner doesn't plan work (no Scope, no Construct, no Assemble). It doesn't implement (no test anchors, no code). It frames a question, collects evidence, reasons through hypotheses, verifies its own logic, and emits a verdict. Five phases cover the workflow without importing irrelevant ceremony from sibling agents.

**Evidence**: OpenAI reasoning controls, Anthropic extended thinking, and the reactive-vs-deliberative pattern (Medium, Feb 2026) all distinguish *reasoning depth* as a schedulable resource, not an architectural mode. FORGE formalizes this.

### 2. Adversarial Self-Testing as Core Principle

**Research input**: Reflexion (Shinn et al., NeurIPS 2023) demonstrates 91% Pass@1 via verbal self-reflection. The "lazy agent" paper (Zhang et al., arXiv 2511.02303, Nov 2025) identifies that in multi-agent reasoning, one agent often dominates while the other contributes nothing — the deliberation collapses to single-agent behavior. CorrectBench (2025) shows unbounded self-correction degrades open-ended output quality.

**Decision**: The Reasoner's core identity is adversarial to its own conclusions. Every hypothesis undergoes four stress tests (Inversion, Boundary, Pre-Mortem, Dependency). But deliberation is bounded — max 3 passes, one REFORGE after gate failure.

**Rationale**: The lazy-agent finding is directly relevant. If the Reasoner just confirms the most obvious hypothesis, it adds no value over the upstream agent that raised the question. Adversarial self-testing prevents this collapse. But CorrectBench warns that unbounded reflection makes things worse, not better — hence the hard cap.

**Precedent**: APIVR-Δ caps retries at 3. Scribe allows one revision pass. The Reasoner allows 1–3 deliberation passes (based on depth) plus one REFORGE. Same bounded philosophy, calibrated for reasoning rather than implementation.

### 3. Structural Markers for Decision Intelligence

**Research input**: Scribe's `[DECISION]`, `[ACTION]`, `[DISPUTED]`, `[GAP]` markers. Harness AI incident scribe conventions. EU AI Act (August 2025 GPAI rules, August 2026 high-risk requirements) demanding structured decision logging with complete decision paths, intermediate reasoning steps, and confidence scores.

**Decision**: Six markers — `[VERDICT]`, `[TRADE-OFF]`, `[RISK]`, `[ASSUMPTION]`, `[CONSTRAINT]`, `[REVERSAL-CONDITION]`.

**Rationale**: The Scribe's markers are designed for documentation. The Reasoner's markers are designed for decision audit trails. `[REVERSAL-CONDITION]` is novel — it forces the Reasoner to state what would invalidate its verdict, making decisions falsifiable and time-bounded. `[ASSUMPTION]` explicitly distinguishes inference from evidence, addressing the regulatory trend toward explainable AI decision-making.

**Regulatory context**: The EU AI Act's structured decision logging requirements validate the marker approach. Even outside regulated industries, the ability to trace a decision from verdict to evidence to source is an operational necessity for production systems.

### 4. Confidence Calibration via Four-Factor Decomposition

**Research input**: SPECTRA uses a 4-factor confidence system (25% each: Pattern match, Requirement clarity, Decomposition stability, Constraint compliance). The provider-agnostic research spine recommends "evaluation must include traces, trajectories, and efficiency." Process reward models (cited in AI Trends 2026, Hugging Face) give feedback on each reasoning step, not just the final result.

**Decision**: Four-factor confidence (25% each: Evidence quality, Logical coherence, Constraint coverage, Sensitivity analysis). Both composite and per-factor scores are reported.

**Rationale**: SPECTRA's factors are calibrated for planning confidence. The Reasoner's factors are calibrated for reasoning confidence. Evidence quality and logical coherence are intrinsic to deliberation; constraint coverage and sensitivity analysis are the dimensions most likely to differentiate a good verdict from a lucky one. Reporting per-factor scores prevents a high composite from masking a critically weak dimension.

### 5. Deliberation Depth as an Adaptive Budget, Not a Fixed Pipeline

**Research input**: OpenAI reasoning effort (low/medium/high). Anthropic extended thinking with controllable token budgets. SPECTRA's complexity router (4–6 standard, 7–9 extended, 10–12 human-in-the-loop). The "deliberative systems" pattern from Galileo (April 2026) which notes planning cycles add 2–5 seconds of latency per decision.

**Decision**: Three-dimensional depth scoring (Ambiguity × Reversibility × Blast radius, each 1–3). Total maps to Simple (1 pass) / Standard (2 passes) / Deep (3 passes).

**Rationale**: Not every decision deserves the same cognitive budget. A reversible, low-impact trade-off between two well-understood options doesn't need 3 adversarial passes. An irreversible architectural decision with system-wide blast radius does. The three dimensions map directly to the *cost of being wrong*, which is the right basis for allocating reasoning budget.

**Evidence**: The vendor-neutral research spine's finding that "reasoning is a schedulable resource" is the foundational principle here. SPECTRA's complexity router is the precedent for adaptive depth in the stack.

### 6. Evidence Inventory with Reliability Tiers, Not RAG

**Research input**: GraphRAG demonstrates structured knowledge representation outperforms flat vector retrieval. "Lost in the Middle" (cited in the research spine) shows naive long-context stuffing degrades performance. ATLAS's evidence-anchored claims with `H|M|L` confidence tiers.

**Decision**: Evidence inventory protocol with H/M/L reliability tiers. The Reasoner does not retrieve — it inventories provided context.

**Rationale**: The Reasoner is downstream of ATLAS (which retrieves) and SPECTRA (which gathers context). Adding retrieval to the Reasoner would duplicate ATLAS's purpose and violate single-responsibility. Instead, the Reasoner applies quality assessment to whatever evidence it receives, ensuring that low-reliability evidence is flagged rather than silently treated as ground truth.

**Precedent**: Scribe draws the same boundary — "synthesis, not research." The Reasoner draws "deliberation, not retrieval."

### 7. Hypothesis Generation with Falsification Tests

**Research input**: PlanSearch (Wang et al., 2024) shows diversity at the plan level produces better outcomes. ToT (Yao et al., NeurIPS 2023) demonstrates 74% vs 4% improvement via multi-path exploration. Popper's falsificationism (philosophical foundation). The "Cross-Verification Collaboration Protocol" (CVCP, high-confidence academic research) demonstrates adversarial testing agents dramatically improve pass rates.

**Decision**: ≥3 hypotheses minimum, each with explicit falsification tests ("This hypothesis is wrong if…").

**Rationale**: PlanSearch and ToT established that multi-path exploration improves outcomes. The Reasoner extends this from *generation diversity* to *epistemic diversity* — each hypothesis must be not just different but falsifiable. This prevents strawman alternatives (a common failure mode where the "losing" hypotheses are obviously inferior, serving only to validate the foregone conclusion).

### 8. Template-Driven Output per Decision Type

**Research input**: Scribe's template architecture (session-chronicle, ADR, runbook, change-narrative). SPECTRA's dual-output requirement (Markdown + structured data). Copilot Agent Mode's dual-plan representation (human-readable Markdown + machine-readable JSON).

**Decision**: Five templates (verdict, trade-off-analysis, feasibility-assessment, root-cause-analysis, conflict-resolution) plus custom mode.

**Rationale**: Different decision types require different structural elements. A trade-off analysis needs a decision matrix. A root cause analysis needs causal chains. A feasibility assessment needs a constraint walkthrough. Templates enforce structural completeness — you can't skip the constraint walkthrough in a feasibility assessment because the template makes its absence obvious.

---

## What Was Explicitly Excluded (and Why)

| Excluded | Reason |
|----------|--------|
| Code retrieval / codebase exploration | Not deliberation. ATLAS does that. |
| Task decomposition / work planning | Not deliberation. SPECTRA does that. |
| Implementation / code generation | Not deliberation. APIVR-Δ does that. |
| Document synthesis | Not deliberation. Scribe does that. |
| Unbounded debate / multi-agent deliberation | Lazy-agent collapse risk (Zhang et al., 2025). Single-agent adversarial self-testing is more token-efficient and avoids coordination overhead. |
| Tree search / MCTS for reasoning | Overkill for decision problems. LATS-style search is valuable for code generation (92.7% on HumanEval) but the Reasoner isn't generating solutions — it's evaluating them. Hypothesis scoring is the lightweight equivalent. |
| Self-evolving scaffold | Promising (Live-SWE-agent, 75.4% on SWE-bench Verified) but premature for a deliberation agent. Reasoning methodology should be stable; tool creation belongs in APIVR-Δ. |
| Memory subsystem | The Reasoner is stateless by design. Each invocation receives fresh context. Persistent patterns belong in the Orchestrator's or SPECTRA's memory, not in the Reasoner. |
| Probabilistic / Bayesian scoring | Theoretically elegant but impractical without calibrated priors. The 5-dimension rubric with integer scores is the pragmatic approximation. |

---

## Boundary Clarification: FORGE vs SPECTRA Explore

The open thread in the project instructions raises a sharp question — SPECTRA's Explore phase also generates and scores multiple hypotheses. Where is the boundary?

**The boundary is the shape of the question, not the technique.**

| Dimension | SPECTRA Explore | FORGE Reason |
|-----------|-----------------|--------------|
| **Question shape** | "How should we build X?" | "Should we do X at all — and if so, which of these alternatives wins?" |
| **Output** | Decomposition into stories, phases, and build strategy | A verdict: a chosen position with conditions |
| **Hypotheses represent** | Distinct decomposition strategies for implementation | Distinct positions on a judgment question |
| **Scoring dimensions** | Feasibility, implementation clarity, risk-per-story, sequencing | Evidence alignment, constraint satisfaction, risk profile, reversibility, second-order clarity |
| **Next step** | Construct phase → Assemble → spec handoff | Emit phase → verdict → handoff to whichever agent's work the decision enables |
| **Caller's need** | "I've decided to build X, help me plan the build" | "I don't know if we should build X, or which X — help me decide" |

**In practice:**

- A caller unsure whether to migrate to Postgres 16 → **FORGE**. Output: a verdict with reversal conditions.
- A caller who has decided to migrate and needs a phased plan → **SPECTRA**. Output: a spec with stories.
- A caller with a planned migration that hit an ambiguous fork partway → **FORGE invoked by SPECTRA** on the specific fork. FORGE emits a verdict on the fork; SPECTRA incorporates it into the plan and continues.

The composition pattern is important: **FORGE is consultable from within SPECTRA's pipeline**, not a replacement for it. When SPECTRA's Explore phase surfaces hypotheses that represent genuine judgment calls (not just implementation variants), those calls escalate to FORGE. The verdict returns as a constraint SPECTRA then plans around.

This is the same pattern that the research spine (Provider-Agnostic Stack, attached doc 1) identifies as "reasoning is a schedulable resource" — FORGE is the resource SPECTRA schedules when its own decomposition machinery hits a judgment bottleneck.

---

## Acronym Word Choices

The project instructions offered a candidate expansion: Frame / Outline / Reason / Ground / Evaluate. The shipped methodology uses: **Frame / Observe / Reason / Gate / Emit**.

| Letter | Candidate | Chosen | Why |
|--------|-----------|--------|-----|
| F | Frame | Frame | Match. Decomposition of the decision question. |
| O | Outline | **Observe** | "Outline" implies structural sketching, which belongs in Frame. "Observe" is active evidence inventory — the distinct work of the second phase. |
| R | Reason | Reason | Match. Multi-path hypothesis generation and scoring. |
| G | Ground | **Gate** | "Ground" describes what you do throughout (anchor claims to evidence). "Gate" captures the discrete verification checkpoint — pass/fail before delivery. Grounding is a property; gating is an action. |
| E | Evaluate | **Emit** | "Evaluate" overlaps with Reason (scoring is evaluation). "Emit" captures the delivery of the verdict as a distinct phase — the transition from internal deliberation to external artifact. |

Both sets are defensible; the chosen set is more differentiated phase-to-phase and maps cleanly to distinct observable outputs per phase.

---

## Token Budget Analysis

| Component | Estimated Tokens | When Loaded |
|-----------|-----------------|-------------|
| REASONER.md (entry point) | ~1,150 | Always when Reasoner active |
| skills/framing/SKILL.md | ~920 | Frame phase |
| skills/deliberation/SKILL.md | ~1,100 | Reason phase |
| skills/verification/SKILL.md | ~950 | Gate phase |
| Template (largest: verdict) | ~480 | Per decision type |

**Typical working set**: REASONER.md + one skill + one template ≈ **2,550 tokens**

This is consistent with the stack's design envelope:
- Scribe: ~2,200 tokens working set
- APIVR-Δ: ~4,350 tokens working set
- ATLAS: ~2,100 tokens working set (agent.md + one skill)

The remaining context budget is available for the evidence the Reasoner needs to deliberate on — which is the right priority, since deliberation quality scales with evidence quality, not with instruction volume.

---

## Research Sources

| Source | Contribution to Reasoner Design |
|--------|-------------------------------|
| Provider-Agnostic Research Spine (attached doc 1) | Six-layer stack model; "reasoner mode" decomposition; hierarchical token budgeting; harness-level safety |
| Reasoner-Style Multi-Agent Systems (attached doc 2) | SWE-agent ACI; CAT context compression; GCC versioned context; Live-SWE-agent self-evolution |
| Foundation Architecture (attached doc 3) | Macro-micro policy separation; Context Folding; BACM budget-aware management; CVCP cross-verification |
| Reflexion (Shinn et al., NeurIPS 2023) | Bounded self-reflection: one gate + one revision max |
| CorrectBench (arXiv 2510.16062, 2025) | Evidence against unbounded self-correction for open-ended tasks |
| PlanSearch (Wang et al., 2024) | Diversity at plan/hypothesis level > diversity at solution level |
| Tree of Thoughts (Yao et al., NeurIPS 2023) | Multi-path exploration with evaluation and backtracking |
| Lazy Agents (Zhang et al., arXiv 2511.02303, 2025) | Multi-agent reasoning collapse; need for adversarial contribution verification |
| EU AI Act GPAI rules (August 2025) | Structured decision logging, explainability requirements |
| SPECTRA v4.2.0 | Complexity router, confidence calibration, failure taxonomy |
| APIVR-Δ v3.0 | Layered loading architecture, bounded retries, token budget methodology |
| Scribe v1.1.0 | Structural markers, bounded reflection, template-driven output |
| ATLAS v1.0 | Evidence-anchored claims, deliberation-free retrieval, handoff protocol |

---

*Reasoner v1.0.0 — Design Rationale*
