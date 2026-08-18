#!/usr/bin/env bats
# tests/ecl-v2-adoption.bats — Wave-3 ECL v2.0 adoption sweep
#
# Covers: the vendored v2 envelope schema shape, ISE (Intent, Source,
# Entitlement) block presence + grade correctness on the outbound
# reasoning-report envelope template, the requires_checker checker-handoff
# gate (schema + templates + new skill), the self-consistency weak-host
# trigger, install.sh wiring for the new artefacts, version stamps, and
# drift-kill greps (no stray "ECL v1.0" prose left behind by the sweep).

load helpers.bash

# ─────────────────────────────────────────────────────────────────────────────
# v2 envelope schema — shape
# ─────────────────────────────────────────────────────────────────────────────

@test "v2: schemas/ecl-envelope.v2.json exists and is valid JSON" {
  [ -f "${REPO_ROOT}/schemas/ecl-envelope.v2.json" ]
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq empty "${REPO_ROOT}/schemas/ecl-envelope.v2.json"
  [ "$status" -eq 0 ]
}

@test "v2: schemas/ecl-envelope.v1.json is RETAINED (not removed by the sweep)" {
  [ -f "${REPO_ROOT}/schemas/ecl-envelope.v1.json" ]
}

@test "v2: envelope_version pattern accepts 2.0" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.properties.envelope_version.pattern' "${REPO_ROOT}/schemas/ecl-envelope.v2.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"2"* ]]
}

@test "v2: schema declares an ise \$defs block with assertion_grade required" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.["$defs"].ise.required[0]' "${REPO_ROOT}/schemas/ecl-envelope.v2.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "assertion_grade" ]]
}

@test "v2: ise.assertion_grade enum has the four ECL v2.0 §6.5.2 values" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.["$defs"].ise.properties.assertion_grade.enum[]' "${REPO_ROOT}/schemas/ecl-envelope.v2.json"
  [ "$status" -eq 0 ]
  [[ "$output" == *"unverified"* ]]
  [[ "$output" == *"self-attested"* ]]
  [[ "$output" == *"validated"* ]]
  [[ "$output" == *"human-reviewed"* ]]
}

@test "v2: top-level ise property refs the \$defs/ise block" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.properties.ise["$ref"]' "${REPO_ROOT}/schemas/ecl-envelope.v2.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "#/\$defs/ise" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# install.sh wiring — v2 schema + checker-handoff skill
# ─────────────────────────────────────────────────────────────────────────────








# ─────────────────────────────────────────────────────────────────────────────
# ISE block — outbound reasoning-report envelope template
# ─────────────────────────────────────────────────────────────────────────────

@test "ise: schemas/reasoning-report.envelope.json declares envelope_version 2.0" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.envelope_version' "${REPO_ROOT}/schemas/reasoning-report.envelope.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "2.0" ]]
}

@test "ise: schemas/reasoning-report.envelope.json ise.assertion_grade is self-attested" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.ise.assertion_grade' "${REPO_ROOT}/schemas/reasoning-report.envelope.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "self-attested" ]]
}

@test "ise: schemas/reasoning-report.envelope.json receiver_authorization matches the declared defaults" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.ise.receiver_authorization.auto_route' "${REPO_ROOT}/schemas/reasoning-report.envelope.json"
  [[ "$output" == "true" ]]
  run jq -r '.ise.receiver_authorization.auto_merge' "${REPO_ROOT}/schemas/reasoning-report.envelope.json"
  [[ "$output" == "false" ]]
  run jq -r '.ise.receiver_authorization.auto_deploy' "${REPO_ROOT}/schemas/reasoning-report.envelope.json"
  [[ "$output" == "false" ]]
}

@test "ise: schemas/reasoning-report.envelope.json provenance.methodology_version is well-formed" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.ise.provenance.methodology_version' "${REPO_ROOT}/schemas/reasoning-report.envelope.json"
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^forge-[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "ise: justification for self-attested grade is documented in skills/verification/SKILL.md" {
  grep -qi 'self-attested' "${REPO_ROOT}/skills/verification/SKILL.md"
  grep -qi 'self-review' "${REPO_ROOT}/skills/verification/SKILL.md"
}

# ─────────────────────────────────────────────────────────────────────────────
# requires_checker — profile schema + templates + new skill
# ─────────────────────────────────────────────────────────────────────────────

@test "requires_checker: present in schemas/reasoning-report-profile.v1.json with default false" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run jq -r '.allOf[1].properties.requires_checker.type' "${REPO_ROOT}/schemas/reasoning-report-profile.v1.json"
  [ "$status" -eq 0 ]
  [[ "$output" == "boolean" ]]
  run jq -r '.allOf[1].properties.requires_checker.default' "${REPO_ROOT}/schemas/reasoning-report-profile.v1.json"
  [[ "$output" == "false" ]]
}

@test "requires_checker: present in all five body templates' frontmatter" {
  for f in verdict trade-off-analysis feasibility-assessment root-cause-analysis conflict-resolution; do
    grep -q 'requires_checker: false' "${REPO_ROOT}/templates/${f}.md"
  done
}

