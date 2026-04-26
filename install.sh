#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────
# Reasoner v1.1.1 — Install Script (EIIS-1.0 conformant)
#
# Installs the Reasoner deliberation agent into any project.
# Usage: bash install.sh [OPTIONS]
# ──────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EIDOLON_NAME="forge"
EIDOLON_VERSION="1.1.1"
METHODOLOGY="FORGE"

# --- defaults ---
TARGET="./agents/reasoner"
HOSTS="auto"
FORCE=false
DRY_RUN=false
NON_INTERACTIVE=false
MANIFEST_ONLY=false
# EIIS v1.1 §2.2 / §2.3 — shared-dispatch flag (SHOULD in v1.0 / v1.1,
# promoted to MUST in v1.2). Default mirrors EIIS skeleton: false (per-host
# vendor files are self-sufficient; root composition is opt-in).
SHARED_DISPATCH=false

usage() {
  cat <<EOF
Usage: bash install.sh [OPTIONS]

Options:
  --target DIR          Target install dir (default: ${TARGET})
  --hosts LIST          claude-code,copilot,cursor,opencode,codex,all
                        (default: auto)
  --shared-dispatch     Compose marker-bounded section in root AGENTS.md /
                        CLAUDE.md / .github/copilot-instructions.md.
  --no-shared-dispatch  Skip root composition (default).
                        NB: when 'codex' is wired, root AGENTS.md is still
                        written (EIIS v1.1 §4.1.0 — Codex's primary surface).
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
    --target)             TARGET="$2"; shift 2 ;;
    --hosts)              HOSTS="$2"; shift 2 ;;
    --shared-dispatch)    SHARED_DISPATCH=true; shift ;;
    --no-shared-dispatch) SHARED_DISPATCH=false; shift ;;
    --force)              FORCE=true; shift ;;
    --dry-run)            DRY_RUN=true; shift ;;
    --non-interactive)    NON_INTERACTIVE=true; shift ;;
    --manifest-only)      MANIFEST_ONLY=true; shift ;;
    --version)            echo "${EIDOLON_VERSION}"; exit 0 ;;
    -h|--help)            usage; exit 0 ;;
    -*)                   echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
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
  # Codex (EIIS v1.1 §4.5): .codex/ is the definitive Codex-only signal;
  # AGENTS.md alone (no .github/, no .codex/) also indicates Codex.
  [[ -d ".codex" ]]                            && detected+=("codex")
  if [[ -f "AGENTS.md" && ! -d ".github" && ! -d ".codex" ]]; then
    detected+=("codex")
  fi
  if [[ ${#detected[@]} -eq 0 ]]; then
    echo "none"
  else
    local IFS=','; echo "${detected[*]}"
  fi
}

if [[ "$HOSTS" == "auto" ]]; then
  HOSTS="$(detect_hosts)"
elif [[ "$HOSTS" == "all" ]]; then
  HOSTS="claude-code,copilot,cursor,opencode,codex"
fi

# Validate the host list (--hosts LIST values per EIIS §2.1 / §3.2).
IFS=',' read -ra _HOST_VALIDATE <<< "$HOSTS"
for _h in "${_HOST_VALIDATE[@]}"; do
  _h="${_h// /}"
  case "$_h" in
    claude-code|copilot|cursor|opencode|codex|raw|none|all|"") : ;;
    *) echo "Invalid --hosts value: $_h" >&2; exit 2 ;;
  esac
done

# --- utilities (EIIS v1.1 §3.3 — files_written tracking) ---
sha256_file() {
  local f="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$f" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$f" | awk '{print $NF}'
  else
    echo "0000000000000000000000000000000000000000000000000000000000000000"
  fi
}

# FILES_WRITTEN accumulates JSON object literals; flushed into the manifest.
FILES_WRITTEN=()

