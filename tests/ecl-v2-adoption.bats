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

@test "v2: install.sh copies schemas/ecl-envelope.v2.json" {
  grep -q 'schemas/ecl-envelope.v2.json' "${REPO_ROOT}/install.sh"
}

@test "v2: install.sh wire_skill calls include checker-handoff" {
  grep -q 'wire_skill "checker-handoff"' "${REPO_ROOT}/install.sh"
}

@test "v2: install.sh build_skills_json loop includes checker-handoff" {
  grep -qE 'for skill in.*checker-handoff' "${REPO_ROOT}/install.sh"
}

@test "v2: install produces both ecl-envelope.v1.json and v2.json in target" {
  run_install --non-interactive --force
  [ "$status" -eq 0 ]
  [ -f "${INSTALL_TARGET}/schemas/ecl-envelope.v1.json" ]
  [ -f "${INSTALL_TARGET}/schemas/ecl-envelope.v2.json" ]
}

@test "v2: install produces skills/checker-handoff.md in the target" {
  run_install --non-interactive --force
  [ "$status" -eq 0 ]
  [ -f "${INSTALL_TARGET}/skills/checker-handoff.md" ]
}

@test "v2: install wires .claude/skills/forge-checker-handoff/SKILL.md for claude-code host" {
  run_install --non-interactive --force
  [ "$status" -eq 0 ]
  [ -f "${TEST_PROJECT}/.claude/skills/forge-checker-handoff/SKILL.md" ]
}

@test "v2: install manifest records checker-handoff skill" {
  run_install --non-interactive --force
  [ "$status" -eq 0 ]
  grep -q 'checker-handoff' "${INSTALL_TARGET}/install.manifest.json"
}

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