@test "checker-handoff: skills/checker-handoff/SKILL.md exists with canonical frontmatter" {
  [ -f "${REPO_ROOT}/skills/checker-handoff/SKILL.md" ]
  local first_line
  first_line="$(head -1 "${REPO_ROOT}/skills/checker-handoff/SKILL.md")"
  [[ "$first_line" == "---" ]]
  grep -q '^name: forge-checker-handoff' "${REPO_ROOT}/skills/checker-handoff/SKILL.md"
  grep -qE '^description: .+' "${REPO_ROOT}/skills/checker-handoff/SKILL.md"
}

@test "checker-handoff: skill enumerates the five irreversibility trigger categories" {
  grep -qi 'deploy' "${REPO_ROOT}/skills/checker-handoff/SKILL.md"
  grep -qi 'destructive migration' "${REPO_ROOT}/skills/checker-handoff/SKILL.md"
  grep -qi 'security-boundary' "${REPO_ROOT}/skills/checker-handoff/SKILL.md"
  grep -qi 'external spend' "${REPO_ROOT}/skills/checker-handoff/SKILL.md"
  grep -qi 'public communication' "${REPO_ROOT}/skills/checker-handoff/SKILL.md"
}

@test "checker-handoff: skill declares maker != checker and stays tool-less" {
  grep -qi 'maker' "${REPO_ROOT}/skills/checker-handoff/SKILL.md"
  grep -qi 'checker' "${REPO_ROOT}/skills/checker-handoff/SKILL.md"
  grep -qi 'tool-less' "${REPO_ROOT}/skills/checker-handoff/SKILL.md"
}

@test "checker-handoff: PERSONA.md P0 rules reference the hop without renumbering 1-8" {
  grep -q '^8\. \*\*Scope discipline\.\*\*' "${REPO_ROOT}/PERSONA.md"
  grep -q '^9\. \*\*Checker handoff' "${REPO_ROOT}/PERSONA.md"
  grep -q 'requires_checker' "${REPO_ROOT}/PERSONA.md"
}

@test "checker-handoff: PERSONA.md token budget gate still passes with the new P0 line" {
  run_install --non-interactive --force
  [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Weak-host self-consistency trigger (additive, roster degraded_mode data)
# ─────────────────────────────────────────────────────────────────────────────

@test "degraded-mode: skills/self-consistency/SKILL.md references roster degraded_mode: sample-select" {
  grep -q 'degraded_mode: sample-select' "${REPO_ROOT}/skills/self-consistency/SKILL.md"
}

@test "degraded-mode: skills/self-consistency/SKILL.md references routing.yaml and self-red-teaming replacement" {
  grep -q 'routing.yaml' "${REPO_ROOT}/skills/self-consistency/SKILL.md"
  grep -qi 'self-red-team' "${REPO_ROOT}/skills/self-consistency/SKILL.md"
}

@test "degraded-mode: self-consistency.md existing Deep+stakes and opt-in gates are unchanged (additive-only amendment)" {
  grep -q 'Deep depth' "${REPO_ROOT}/skills/self-consistency/SKILL.md"
  grep -q 'Explicit opt-in' "${REPO_ROOT}/skills/self-consistency/SKILL.md"
  grep -q 'N=3' "${REPO_ROOT}/skills/self-consistency/SKILL.md"
  grep -q 'N=5' "${REPO_ROOT}/skills/self-consistency/SKILL.md"
}

# ─────────────────────────────────────────────────────────────────────────────
# Drift-kill: no stray "ECL v1.0" prose left in documentation
# ─────────────────────────────────────────────────────────────────────────────


@test "drift: SPEC.md targets ECL v2.0, not v1.0" {
  grep -q 'ECL v2.0' "${REPO_ROOT}/SPEC.md"
  run grep -c 'ECL v1\.0' "${REPO_ROOT}/SPEC.md"
  [[ "$output" == "0" ]]
}

@test "drift: skills/verification/SKILL.md envelope checklist header is ECL v2.0" {
  grep -q 'Envelope Construction Checklist (ECL v2.0' "${REPO_ROOT}/skills/verification/SKILL.md"
  run grep -c 'ECL v1\.0' "${REPO_ROOT}/skills/verification/SKILL.md"
  [[ "$output" == "0" ]]
}

@test "drift: skills/verification/SKILL.md envelope template path points at schemas/, not the stale templates/ path" {
  grep -q 'schemas/reasoning-report.envelope.json' "${REPO_ROOT}/skills/verification/SKILL.md"
  run grep -c 'templates/reasoning-report.envelope.json' "${REPO_ROOT}/skills/verification/SKILL.md"
  [[ "$output" == "0" ]]
}



# ─────────────────────────────────────────────────────────────────────────────
# Version stamp — 5 canonical homes at 1.10.0
# ─────────────────────────────────────────────────────────────────────────────
