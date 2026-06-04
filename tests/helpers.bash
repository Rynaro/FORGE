#!/usr/bin/env bash
# tests/helpers.bash — shared test helpers for FORGE bats suite.
#
# Provides minimal fixture helpers for install.sh-based tests.
# Bash 3.2 compatible: no associative arrays, no ${var,,}, no readarray.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT

# setup — called by bats before each test. Establishes a fresh consumer-project
# directory in BATS_TEST_TMPDIR so each test runs in isolation.
# Seeds CLAUDE.md so detect_hosts resolves to claude-code; this avoids the
# set -u / empty-array expansion that fires when --hosts none is passed to
# a bash 3.2-compatible install.sh.
setup() {
  TEST_PROJECT="${BATS_TEST_TMPDIR}/project"
  mkdir -p "${TEST_PROJECT}"
  cd "${TEST_PROJECT}"
  # Seed the claude-code host marker.
  touch "${TEST_PROJECT}/CLAUDE.md"
}

# teardown — return to repo root after each test.
teardown() {
  cd "${REPO_ROOT}"
}

# run_install [ARGS...] — invoke install.sh with --hosts claude-code, targeting
# a temp dir under the current TEST_PROJECT. Sets INSTALL_TARGET.
# We use --hosts claude-code explicitly (not --hosts none) so the
# hosts_wired_arr is populated and the set -u guard in the codex-ownership
# block does not fire on an empty array.
run_install() {
  INSTALL_TARGET="${TEST_PROJECT}/.eidolons/forge"
  run bash "${REPO_ROOT}/install.sh" \
    --target "${INSTALL_TARGET}" \
    --hosts claude-code \
    "$@"
}

# sha256_of <path> — portable SHA-256 helper.
sha256_of() {
  local f="$1"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$f" | awk '{print $1}'
  else
    echo "0000000000000000000000000000000000000000000000000000000000000000"
  fi
}
