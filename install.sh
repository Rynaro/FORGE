#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────
# Reasoner v1.0.0 — Install Script
#
# Installs the Reasoner deliberation agent into any project.
# Usage: bash install.sh [target-directory]
# Default target: ./agents/reasoner
# ──────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-./agents/reasoner}"

echo "╔══════════════════════════════════════════╗"
echo "║  Reasoner v1.0.0 — Install               ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Create target directory
mkdir -p "$TARGET"
mkdir -p "$TARGET/skills/framing"
mkdir -p "$TARGET/skills/deliberation"
mkdir -p "$TARGET/skills/verification"
mkdir -p "$TARGET/templates"

# Copy core files
cp "$SCRIPT_DIR/REASONER.md"          "$TARGET/REASONER.md"
cp "$SCRIPT_DIR/SKILL.md"             "$TARGET/SKILL.md"
cp "$SCRIPT_DIR/agent.md"             "$TARGET/agent.md"
cp "$SCRIPT_DIR/AGENTS.md"            "$TARGET/AGENTS.md"
cp "$SCRIPT_DIR/CLAUDE.md"            "$TARGET/CLAUDE.md"
cp "$SCRIPT_DIR/DESIGN-RATIONALE.md"  "$TARGET/DESIGN-RATIONALE.md"
cp "$SCRIPT_DIR/README.md"            "$TARGET/README.md"

# Copy skills
cp "$SCRIPT_DIR/skills/framing/SKILL.md"      "$TARGET/skills/framing/SKILL.md"
cp "$SCRIPT_DIR/skills/deliberation/SKILL.md"  "$TARGET/skills/deliberation/SKILL.md"
cp "$SCRIPT_DIR/skills/verification/SKILL.md"  "$TARGET/skills/verification/SKILL.md"

# Copy templates
cp "$SCRIPT_DIR/templates/verdict.md"              "$TARGET/templates/verdict.md"
cp "$SCRIPT_DIR/templates/trade-off-analysis.md"   "$TARGET/templates/trade-off-analysis.md"
cp "$SCRIPT_DIR/templates/feasibility-assessment.md" "$TARGET/templates/feasibility-assessment.md"
cp "$SCRIPT_DIR/templates/root-cause-analysis.md"  "$TARGET/templates/root-cause-analysis.md"
cp "$SCRIPT_DIR/templates/conflict-resolution.md"  "$TARGET/templates/conflict-resolution.md"

echo "✓ Core files installed to $TARGET"
echo ""

# ──────────────────────────────────────────────────────────
# Host detection and wiring hints
# ──────────────────────────────────────────────────────────

HOSTS_FOUND=()

# Claude Code
if [ -f ".claude/settings.json" ] || [ -f "CLAUDE.md" ]; then
  HOSTS_FOUND+=("claude-code")
  echo "→ Claude Code detected."
  echo "  Add to CLAUDE.md:  @${TARGET}/REASONER.md"
  echo "  Or create .claude/agents/reasoner.md pointing to ${TARGET}/agent.md"
  echo ""
fi

# Cursor
if [ -d ".cursor" ] || [ -f ".cursorrules" ]; then
  HOSTS_FOUND+=("cursor")
  echo "→ Cursor detected."
  echo "  Create .cursor/rules/reasoner.mdc with:"
  echo "    ---"
  echo "    description: Reasoner — structured deliberation for hard decisions"
  echo "    globs: \"**/*\""
  echo "    alwaysApply: false"
  echo "    ---"
  echo "  Then paste contents of ${TARGET}/agent.md"
  echo ""
fi

# GitHub Copilot
if [ -d ".github" ]; then
  HOSTS_FOUND+=("copilot")
  echo "→ GitHub Copilot detected."
  echo "  Copy ${TARGET}/agent.md to .github/agents/reasoner.agent.md"
  echo "  Skills go in .github/skills/reasoner/"
  echo ""
fi

# OpenCode
if [ -d ".opencode" ]; then
  HOSTS_FOUND+=("opencode")
  echo "→ OpenCode detected."
  echo "  Create .opencode/agents/reasoner.md with mode: primary"
  echo "  Reference ${TARGET}/REASONER.md for full rules"
  echo ""
fi

# AGENTS.md (cross-host standard)
if [ -f "AGENTS.md" ]; then
  echo "→ AGENTS.md found at repo root."
  echo "  Add the Reasoner section from ${TARGET}/agent.md"
  echo ""
fi

if [ ${#HOSTS_FOUND[@]} -eq 0 ]; then
  echo "  No known agent host detected. The files are installed and ready"
  echo "  for any host that reads Markdown agent instructions."
  echo ""
fi

# ──────────────────────────────────────────────────────────
# Verification hint
# ──────────────────────────────────────────────────────────

echo "──────────────────────────────────────────"
echo "Smoke test — paste this into your agent chat:"
echo ""
echo "  Reasoner, evaluate this trade-off: given a team of 3 engineers,"
echo "  a 6-week deadline, and an existing Rails monolith at 80K LOC,"
echo "  should we extract the billing service into a separate microservice"
echo "  now, or defer to next quarter? Constraints: PCI compliance audit"
echo "  in 8 weeks, no additional infrastructure budget this quarter."
echo ""
echo "Expected: The Reasoner frames the question, inventories constraints,"
echo "generates ≥3 hypotheses, scores them, and emits a verdict with"
echo "confidence score and reversal conditions."
echo "──────────────────────────────────────────"
echo ""
echo "✓ Install complete. All paths are relative — works from any location."
