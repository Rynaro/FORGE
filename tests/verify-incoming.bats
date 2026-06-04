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

@test "skills/verify-incoming.md exists in the repo" {
  [ -f "${REPO_ROOT}/skills/verify-incoming.md" ]
}

@test "skill declares BLOCKING posture (REFUSE / SHALL NOT / blocking)" {
  grep -qE 'REFUSE|SHALL NOT|blocking' "${REPO_ROOT}/skills/verify-incoming.md"
}

@test "skill does NOT declare warn-only as current posture (payload always processed)" {
  # Negative assertion: catches regressions back to the old opt-in warn-only gate.
  # The skill documents "BLOCKING, not warn-only" and may contrast with history.
  # Fail only if it affirmatively states the payload is ALWAYS processed (never
  # blocked), or states "posture: warn-only" as the current configuration.
  # "Blocking, not warn-only" and "warn-only" in historical blockquotes are fine.
  if grep -qiE 'payload is always processed|artefact is always processed' \
      "${REPO_ROOT}/skills/verify-incoming.md"; then
    echo "FAIL: skill says payload/artefact is always processed" >&3
    false
  fi
  # Must not process the payload after a mismatch outside a superseded note.
  if grep -v '^>' "${REPO_ROOT}/skills/verify-incoming.md" | \
      grep -qiE 'process.*(payload|artefact).*(anyway|regardless)'; then
    echo "FAIL: skill says payload is processed anyway on failure" >&3
    false
  fi
}

@test "skill references ECL section 6.2.2" {
  grep -q 'ECL.*6\.2\.2\|6\.2\.2.*ECL' "${REPO_ROOT}/skills/verify-incoming.md"
}

@test "skill documents verify_pass and verify_fail trace events" {
  grep -q 'verify_pass' "${REPO_ROOT}/skills/verify-incoming.md"
  grep -q 'verify_fail' "${REPO_ROOT}/skills/verify-incoming.md"
}

@test "skill opens with a heading (no YAML frontmatter)" {
  local first_non_blank
  first_non_blank="$(grep -v '^[[:space:]]*$' "${REPO_ROOT}/skills/verify-incoming.md" | head -1)"
  [[ "$first_non_blank" == "# "* ]]
}

# ── install.sh registration ──────────────────────────────────────────────────

@test "install.sh copy-loop includes verify-incoming" {
  grep -q 'verify-incoming' "${REPO_ROOT}/install.sh"
}

@test "install.sh wire_skill calls include verify-incoming" {
  grep -q 'wire_skill "verify-incoming"' "${REPO_ROOT}/install.sh"
}

@test "install.sh build_skills_json loop includes verify-incoming" {
  grep -qE 'for skill in.*verify-incoming' "${REPO_ROOT}/install.sh"
}

# ── install run: exit 0 + artefact presence ──────────────────────────────────

@test "install.sh exits 0 with --non-interactive --force" {
  run_install --non-interactive --force
  [ "$status" -eq 0 ]
}

@test "install produces skills/verify-incoming.md in the target" {
  run_install --non-interactive --force
  [ "$status" -eq 0 ]
  [ -f "${INSTALL_TARGET}/skills/verify-incoming.md" ]
}

@test "install manifest records verify-incoming skill" {
  run_install --non-interactive --force
  [ "$status" -eq 0 ]
  local manifest="${INSTALL_TARGET}/install.manifest.json"
  [ -f "${manifest}" ]
  grep -q 'verify-incoming' "${manifest}"
}

@test "install manifest lists verify-incoming with a non-zero sha256" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run_install --non-interactive --force
  [ "$status" -eq 0 ]
  local manifest="${INSTALL_TARGET}/install.manifest.json"
  local sha
  sha="$(jq -r '.skills[] | select(.name == "verify-incoming") | .source_sha256' "${manifest}")"
  [ -n "${sha}" ]
  [[ "${sha}" != "0000000000000000000000000000000000000000000000000000000000000000" ]]
}

# ── vendor copy (claude-code host) ───────────────────────────────────────────

@test "install wires .claude/skills/forge-verify-incoming/SKILL.md for claude-code host" {
  run_install --non-interactive --force
  [ "$status" -eq 0 ]
  [ -f "${TEST_PROJECT}/.claude/skills/forge-verify-incoming/SKILL.md" ]
}

@test "vendor SKILL.md content matches installed skills/verify-incoming.md" {
  run_install --non-interactive --force
  [ "$status" -eq 0 ]
  local vendor="${TEST_PROJECT}/.claude/skills/forge-verify-incoming/SKILL.md"
  local src="${INSTALL_TARGET}/skills/verify-incoming.md"
  [ -f "${vendor}" ]
  [ -f "${src}" ]
  diff -q "${vendor}" "${src}" >/dev/null
}

# ── agent.md token budget gate ───────────────────────────────────────────────

@test "agent.md token budget gate passes (exit 0, not exit 4) with verify-incoming added" {
  run_install --non-interactive --force
  # install.sh exits 4 when agent.md > 1000 tokens in --non-interactive mode.
  # exit 0 confirms the budget gate passed after adding verify-incoming.
  [ "$status" -eq 0 ]
}