# record_file <path> <role> <mode>
#   role: entry-point | spec | skill | template | dispatch | manifest | other
#   mode: created | appended | overwritten | rewritten
record_file() {
  local p="$1" role="$2" mode="$3"
  [[ -f "$p" ]] || return 0
  local chk; chk=$(sha256_file "$p")
  FILES_WRITTEN+=("{\"path\":\"${p}\",\"sha256\":\"${chk}\",\"role\":\"${role}\",\"mode\":\"${mode}\"}")
}

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

    # copy_tracked <src-rel> <dst> <role>
    copy_tracked() {
      local src="$1" dst="$2" role="$3"
      cp "$SCRIPT_DIR/$src" "$dst"
      record_file "$dst" "$role" "created"
    }

    # Copy core files
    copy_tracked "REASONER.md"          "$TARGET/REASONER.md"          "spec"
    copy_tracked "SKILL.md"             "$TARGET/SKILL.md"             "skill"
    copy_tracked "agent.md"             "$TARGET/agent.md"             "entry-point"
    copy_tracked "AGENTS.md"            "$TARGET/AGENTS.md"            "entry-point"
    copy_tracked "CLAUDE.md"            "$TARGET/CLAUDE.md"            "entry-point"
    copy_tracked "DESIGN-RATIONALE.md"  "$TARGET/DESIGN-RATIONALE.md"  "other"
    copy_tracked "README.md"            "$TARGET/README.md"            "other"

    # Copy skills
    copy_tracked "skills/framing/SKILL.md"        "$TARGET/skills/framing/SKILL.md"       "skill"
    copy_tracked "skills/deliberation/SKILL.md"   "$TARGET/skills/deliberation/SKILL.md"  "skill"
    copy_tracked "skills/verification/SKILL.md"   "$TARGET/skills/verification/SKILL.md"  "skill"

    # Copy templates
    copy_tracked "templates/verdict.md"                 "$TARGET/templates/verdict.md"                "template"
    copy_tracked "templates/trade-off-analysis.md"      "$TARGET/templates/trade-off-analysis.md"     "template"
    copy_tracked "templates/feasibility-assessment.md"  "$TARGET/templates/feasibility-assessment.md" "template"
    copy_tracked "templates/root-cause-analysis.md"     "$TARGET/templates/root-cause-analysis.md"    "template"
    copy_tracked "templates/conflict-resolution.md"     "$TARGET/templates/conflict-resolution.md"    "template"

    echo "✓ Core files installed to $TARGET"
    echo ""
  fi
fi

# ──────────────────────────────────────────────────────────
# Marker-aware shared-dispatch helper (EIIS v1.1 §4.1).
#
# Owns a marker-bounded region in a composable dispatch file (root
# AGENTS.md, CLAUDE.md, .github/copilot-instructions.md). On second run,
# the region is rewritten in place — output is byte-identical to the
# first run (§4.1.2, §5.2). Bare appends without markers (D-4) are
# explicitly avoided. Legacy non-marker FORGE content from v1.1.1 and
# earlier is left untouched: we only append a fresh marker-bounded
# block, leaving the consumer to manually clean up legacy lines if
# desired (the safer choice — see PR body).
# ──────────────────────────────────────────────────────────
upsert_eidolon_block() {
  # upsert_eidolon_block <dst> <content> <role>
  local dst="$1" content="$2" role="$3"
  local start="<!-- eidolon:${EIDOLON_NAME} start -->"
  local end="<!-- eidolon:${EIDOLON_NAME} end -->"

  if [[ "$DRY_RUN" == "true" ]]; then
    local action="append"
    if [[ -f "$dst" ]] && grep -qF "$start" "$dst" 2>/dev/null; then
      action="rewrite"
    fi
    echo "  [dry-run] ${action} eidolon:${EIDOLON_NAME} block in ${dst}"
    return
  fi

  mkdir -p "$(dirname "$dst")" 2>/dev/null || true

  # Legacy cleanup: convert any pre-existing symlink to a real file before
  # upserting (defensive — older FORGE installers did not symlink, but
  # consumers may have done so manually).
  if [[ -L "$dst" ]]; then
    rm -f "$dst"
  fi

  local content_file mode tmp
  content_file="$(mktemp)"
  printf '%s\n' "$content" > "$content_file"

  if [[ -f "$dst" ]] && grep -qF "$start" "$dst" 2>/dev/null; then
    mode="rewritten"
    tmp="$(mktemp)"
    awk -v start="$start" -v end="$end" -v cf="$content_file" '
      BEGIN { in_block = 0 }
      $0 == start {
        print start
        while ((getline line < cf) > 0) print line
        close(cf)
        in_block = 1
        next
      }
      $0 == end {
        print end
        in_block = 0
        next
      }
      !in_block { print }
    ' "$dst" > "$tmp"
    mv "$tmp" "$dst"
  elif [[ -f "$dst" ]]; then
    mode="appended"
    {
      printf '\n%s\n' "$start"
      cat "$content_file"
      printf '%s\n' "$end"
    } >> "$dst"
  else
    mode="created"
    {
      printf '%s\n' "$start"
      cat "$content_file"
      printf '%s\n' "$end"
    } > "$dst"
  fi

  rm -f "$content_file"
  record_file "$dst" "$role" "$mode"
}

