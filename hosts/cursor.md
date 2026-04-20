# Wiring FORGE into Cursor

## 1. Install

```bash
bash install.sh --target ./agents/reasoner --hosts cursor
```

The installer creates `.cursor/rules/reasoner.mdc` in your project.

## 2. Config

**`.cursor/rules/reasoner.mdc`:**

```markdown
---
description: Reasoner — structured deliberation for hard decisions (FORGE methodology)
globs: "**/*"
alwaysApply: false
---

You are operating under the FORGE methodology. Load the full spec before
deliberating:

See agents/reasoner/agent.md for the condensed descriptor.
See agents/reasoner/REASONER.md for the full methodology.

Non-negotiable (P0): reasoning-only (no tools), frame first, ≥3 hypotheses,
adversarial self-testing, evidence-anchored claims, bounded deliberation
(max 3 passes + 1 REFORGE), reversal conditions mandatory, scope discipline.
```

**`alwaysApply: false`** is recommended — load on demand when deliberation
is needed, not for every file edit.

To make the Reasoner always available (lower token cost than always-loaded):
use `alwaysApply: false` and invoke explicitly.

## 3. Invoke

In Cursor chat, attach the rule or invoke by description:

```
FORGE, help me decide: [specific question with constraints]
```

Or use the `@reasoner` reference if configured in Cursor settings.

## 4. Verify

Paste this smoke test into Cursor chat:

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

**"The .mdc rule isn't being applied"**  
Cursor loads `.cursor/rules/` files based on `globs` and `alwaysApply`.
With `alwaysApply: false`, the rule must be manually attached or invoked
via the `@rule-name` syntax. Verify with Cursor Settings → Rules.

**"I want the Reasoner always loaded"**  
Change `alwaysApply: true` in the `.mdc` frontmatter. Be aware this adds
the rule to every request's context budget.

**"FORGE cycle not being followed"**  
The `.mdc` file summary may be too condensed. Reference the full spec
file inline:
```
@agents/reasoner/REASONER.md
FORGE, [question]
```
