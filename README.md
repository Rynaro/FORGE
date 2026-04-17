# Reasoner — Structured Deliberation Agent

A standalone specialist agent that produces evidence-grounded verdicts for hard problems through adversarial self-testing.

When your stack can't agree, when the trade-offs aren't obvious, when the root cause is buried under layers of complexity — the Reasoner is the agent you escalate to.

## Architecture

```
reasoner/
├── install.sh                  # Install into any project
├── REASONER.md                 # Agent entry point (always loaded)
├── DESIGN-RATIONALE.md         # Research → design decision mapping
├── skills/                     # Loaded on-demand per phase
│   ├── framing/
│   │   └── SKILL.md            # Problem decomposition + constraint extraction
│   ├── deliberation/
│   │   └── SKILL.md            # Multi-path reasoning + hypothesis scoring
│   └── verification/
│       └── SKILL.md            # Logic checking + confidence calibration
└── templates/                  # Decision output skeletons per type
    ├── verdict.md              # General-purpose decision output
    ├── trade-off-analysis.md   # X vs Y with decision matrix
    ├── feasibility-assessment.md  # Can X be done under constraints C?
    ├── root-cause-analysis.md  # Why did X fail?
    └── conflict-resolution.md  # Agents/stakeholders disagree — arbitrate
```

## Quick Start

### Install into a project

```bash
git clone https://github.com/Rynaro/reasoner
bash reasoner/install.sh [target-directory]
```

Default target: `./agents/reasoner`. Then point your AI tooling at the installed `REASONER.md`:

| Tooling | How to load |
|---------|-------------|
| **Claude Code** | `@agents/reasoner/REASONER.md` or add to `CLAUDE.md` |
| **Cursor** | Add path to `.cursorrules` or custom instructions |
| **Windsurf** | Add path to `.windsurfrules` |
| **GitHub Copilot** | Place in `.github/agents/` or reference from `AGENTS.md` |
| **OpenCode** | Place in `.opencode/agents/` |
| **Raw API / any LLM** | Load `REASONER.md` as the system prompt |

### Alternative: Git submodule

```bash
git submodule add https://github.com/Rynaro/reasoner agents/reasoner
```

### Alternative: Direct copy

```bash
cp -r reasoner/ your-project/agents/reasoner/
```

All internal paths are relative. Works from any location.

## Decision Types

| Type | Use When |
|------|----------|
| **trade-off** | Choosing between options with competing advantages |
| **feasibility** | Evaluating whether something can be done under constraints |
| **root-cause** | Diagnosing why a complex failure occurred |
| **conflict-resolution** | Arbitrating between disagreeing agents or stakeholders |
| **constraint-satisfaction** | Finding solutions within multiple interacting constraints |
| **risk-assessment** | Mapping failure modes and their mitigations |

Custom decision types are supported — the Reasoner builds a skeleton from context when no template matches.

## FORGE Cycle

```
F ──▶ O ──▶ R ──▶ G ──┬──▶ E (gates pass)
                      └──▶ REFORGE (one pass) ──▶ E
```

- **Frame**: Define the exact question, constraints, success criteria, and deliberation depth
- **Observe**: Inventory evidence with reliability tiers (H/M/L)
- **Reason**: Generate ≥3 hypotheses, stress-test each, score across 5 dimensions
- **Gate**: Verify logic, evidence coverage, and decision completeness
- **Emit**: Deliver the verdict with confidence score, evidence chain, and handoff recommendations

## Design Principles

**Minimal entry point**: `REASONER.md` is the only file loaded at start. Skills and templates load on-demand per phase.

**Token-efficient**: Typical working set is ~2,550 tokens (entry point + one skill + one template). Leaves maximum context budget for evidence.

**Deliberation, not retrieval**: The Reasoner reasons from provided context. It does not explore codebases (ATLAS), plan work (SPECTRA), implement (APIVR-Δ), or write documents (Scribe).

**Bounded deliberation**: 1–3 reasoning passes based on problem complexity. One REFORGE after gate failure, then emit. No unbounded loops.

**Adversarial self-testing**: Every hypothesis undergoes Inversion, Boundary, Pre-Mortem, and Dependency tests. The Reasoner actively tries to break its own conclusions.

**Structural markers**: Six markers (`[VERDICT]`, `[TRADE-OFF]`, `[RISK]`, `[ASSUMPTION]`, `[CONSTRAINT]`, `[REVERSAL-CONDITION]`) transform reasoning from prose into auditable decision intelligence.

## Position in the Stack

```
         ┌──────────────────────────────────────────────────┐
         │                  User / Orchestrator              │
         └──────┬───────┬───────┬───────┬───────┬───────────┘
                │       │       │       │       │
         ┌──────▼──┐ ┌──▼───┐ ┌▼──────┐ ┌▼─────┐ ┌▼────────┐
         │ SPECTRA │ │APIVR-│ │ ATLAS │ │Scribe│ │ Reasoner │
         │ Planner │ │  Δ   │ │ Scout │ │      │ │          │
         │         │ │Coder │ │       │ │      │ │          │
         └─────────┘ └──────┘ └───────┘ └──────┘ └──────────┘
           Plans      Builds   Explores   Writes   Decides
```

The Reasoner is invoked when:
- SPECTRA encounters a decision it can't resolve with planning methodology alone
- APIVR-Δ hits a design fork that requires deliberation before implementation
- ATLAS produces a scout report that raises more questions than it answers
- Multiple agents produce conflicting recommendations
- A human needs a structured assessment before committing to an irreversible path

## Research Foundation

See [DESIGN-RATIONALE.md](DESIGN-RATIONALE.md) for the full mapping of research findings to design decisions. Key influences:

- **Reflexion** (Shinn et al., NeurIPS 2023): Bounded self-reflection — one gate + one revision max
- **PlanSearch** (Wang et al., 2024): Hypothesis diversity > solution diversity
- **Lazy Agents** (Zhang et al., arXiv 2511.02303, 2025): Multi-agent reasoning collapse; adversarial contribution is essential
- **CorrectBench** (2025): Evidence against unbounded self-correction
- **EU AI Act** (2025–2026): Structured decision logging and explainability requirements
- **SPECTRA v4.2.0**: Complexity routing, confidence calibration methodology
- **APIVR-Δ v3.0**: Layered loading architecture, token budget discipline

---

*Reasoner v1.0.0*
