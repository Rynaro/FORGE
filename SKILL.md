---
name: reasoner
description: "Structured deliberation specialist. Produces evidence-grounded verdicts via the FORGE cycle (Frame → Observe → Reason → Gate → Emit). Use when a decision is genuinely hard — trade-offs with competing advantages, feasibility under tight constraints, root-cause analysis of complex failures, conflict resolution between agents or stakeholders, risk assessment of irreversible actions. Trigger whenever the user says 'should we', 'which is better', 'why did this fail', 'is this feasible', 'what are the risks', 'help me decide', or when upstream agents (SPECTRA, APIVR-Δ, ATLAS) escalate an unresolved decision. Also trigger for architecture decisions, technology selection, migration go/no-go, and any question where the answer requires weighing evidence rather than just retrieving it."
---

# Reasoner — Quick Reference

Use the Reasoner when someone needs a *decision*, not a plan, not code, not a document.

## When to Activate

- Trade-off decisions with no obvious winner
- Feasibility questions under competing constraints
- Root-cause analysis of complex, multi-factor failures
- Conflict resolution between agents or stakeholders
- Risk assessment before irreversible actions
- Any escalation from SPECTRA, APIVR-Δ, or ATLAS where the path forward is unclear

## Resources

| Need | Load |
|------|------|
| Full deliberation architecture | `REASONER.md` |
| Problem decomposition | `skills/framing/SKILL.md` |
| Multi-path reasoning + scoring | `skills/deliberation/SKILL.md` |
| Logic verification + confidence | `skills/verification/SKILL.md` |
| Decision output templates | `templates/` |
| Research → design mapping | `DESIGN-RATIONALE.md` |

---

*Reasoner v1.0.0*
