# Installing the Reasoner (FORGE)

The Reasoner is installed by copying its files into your project and wiring
your AI tooling to point at the entry file. The `install.sh` script handles
detection and wiring automatically.

## Quick install

```bash
# From the Reasoner repo root, run inside your target project:
bash /path/to/forge/install.sh

# Or specify a custom target directory:
bash /path/to/forge/install.sh --target ./agents/reasoner

# Dry-run to preview changes without writing:
bash /path/to/forge/install.sh --dry-run
```

Default install target: `./agents/reasoner`

## Host wiring

### Claude Code

After install, add the Reasoner to your project's `CLAUDE.md`:

```
@agents/reasoner/REASONER.md
```

Or register as a sub-agent (Claude Code ≥ 1.x):

```bash
mkdir -p .claude/agents
ln -sf ../../agents/reasoner/agent.md .claude/agents/reasoner.md
```

Then invoke:

```
@REASONER.md

FORGE, help me decide: [your question]
```

### GitHub Copilot

1. Copy the Reasoner into your project: `bash install.sh --hosts copilot`
2. The installer creates or updates `.github/copilot-instructions.md` with
   a pointer to `agents/reasoner/AGENTS.md`.
3. Alternatively, place `agents/reasoner/agent.md` in `.github/agents/` for
   Copilot's native agent discovery:

```bash
mkdir -p .github/agents
cp agents/reasoner/agent.md .github/agents/reasoner.agent.md
```

### Cursor

1. Run `bash install.sh --hosts cursor` — creates `.cursor/rules/reasoner.mdc`
2. Or create manually:

```markdown
---
description: Reasoner — structured deliberation for hard decisions (FORGE)
globs: "**/*"
alwaysApply: false
---

See agents/reasoner/agent.md for the full specification.
```

### OpenCode

1. Run `bash install.sh --hosts opencode` — creates `.opencode/agents/reasoner.md`
2. Or create manually:

```markdown
---
mode: primary
description: Reasoner — structured deliberation for hard decisions (FORGE)
---

See agents/reasoner/REASONER.md for full rules.
```

### Raw API / any LLM

Load `REASONER.md` as the system prompt. No other files required for
basic deliberation. Load skills and templates on demand per phase.

## Verify the install

After installing, paste this smoke-test prompt into your AI tool:

```
Reasoner, evaluate this trade-off: given a team of 3 engineers, a
6-week deadline, and an existing Rails monolith at 80K LOC, should
we extract the billing service into a separate microservice now, or
defer to next quarter? Constraints: PCI compliance audit in 8 weeks,
no additional infrastructure budget this quarter.
```

**Expected behavior:** The Reasoner frames the question, inventories
the constraints, generates ≥3 hypotheses, scores them across 5
dimensions, and emits a verdict with a confidence score and reversal
conditions. If it asks clarifying questions instead of deliberating
immediately, that is also correct (the Frame phase may request
missing success criteria).

## Upgrade

To upgrade to a newer version:

```bash
bash /path/to/new-forge/install.sh --target ./agents/reasoner --force
```

The `--force` flag skips the version-compare prompt. The installer
updates all files and writes a new `install.manifest.json`.

## Uninstall

Remove the installed directory and any dispatch file entries:

```bash
rm -rf ./agents/reasoner
# Then remove the @agents/reasoner/REASONER.md line from CLAUDE.md,
# .cursor/rules/reasoner.mdc, etc.
```

## Non-interactive / meta-installer mode

For use inside a meta-installer script (e.g., `eidolons-init`):

```bash
bash install.sh \
  --target ./agents/reasoner \
  --hosts all \
  --non-interactive \
  --force
```

Exits with code 3 if an existing install is found without `--force`.
Exits with code 4 if `agent.md` exceeds 1000 tokens.
