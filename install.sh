#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────
# Reasoner v1.1.0 — Install Script (EIIS-1.0 conformant)
#
# Installs the Reasoner deliberation agent into any project.
# Usage: bash install.sh [OPTIONS]
# ──────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EIDOLON_NAME="forge"
EIDOLON_VERSION="1.1.0"
METHODOLOGY="FORGE"

# --- defaults ---
TARGET="./agents/reasoner"
HOSTS="auto"
FORCE=false
DRY_RUN=false
NON_INTERACTIVE=false
MANIFEST_ONLY=false

usage() {
  cat <<EOF
Usage: bash install.sh [OPTIONS]

Options:
  --target DIR          Target install dir (default: ${TARGET})
  --hosts LIST          claude-code,copilot,cursor,opencode,all (default: auto)
  --force               Overwrite existing install
  --dry-run             Print actions, no writes
  --non-interactive     No prompts; fail on ambiguity (meta-installer mode)
  --manifest-only       Only emit install.manifest.json
  --version             Print Eidolon version
  -h, --help            Show help
EOF
}

# --- arg parsing (legacy positional arg supported with deprecation warning) ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)           TARGET="$2"; shift 2 ;;
    --hosts)            HOSTS="$2"; shift 2 ;;
    --force)            FORCE=true; shift ;;
    --dry-run)          DRY_RUN=true; shift ;;
    --non-interactive)  NON_INTERACTIVE=true; shift ;;
    --manifest-only)    MANIFEST_ONLY=true; shift ;;
    --version)          echo "${EIDOLON_VERSION}"; exit 0 ;;
    -h|--help)          usage; exit 0 ;;
    -*)                 echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)
      TARGET="$1"
      echo "Warning: positional target is deprecated; use --target DIR instead" >&2
      shift ;;
  esac
done

# --- host detection ---
detect_hosts() {
  local detected=()
  [[ -f "CLAUDE.md" || -d ".claude" ]]        && detected+=("claude-code")
  [[ -d ".github" ]]                           && detected+=("copilot")
  [[ -d ".cursor" || -f ".cursorrules" ]]      && detected+=("cursor")
  [[ -d ".opencode" ]]                         && detected+=("opencode")
  if [[ ${#detected[@]} -eq 0 ]]; then
    echo "none"
  else
    local IFS=','; echo "${detected[*]}"
  fi
}

if [[ "$HOSTS" == "auto" ]]; then
  HOSTS="$(detect_hosts)"
fi

echo "╔══════════════════════════════════════════╗"
echo "║  Reasoner v${EIDOLON_VERSION} — Install               ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# --- idempotency check ---
if [[ -f "${TARGET}/install.manifest.json" && "$FORCE" != "true" ]]; then
  EXISTING_VER=$(grep -o '"version":"[^"]*"' "${TARGET}/install.manifest.json" 2>/dev/null | cut -d'"' -f4 || echo "unknown")
  if [[ "$NON_INTERACTIVE" == "true" ]]; then
    echo "Existing install v${EXISTING_VER} at ${TARGET}. Pass --force to overwrite." >&2
    exit 3
  fi
  read -rp "Existing install v${EXISTING_VER} at ${TARGET}. Overwrite? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

# ──────────────────────────────────────────────────────────
# Copy methodology files
# ──────────────────────────────────────────────────────────

if [[ "$MANIFEST_ONLY" != "true" ]]; then
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] Would create: ${TARGET}/"
    echo "[dry-run] Would copy: REASONER.md, SKILL.md, agent.md, AGENTS.md, CLAUDE.md, DESIGN-RATIONALE.md, README.md"
    echo "[dry-run] Would copy: skills/framing/SKILL.md, skills/deliberation/SKILL.md, skills/verification/SKILL.md"
    echo "[dry-run] Would copy: templates/verdict.md, trade-off-analysis.md, feasibility-assessment.md, root-cause-analysis.md, conflict-resolution.md"
    echo ""
  else
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
    cp "$SCRIPT_DIR/skills/framing/SKILL.md"       "$TARGET/skills/framing/SKILL.md"
    cp "$SCRIPT_DIR/skills/deliberation/SKILL.md"   "$TARGET/skills/deliberation/SKILL.md"
    cp "$SCRIPT_DIR/skills/verification/SKILL.md"   "$TARGET/skills/verification/SKILL.md"

    # Copy templates
    cp "$SCRIPT_DIR/templates/verdict.md"               "$TARGET/templates/verdict.md"
    cp "$SCRIPT_DIR/templates/trade-off-analysis.md"    "$TARGET/templates/trade-off-analysis.md"
    cp "$SCRIPT_DIR/templates/feasibility-assessment.md" "$TARGET/templates/feasibility-assessment.md"
    cp "$SCRIPT_DIR/templates/root-cause-analysis.md"   "$TARGET/templates/root-cause-analysis.md"
    cp "$SCRIPT_DIR/templates/conflict-resolution.md"   "$TARGET/templates/conflict-resolution.md"

    echo "✓ Core files installed to $TARGET"
    echo ""
  fi
fi

# ──────────────────────────────────────────────────────────
# Host detection and dispatch file writing
# ──────────────────────────────────────────────────────────

hosts_wired_arr=()

wire_host() {
  local host="$1"
  case "$host" in
    claude-code)
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] Would append FORGE pointer to CLAUDE.md"
      elif [[ -f "CLAUDE.md" ]]; then
        if ! grep -q "${TARGET}/REASONER.md" "CLAUDE.md" 2>/dev/null; then
          printf '\n# Reasoner (FORGE)\n@%s/REASONER.md\n' "${TARGET}" >> "CLAUDE.md"
          echo "→ Claude Code: appended FORGE pointer to CLAUDE.md"
        else
          echo "→ Claude Code: CLAUDE.md already references ${TARGET}/REASONER.md (skipped)"
        fi
        hosts_wired_arr+=("claude-code")
      fi
      ;;
    copilot)
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] Would create/update .github/copilot-instructions.md"
      else
        mkdir -p ".github"
        local COPILOT_INSTR=".github/copilot-instructions.md"
        if [[ ! -f "$COPILOT_INSTR" ]]; then
          cat > "$COPILOT_INSTR" <<EOF
