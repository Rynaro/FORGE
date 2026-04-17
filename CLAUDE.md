# CLAUDE.md

Claude Code reads this file. The Reasoner / FORGE methodology lives in
[`AGENTS.md`](./AGENTS.md) — the single source of truth that is also
auto-discovered by GitHub Copilot, Cursor, and OpenCode.

To activate the Reasoner in this workspace, reference `REASONER.md`:

```
@REASONER.md

FORGE, {your deliberation request}
```

Or register the agent definition explicitly:

```bash
mkdir -p .claude/agents
ln -sf ../../agent.md .claude/agents/reasoner.md
```

Full specification and architecture details: see [`AGENTS.md`](./AGENTS.md)
and [`REASONER.md`](./REASONER.md).
