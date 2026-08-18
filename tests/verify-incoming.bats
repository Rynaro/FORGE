#!/usr/bin/env bats
# tests/verify-incoming.bats — FORGE verify-incoming skill (blocking, symmetric)
#
# Tests the verify-incoming skill and its install registration.
# Note: FORGE is the tool-less Reasoner — no Bash execution at runtime.
# These tests validate the skill content posture and install artefacts only.
#
# All install runs use --hosts claude-code (via run_install helper default).
# The helpers setup() seeds CLAUDE.md so detect_hosts resolves correctly.

load helpers.bash

# ── Skill file content ───────────────────────────────────────────────────────

@test "skills/verify-incoming/SKILL.md exists in the repo" {
  [ -f "${REPO_ROOT}/skills/verify-incoming/SKILL.md" ]
}

@test "skill declares BLOCKING posture (REFUSE / SHALL NOT / blocking)" {
  grep -qE 'REFUSE|SHALL NOT|blocking' "${REPO_ROOT}/skills/verify-incoming/SKILL.md"
}

@test "skill does NOT declare warn-only as current posture (payload always processed)" {
  # Negative assertion: catches regressions back to the old opt-in warn-only gate.
  # The skill documents "BLOCKING, not warn-only" and may contrast with history.
  # Fail only if it affirmatively states the payload is ALWAYS processed (never
  # blocked), or states "posture: warn-only" as the current configuration.
  # "Blocking, not warn-only" and "warn-only" in historical blockquotes are fine.
  if grep -qiE 'payload is always processed|artefact is always processed' \
      "${REPO_ROOT}/skills/verify-incoming/SKILL.md"; then
    echo "FAIL: skill says payload/artefact is always processed" >&3
    false
  fi
  # Must not process the payload after a mismatch outside a superseded note.
  if grep -v '^>' "${REPO_ROOT}/skills/verify-incoming/SKILL.md" | \
      grep -qiE 'process.*(payload|artefact).*(anyway|regardless)'; then
    echo "FAIL: skill says payload is processed anyway on failure" >&3
    false
  fi
}

@test "skill references ECL section 6.2.2" {
  grep -q 'ECL.*6\.2\.2\|6\.2\.2.*ECL' "${REPO_ROOT}/skills/verify-incoming/SKILL.md"
}

@test "skill documents verify_pass and verify_fail trace events" {
  grep -q 'verify_pass' "${REPO_ROOT}/skills/verify-incoming/SKILL.md"
  grep -q 'verify_fail' "${REPO_ROOT}/skills/verify-incoming/SKILL.md"
}

@test "skill has canonical YAML frontmatter with non-empty name and description" {
  # D2 migration: all skills now carry canonical frontmatter.
  # Assert the file starts with '---', and that name and description are present
  # with non-empty values.
  local first_line
  first_line="$(head -1 "${REPO_ROOT}/skills/verify-incoming/SKILL.md")"
  [[ "$first_line" == "---" ]]
  grep -q '^name: forge-verify-incoming' "${REPO_ROOT}/skills/verify-incoming/SKILL.md"
  grep -qE '^description: .+' "${REPO_ROOT}/skills/verify-incoming/SKILL.md"
}

# ── install.sh registration ──────────────────────────────────────────────────




# ── install run: exit 0 + artefact presence ──────────────────────────────────





# ── vendor copy (claude-code host) ───────────────────────────────────────────



# ── PERSONA.md token budget gate ───────────────────────────────────────────────

@test "PERSONA.md token budget gate passes (exit 0, not exit 4) with verify-incoming added" {
  run_install --non-interactive --force
  # install.sh exits 4 when PERSONA.md > 1000 tokens in --non-interactive mode.
  # exit 0 confirms the budget gate passed after adding verify-incoming.
  [ "$status" -eq 0 ]
}
