# Wiring FORGE into GitHub Copilot

## 1. Install

```bash
bash install.sh --target ./agents/reasoner --hosts copilot
```

The installer creates or updates `.github/copilot-instructions.md` with a
pointer to the Reasoner.

## 2. Config

**Option A — Custom instructions pointer (`.github/copilot-instructions.md`):**

```markdown
# GitHub Copilot — FORGE Reasoner

Load `agents/reasoner/REASONER.md` when the user invokes FORGE or the Reasoner.
See `agents/reasoner/AGENTS.md` for non-negotiable rules and phase pipeline.
```

**Option B — Native agent file (Copilot agent discovery):**

```bash
mkdir -p .github/agents
cp agents/reasoner/agent.md .github/agents/reasoner.agent.md
```

Copilot discovers agents in `.github/agents/*.agent.md`. This allows
`@reasoner` invocation in Copilot Chat.

**Option C — Skills in `.github/skills/`:**

```bash
mkdir -p .github/skills/reasoner
cp agents/reasoner/skills/deliberation/SKILL.md .github/skills/reasoner/deliberation.md
```

## 3. Invoke

```
@reasoner FORGE, help me decide: [question]
```

Or, if using custom instructions only:

```
FORGE, evaluate this feasibility question: [question]
```

## 4. Verify

Paste this smoke test into Copilot Chat:

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

**"Copilot doesn't pick up the custom instructions"**  
The `.github/copilot-instructions.md` file must be in the repo root's
`.github/` directory. Verify with `cat .github/copilot-instructions.md`.
Copilot applies these to the entire repository.

**"@reasoner not recognized"**  
Native agent discovery requires Copilot agent mode and `.github/agents/`
support. Check your Copilot plan and VS Code extension version. Fall back
to custom instructions if unavailable.

**"The Reasoner is using tools"**  
P0 Rule 1 prohibits tool use. If bypassed, add an explicit prohibition in
your `.github/copilot-instructions.md`:

```markdown
The Reasoner (FORGE) must NOT use tools, read files, or call APIs.
It reasons only from context provided in the conversation.
```
