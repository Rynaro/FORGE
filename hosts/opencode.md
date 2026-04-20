# Wiring FORGE into OpenCode

## 1. Install

```bash
bash install.sh --target ./agents/reasoner --hosts opencode
```

The installer creates `.opencode/agents/reasoner.md` in your project.

## 2. Config

**`.opencode/agents/reasoner.md`:**

```markdown
---
mode: primary
description: Reasoner — structured deliberation for hard decisions (FORGE methodology)
---

See agents/reasoner/REASONER.md for the full specification.

Non-negotiable (P0): reasoning-only (no tools), frame first, ≥3 hypotheses,
adversarial self-testing, evidence-anchored claims, bounded deliberation,
reversal conditions mandatory.

Invoke with: "FORGE, help me decide: [question]"
```

`mode: primary` makes the Reasoner available as a named agent in OpenCode.

## 3. Invoke

```
FORGE, help me decide: [specific, bounded question]

Reasoner, evaluate this feasibility question: [context + constraints]
```

## 4. Verify

Paste this smoke test:

```
FORGE, evaluate this trade-off: given a team of 3 engineers,
a 6-week deadline, and an existing Rails monolith at 80K LOC,
should we extract the billing service into a separate microservice
now, or defer to next quarter? Constraints: PCI compliance audit
in 8 weeks, no additional infrastructure budget this quarter.
```

Expected: Frame → Observe → Reason (≥3 hypotheses) → Gate → Emit verdict
with confidence score and reversal conditions.

## 5. Troubleshooting

**"Agent not discovered"**  
OpenCode discovers agents in `.opencode/agents/`. Verify the file exists:
`ls .opencode/agents/`. Restart OpenCode after adding new agent files.

**"The Reasoner is performing actions instead of reasoning"**  
Reinforce the P0 constraint in the agent file header:

```markdown
CRITICAL: This agent does NOT use tools, read files, execute code, or
mutate state. It reasons only from context provided by the user.
```

**"Full FORGE cycle not followed"**  
Reference the full spec:
```
@agents/reasoner/REASONER.md

FORGE, [question]
```
