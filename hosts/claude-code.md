# Wiring FORGE into Claude Code

## 1. Install

```bash
bash install.sh --target ./.eidolons/forge --hosts claude-code
```

The installer writes `SPEC.md` and wires `.claude/agents/forge.md` and
`.claude/skills/forge-<phase>/SKILL.md` in your project.

## 2. Config

**Option A — `CLAUDE.md` pointer (always-loaded):**

```markdown
# CLAUDE.md
@.eidolons/forge/SPEC.md
```

This loads the Reasoner spec into every Claude Code session in the project.
Use this when FORGE deliberation is a frequent operation.

**Option B — Sub-agent registration (on-demand, recommended for large projects):**

```bash
mkdir -p .claude/agents
ln -sf ../../.eidolons/forge/agent.md .claude/agents/reasoner.md
```

Claude Code will discover `reasoner` as an available sub-agent but only load
it when invoked. This preserves context budget.

**Option C — Direct reference per session:**

```
@.eidolons/forge/SPEC.md

FORGE, help me decide: [question]
```

## 3. Invoke

```
FORGE, help me decide: [specific, bounded question]

Reasoner, evaluate this trade-off: [context + constraints]

@SPEC.md
FORGE, arbitrate: SPECTRA recommends X, APIVR-Δ flagged Y as problematic.
```

## 4. Verify

Paste this smoke test into Claude Code:

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

**"The agent doesn't follow FORGE cycle steps"**  
Ensure `SPEC.md` is being loaded (not just `agent.md`). The full cycle
spec is in `SPEC.md`. `agent.md` is a condensed descriptor for sub-agent
registration — it references `SPEC.md` explicitly.

**"The Reasoner is reading files / calling tools"**  
P0 Rule 1 prohibits tool use. If the model is bypassing this, the CLAUDE.md
or sub-agent file may not be loaded correctly. Verify with `@.eidolons/forge/agent.md`
inline before the prompt.

**"Only getting 2 hypotheses"**  
P0 Rule 3 requires ≥3. If consistently getting 2, the `skills/deliberation.md`
skill may not be loaded. During the Reason phase, load it explicitly:
```
@.eidolons/forge/skills/deliberation.md
```
