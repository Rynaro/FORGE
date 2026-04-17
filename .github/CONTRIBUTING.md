# Contributing to the Reasoner

Contributions should strengthen the methodology. The Reasoner is a deliberation methodology — a way of thinking about hard decisions — not a framework or library. Keep that distinction in mind when proposing changes.

## Most Valuable Contributions

1. **Case studies** — Real-world deliberations where you applied the Reasoner. What worked? What didn't? What would you change in the methodology? Every case study becomes a benchmark data point.
2. **Failure mode catalog** — Deliberations that went wrong. Why? What marker, rubric dimension, or gate check would have caught it?
3. **Template refinements** — If you invented a new decision type or found a structural gap in an existing template, propose it.
4. **Host integrations** — Wiring guides for hosts not yet documented (e.g., Windsurf, Aider, Cline, Continue).

## What to Avoid

- **Adding runtime dependencies.** The Reasoner is a set of Markdown instructions. It has no runtime.
- **Expanding scope into planning, implementation, or exploration.** Those belong to SPECTRA, APIVR-Δ, and ATLAS respectively.
- **Unbounded deliberation patterns.** CorrectBench and Reflexion both establish that bounded reflection beats unbounded. Proposals for "deeper" or "longer" reasoning should come with evidence, not just intuition.
- **Model-specific prompts.** The Reasoner must remain provider-agnostic. If a pattern only works on one model family, it doesn't belong.

## How to Propose Changes

1. Open an issue using the appropriate template (methodology feedback or case study)
2. For methodology changes, include:
   - The specific behavior you observed
   - Why the current design doesn't handle it well
   - Your proposed change
   - Evidence (research papers, production observations, or reasoned argument)
3. For new templates or skills, include a worked example showing how the new structure improves output quality

## Methodology Change Criteria

A proposed change should:
- **Trace to evidence** — cite research, document production failures, or present a reasoned argument grounded in cognitive science or decision theory
- **Preserve vendor-agnosticism** — work across Claude, GPT, Gemini, Llama, and future models
- **Respect token budgets** — additions should justify their context cost
- **Fit the stack** — not duplicate SPECTRA, APIVR-Δ, ATLAS, or Scribe responsibilities

## Versioning

The Reasoner follows semantic versioning:
- **Major** (1.x → 2.x): Breaking changes to FORGE cycle phases, mandatory markers, or core principles
- **Minor** (1.0 → 1.1): New templates, new skills, new decision types — backward compatible
- **Patch** (1.0.0 → 1.0.1): Clarifications, typo fixes, rubric refinements

## License

By contributing, you agree that your contributions will be licensed under CC BY-SA 4.0 (the same license as the Reasoner itself).