# Shared-dispatch block content — identical body across AGENTS.md,
# CLAUDE.md, and .github/copilot-instructions.md so the marker rewrite
# stays idempotent regardless of which surface is being touched.
SHARED_BLOCK="## FORGE — Reasoner / structured deliberation (v${EIDOLON_VERSION})

Entry: \`${TARGET}/agent.md\`
Spec:  \`${TARGET}/REASONER.md\`
Cycle: F (Frame) → O (Observe) → R (Reason) → G (Gate) → E (Emit)

**P0 (non-negotiable):** reasoning-only (no tools, no mutations); frame first
(refuse vague questions); ≥3 hypotheses with adversarial stress-tests;
evidence-anchored claims (H/M/L tiers); bounded deliberation (≤3 passes +
1 REFORGE); reversal conditions mandatory.

See \`${TARGET}/AGENTS.md\` for full rules and the phase pipeline."

# ──────────────────────────────────────────────────────────
# Host detection and dispatch file writing
# ──────────────────────────────────────────────────────────

hosts_wired_arr=()

# write_per_host_dispatch <dst> <content> — overwrites unconditionally
# (--force semantics is the manifest-level idempotency gate; the file
# itself is owned by the Eidolon and rewritten byte-identically per §5.3).
write_per_host_dispatch() {
  local dst="$1" content="$2"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [dry-run] write ${dst}"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  printf '%s\n' "$content" > "$dst"
  record_file "$dst" "dispatch" "created"
}

wire_host() {
  local host="$1"
  case "$host" in
    claude-code)
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] Would write .claude/agents/${EIDOLON_NAME}.md"
        [[ "$SHARED_DISPATCH" == "true" ]] && echo "[dry-run] Would upsert eidolon:${EIDOLON_NAME} block in CLAUDE.md"
      else
        local CLAUDE_AGENT="---
name: ${EIDOLON_NAME}
description: Reasoner — structured deliberation for hard decisions via the FORGE cycle (Frame → Observe → Reason → Gate → Emit). Reasoning-only; refuses tools, exploration, and implementation.
tools: none
methodology: ${METHODOLOGY}
methodology_version: \"${EIDOLON_VERSION}\"
role: Reasoner — structured deliberation and decision intelligence
handoffs: [spectra, apivr, atlas, scribe]
---

# FORGE — Reasoner subagent

Execute the FORGE cycle (Frame → Observe → Reason → Gate → Emit). You are
**reasoning-only**: no tool calls, no file mutations, no exploration. If
asked to plan, implement, or scout, hand off.

Full rules: \`${TARGET}/AGENTS.md\`. Always-loaded profile: \`${TARGET}/agent.md\`.
Skills under \`${TARGET}/skills/<phase>/SKILL.md\` — load only the active phase."
        write_per_host_dispatch ".claude/agents/${EIDOLON_NAME}.md" "$CLAUDE_AGENT"
        if [[ "$SHARED_DISPATCH" == "true" ]]; then
          upsert_eidolon_block "CLAUDE.md" "$SHARED_BLOCK" "dispatch"
        fi
        echo "→ Claude Code: wired"
        hosts_wired_arr+=("claude-code")
      fi
      ;;
    copilot)
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] Would write .github/instructions/${EIDOLON_NAME}.instructions.md"
        [[ "$SHARED_DISPATCH" == "true" ]] && echo "[dry-run] Would upsert eidolon:${EIDOLON_NAME} block in .github/copilot-instructions.md"
      else
        local COPILOT_INSTR="---
applyTo: \"**\"
description: \"FORGE — structured deliberation for hard decisions\"
---

See \`${TARGET}/AGENTS.md\` for the full ruleset and phase pipeline.
Reasoning-only — refuses tools, planning, and implementation."
        write_per_host_dispatch ".github/instructions/${EIDOLON_NAME}.instructions.md" "$COPILOT_INSTR"
        if [[ "$SHARED_DISPATCH" == "true" ]]; then
          upsert_eidolon_block ".github/copilot-instructions.md" "$SHARED_BLOCK" "dispatch"
        fi
        echo "→ Copilot: wired"
        hosts_wired_arr+=("copilot")
      fi
      ;;
    cursor)
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] Would write .cursor/rules/${EIDOLON_NAME}.mdc"
      else
        local CURSOR_RULE="---
description: \"FORGE — structured deliberation for hard decisions\"
globs: \"**/*\"
alwaysApply: false
---

See \`${TARGET}/agent.md\` for the full Reasoner specification.
Invoke with: \"Reasoner, help me decide: ...\""
        write_per_host_dispatch ".cursor/rules/${EIDOLON_NAME}.mdc" "$CURSOR_RULE"
        echo "→ Cursor: wired"
        hosts_wired_arr+=("cursor")
      fi
      ;;
    opencode)
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] Would write .opencode/agents/${EIDOLON_NAME}.md"
      else
        local OC_AGENT="---
mode: primary
description: \"FORGE — structured deliberation for hard decisions\"
---

See \`${TARGET}/REASONER.md\` for full rules.
Reasoning-only — refuses tools, planning, and implementation."
        write_per_host_dispatch ".opencode/agents/${EIDOLON_NAME}.md" "$OC_AGENT"
        echo "→ OpenCode: wired"
        hosts_wired_arr+=("opencode")
      fi
      ;;
    codex)
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "[dry-run] Would write .codex/agents/${EIDOLON_NAME}.md"
      else
        # EIIS v1.1 §4.5 — Codex subagent file. Frontmatter contract:
        # required name (slug) + description; optional tools, model.
        # Source: https://developers.openai.com/codex/subagents
        local CODEX_AGENT="---
name: ${EIDOLON_NAME}
description: FORGE — structured deliberation subagent. Runs the Frame → Observe → Reason → Gate → Emit cycle for hard decisions (trade-offs, feasibility, root-cause, conflict resolution). Reasoning-only; refuses tools, exploration, and implementation. Hands off to SPECTRA, APIVR-Δ, ATLAS, or Scribe.
---

# ${METHODOLOGY} — Codex subagent

Execute the FORGE cycle: **F**rame → **O**bserve → **R**eason → **G**ate →
**E**mit. You are **reasoning-only** — no tool calls, no file mutations.
If the parent asks you to plan, implement, scout, or document, request a
hand-off to the appropriate Eidolon (SPECTRA, APIVR-Δ, ATLAS, Scribe).

Canonical methodology entry: \`${TARGET}/agent.md\`.
Full ruleset: \`${TARGET}/AGENTS.md\`.
Phase skills: \`${TARGET}/skills/<phase>/SKILL.md\` — load only the active phase."
        write_per_host_dispatch ".codex/agents/${EIDOLON_NAME}.md" "$CODEX_AGENT"
        echo "→ Codex: wired"
        hosts_wired_arr+=("codex")
      fi
      ;;
  esac
}

if [[ "$HOSTS" != "none" ]]; then
  IFS=',' read -ra HOST_LIST <<< "$HOSTS"
  for h in "${HOST_LIST[@]}"; do
    h="${h// /}"
    case "$h" in
      ""|raw|none) continue ;;
    esac
    wire_host "$h"
  done
fi

# EIIS v1.1 §4.1.0 — root AGENTS.md is co-owned by `copilot` and `codex`.
# Compose the marker-bounded block when --shared-dispatch is set, OR when
# `codex` is wired (regardless of --shared-dispatch — Codex's primary
# instruction surface). The same block content keeps the rewrite path
# byte-identical between runs (§4.1.2).
codex_in_hosts=false
for h in "${hosts_wired_arr[@]}"; do
  [[ "$h" == "codex" ]] && codex_in_hosts=true
done

if [[ "$MANIFEST_ONLY" != "true" ]] && \
   { [[ "$SHARED_DISPATCH" == "true" ]] || [[ "$codex_in_hosts" == "true" ]]; }; then
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [dry-run] upsert eidolon:${EIDOLON_NAME} block in AGENTS.md"
  else
    upsert_eidolon_block "AGENTS.md" "$SHARED_BLOCK" "dispatch"
    if [[ "$SHARED_DISPATCH" != "true" && "$codex_in_hosts" == "true" ]]; then
      echo "  Note: AGENTS.md written for codex co-ownership (EIIS v1.1 §4.1.0)" >&2
    fi
  fi
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

# EIIS v1.1 §3.3 / §3.4 — files_written populated array. Empty `[]` is a
# violation under v1.0 (warn-only) and v1.2 (hard-fail). FORGE accumulates
# entries via record_file as each path is written.
FILES_JSON=""
if [[ ${#FILES_WRITTEN[@]} -gt 0 ]]; then
  FILES_JSON="$(printf '%s,' "${FILES_WRITTEN[@]}" | sed 's/,$//')"
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
  "files_written": [${FILES_JSON}],
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