# GitHub Copilot — FORGE Reasoner methodology

> Authoritative rule set: \`${TARGET}/AGENTS.md\`. This file is a minimal pointer.

Load \`${TARGET}/REASONER.md\` when the user invokes the Reasoner or FORGE methodology.
See \`${TARGET}/AGENTS.md\` for full non-negotiable rules and phase pipeline.
EOF
          echo "→ Copilot: created .github/copilot-instructions.md"
        else
          if ! grep -q "${TARGET}" "$COPILOT_INSTR" 2>/dev/null; then
            printf '\n# Reasoner (FORGE)\nSee %s/AGENTS.md\n' "${TARGET}" >> "$COPILOT_INSTR"
            echo "→ Copilot: appended FORGE pointer to .github/copilot-instructions.md"
          else
            echo "→ Copilot: copilot-instructions.md already references ${TARGET} (skipped)"
          fi
        fi
        hosts_wired_arr+=("copilot")
      fi
      ;;
    cursor)
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] Would create .cursor/rules/reasoner.mdc"
      else
        mkdir -p ".cursor/rules"
        local CURSOR_RULE=".cursor/rules/reasoner.mdc"
        if [[ ! -f "$CURSOR_RULE" || "$FORCE" == "true" ]]; then
          cat > "$CURSOR_RULE" <<EOF
---
description: Reasoner — structured deliberation for hard decisions (FORGE methodology)
globs: "**/*"
alwaysApply: false
---

See ${TARGET}/agent.md for the full Reasoner specification.
Invoke with: "Reasoner, help me decide: ..."
EOF
          echo "→ Cursor: created .cursor/rules/reasoner.mdc"
        else
          echo "→ Cursor: .cursor/rules/reasoner.mdc already exists (use --force to overwrite)"
        fi
        hosts_wired_arr+=("cursor")
      fi
      ;;
    opencode)
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] Would create .opencode/agents/reasoner.md"
      else
        mkdir -p ".opencode/agents"
        local OC_AGENT=".opencode/agents/reasoner.md"
        if [[ ! -f "$OC_AGENT" || "$FORCE" == "true" ]]; then
          cat > "$OC_AGENT" <<EOF
---
mode: primary
description: Reasoner — structured deliberation for hard decisions (FORGE methodology)
---

See ${TARGET}/REASONER.md for full rules.
EOF
          echo "→ OpenCode: created .opencode/agents/reasoner.md"
        else
          echo "→ OpenCode: .opencode/agents/reasoner.md already exists (use --force to overwrite)"
        fi
        hosts_wired_arr+=("opencode")
      fi
      ;;
  esac
}

if [[ "$HOSTS" != "none" ]]; then
  IFS=',' read -ra HOST_LIST <<< "$HOSTS"
  for h in "${HOST_LIST[@]}"; do
    h="${h// /}"
    if [[ "$h" == "all" ]]; then
      for all_h in claude-code copilot cursor opencode; do
        wire_host "$all_h"
      done
    else
      wire_host "$h"
    fi
  done
fi

# ──────────────────────────────────────────────────────────
# Emit install.manifest.json
# ──────────────────────────────────────────────────────────

INSTALLED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
HOSTS_WIRED_JSON=""
if [[ ${#hosts_wired_arr[@]} -gt 0 ]]; then
  HOSTS_WIRED_JSON="$(printf '"%s",' "${hosts_wired_arr[@]}" | sed 's/,$//')"
fi

AGENT_TOKENS=0
if [[ -f "${TARGET}/agent.md" ]]; then
  AGENT_TOKENS=$(wc -w < "${TARGET}/agent.md" | awk '{printf "%d", $1/0.75}')
elif [[ -f "${SCRIPT_DIR}/agent.md" ]]; then
  AGENT_TOKENS=$(wc -w < "${SCRIPT_DIR}/agent.md" | awk '{printf "%d", $1/0.75}')
fi

if [[ "$DRY_RUN" != "true" ]]; then
  mkdir -p "${TARGET}"
  cat > "${TARGET}/install.manifest.json" <<EOF
{
  "eidolon": "${EIDOLON_NAME}",
  "version": "${EIDOLON_VERSION}",
  "methodology": "${METHODOLOGY}",
  "installed_at": "${INSTALLED_AT}",
  "target": "${TARGET}",
  "hosts_wired": [${HOSTS_WIRED_JSON}],
  "files_written": [],
  "token_budget": {
    "entry": ${AGENT_TOKENS},
    "working_set_target": 1000
  },
  "security": {
    "reads_repo": false,
    "reads_network": false,
    "writes_repo": false,
    "persists": []
  }
}
EOF
  echo "✓ Manifest written to ${TARGET}/install.manifest.json"
fi

# ──────────────────────────────────────────────────────────
# Token budget measurement
# ──────────────────────────────────────────────────────────

echo ""
echo "✓ agent.md: ${AGENT_TOKENS} tokens (budget: ≤1000)"
if [[ "$AGENT_TOKENS" -gt 1000 && "$NON_INTERACTIVE" == "true" ]]; then
  echo "ERROR: agent.md exceeds 1000-token budget in non-interactive mode." >&2
  exit 4
fi

# ──────────────────────────────────────────────────────────
# Smoke test banner
# ──────────────────────────────────────────────────────────

echo ""
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