@test "ise: justification for self-attested grade is documented in skills/verification.md" {
  grep -qi 'self-attested' "${REPO_ROOT}/skills/verification.md"
  grep -qi 'self-review' "${REPO_ROOT}/skills/verification.md"
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

@test "checker-handoff: skills/checker-handoff.md exists with canonical frontmatter" {
  [ -f "${REPO_ROOT}/skills/checker-handoff.md" ]
  local first_line
  first_line="$(head -1 "${REPO_ROOT}/skills/checker-handoff.md")"
  [[ "$first_line" == "---" ]]
  grep -q '^name: forge-checker-handoff' "${REPO_ROOT}/skills/checker-handoff.md"
  grep -qE '^description: .+' "${REPO_ROOT}/skills/checker-handoff.md"
}

@test "checker-handoff: skill enumerates the five irreversibility trigger categories" {
  grep -qi 'deploy' "${REPO_ROOT}/skills/checker-handoff.md"
  grep -qi 'destructive migration' "${REPO_ROOT}/skills/checker-handoff.md"
  grep -qi 'security-boundary' "${REPO_ROOT}/skills/checker-handoff.md"
  grep -qi 'external spend' "${REPO_ROOT}/skills/checker-handoff.md"
  grep -qi 'public communication' "${REPO_ROOT}/skills/checker-handoff.md"
}

@test "checker-handoff: skill declares maker != checker and stays tool-less" {
  grep -qi 'maker' "${REPO_ROOT}/skills/checker-handoff.md"
  grep -qi 'checker' "${REPO_ROOT}/skills/checker-handoff.md"
  grep -qi 'tool-less' "${REPO_ROOT}/skills/checker-handoff.md"
}

@test "checker-handoff: agent.md P0 rules reference the hop without renumbering 1-8" {
  grep -q '^8\. \*\*Scope discipline\.\*\*' "${REPO_ROOT}/agent.md"
  grep -q '^9\. \*\*Checker handoff' "${REPO_ROOT}/agent.md"
  grep -q 'requires_checker' "${REPO_ROOT}/agent.md"
}

@test "checker-handoff: agent.md token budget gate still passes with the new P0 line" {
  run_install --non-interactive --force
  [ "$status" -eq 0 ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Weak-host self-consistency trigger (additive, roster degraded_mode data)
# ─────────────────────────────────────────────────────────────────────────────

@test "degraded-mode: skills/self-consistency.md references roster degraded_mode: sample-select" {
  grep -q 'degraded_mode: sample-select' "${REPO_ROOT}/skills/self-consistency.md"
}

@test "degraded-mode: skills/self-consistency.md references routing.yaml and self-red-teaming replacement" {
  grep -q 'routing.yaml' "${REPO_ROOT}/skills/self-consistency.md"
  grep -qi 'self-red-team' "${REPO_ROOT}/skills/self-consistency.md"
}

@test "degraded-mode: self-consistency.md existing Deep+stakes and opt-in gates are unchanged (additive-only amendment)" {
  grep -q 'Deep depth' "${REPO_ROOT}/skills/self-consistency.md"
  grep -q 'Explicit opt-in' "${REPO_ROOT}/skills/self-consistency.md"
  grep -q 'N=3' "${REPO_ROOT}/skills/self-consistency.md"
  grep -q 'N=5' "${REPO_ROOT}/skills/self-consistency.md"
}

# ─────────────────────────────────────────────────────────────────────────────
# Drift-kill: no stray "ECL v1.0" prose left in documentation
# ─────────────────────────────────────────────────────────────────────────────

@test "drift: AGENTS.md targets ECL v2.0, not v1.0" {
  grep -q 'ECL v2.0' "${REPO_ROOT}/AGENTS.md"
  run grep -c 'ECL v1\.0' "${REPO_ROOT}/AGENTS.md"
  [[ "$output" == "0" ]]
}

@test "drift: SPEC.md targets ECL v2.0, not v1.0" {
  grep -q 'ECL v2.0' "${REPO_ROOT}/SPEC.md"
  run grep -c 'ECL v1\.0' "${REPO_ROOT}/SPEC.md"
  [[ "$output" == "0" ]]
}

@test "drift: skills/verification.md envelope checklist header is ECL v2.0" {
  grep -q 'Envelope Construction Checklist (ECL v2.0' "${REPO_ROOT}/skills/verification.md"
  run grep -c 'ECL v1\.0' "${REPO_ROOT}/skills/verification.md"
  [[ "$output" == "0" ]]
}

@test "drift: skills/verification.md envelope template path points at schemas/, not the stale templates/ path" {
  grep -q 'schemas/reasoning-report.envelope.json' "${REPO_ROOT}/skills/verification.md"
  run grep -c 'templates/reasoning-report.envelope.json' "${REPO_ROOT}/skills/verification.md"
  [[ "$output" == "0" ]]
}

@test "drift: ECL_VERSION file is 2.0 (source install.sh reads from)" {
  [[ "$(cat "${REPO_ROOT}/ECL_VERSION")" == "2.0" ]]
}

@test "drift: install manifest ecl.envelope_version reflects the ECL_VERSION file at install time" {
  if ! command -v jq &>/dev/null; then
    skip "jq not available"
  fi
  run_install --non-interactive --force
  [ "$status" -eq 0 ]
  run jq -r '.ecl.envelope_version' "${INSTALL_TARGET}/install.manifest.json"
  [[ "$output" == "2.0" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Version stamp — 5 canonical homes at 1.10.0
# ─────────────────────────────────────────────────────────────────────────────

@test "stamp: install.sh, agent.md, AGENTS.md, SPEC.md, README.md agree on 1.10.0" {
  grep -q 'EIDOLON_VERSION="1.10.0"' "${REPO_ROOT}/install.sh"
  grep -q 'methodology_version: "1.10.0"' "${REPO_ROOT}/agent.md"
  grep -q 'version: 1.10.0' "${REPO_ROOT}/AGENTS.md"
  grep -q 'methodology_version: 1.10.0' "${REPO_ROOT}/AGENTS.md"
  grep -q 'version: 1.10.0' "${REPO_ROOT}/SPEC.md"
  grep -q '\*\*Version:\*\* 1.10.0' "${REPO_ROOT}/README.md"
}

@test "stamp: CHANGELOG.md has a 1.10.0 entry" {
  grep -q '## \[1.10.0\]' "${REPO_ROOT}/CHANGELOG.md"
}
