#!/usr/bin/env sh

set -u

MAX_ITERATIONS="${MAX_ITERATIONS:-3}"
TEST_COMMAND="${TEST_COMMAND:-python -m unittest discover -s tests -q}"
TEST_TIMEOUT_SECONDS="${TEST_TIMEOUT_SECONDS:-30}"
CODEX_COMMAND="${CODEX_COMMAND:-codex exec --prompt-file PROMPT.md}"
AGENTS_FILE="${AGENTS_FILE:-AGENTS.md}"
TEST_OUTPUT_FILE="${TEST_OUTPUT_FILE:-.harness-test-output.log}"
CODEX_OUTPUT_FILE="${CODEX_OUTPUT_FILE:-.harness-codex-output.log}"
LOOP_LOG_FILE="${LOOP_LOG_FILE:-loop_log.txt}"
LAST_FAILURE_REASON=""

init_log() {
  touch "${LOOP_LOG_FILE}"
  exec >> "${LOOP_LOG_FILE}" 2>&1
  echo "===== Ralph loop started at $(date -u +"%Y-%m-%dT%H:%M:%SZ") ====="
}

run_codex() {
  echo "[loop] Running Codex command: ${CODEX_COMMAND}"
  sh -c "${CODEX_COMMAND}" >"${CODEX_OUTPUT_FILE}" 2>&1
  codex_status=$?
  cat "${CODEX_OUTPUT_FILE}"

  if [ "${codex_status}" -ne 0 ]; then
    LAST_FAILURE_REASON="Codex execution failed before code synthesis completed."
    return "${codex_status}"
  fi

  return 0
}

run_tests() {
  echo "[loop] Running tests with backpressure command: ${TEST_COMMAND}"

  if command -v timeout >/dev/null 2>&1; then
    timeout "${TEST_TIMEOUT_SECONDS}" sh -c "${TEST_COMMAND}" >"${TEST_OUTPUT_FILE}" 2>&1
    test_status=$?
  else
    sh -c "${TEST_COMMAND}" >"${TEST_OUTPUT_FILE}" 2>&1
    test_status=$?
  fi

  cat "${TEST_OUTPUT_FILE}"
  return "${test_status}"
}

classify_failure_reason() {
  if [ ! -f "${TEST_OUTPUT_FILE}" ]; then
    echo "Test output was not captured, so the exact code failure could not be classified."
    return 0
  fi

  if grep -qi "ZeroDivisionError" "${TEST_OUTPUT_FILE}"; then
    echo "Zero-division handling is missing or incorrect in divide()."
    return 0
  fi

  if grep -qi "TypeError" "${TEST_OUTPUT_FILE}"; then
    echo "A type-related error occurred during calculator execution."
    return 0
  fi

  if grep -qi "AssertionError" "${TEST_OUTPUT_FILE}"; then
    echo "The calculator logic returned an unexpected value for one of the required operations."
    return 0
  fi

  if grep -qi "ImportError" "${TEST_OUTPUT_FILE}" || grep -qi "ModuleNotFoundError" "${TEST_OUTPUT_FILE}"; then
    echo "The calculator module or one of the required functions could not be imported."
    return 0
  fi

  if grep -qi "AttributeError" "${TEST_OUTPUT_FILE}"; then
    echo "A required calculator function is missing or exposed under the wrong name."
    return 0
  fi

  if grep -qi "SyntaxError" "${TEST_OUTPUT_FILE}"; then
    echo "The generated Python code contains a syntax error."
    return 0
  fi

  awk 'NF { line=$0 } END { print line }' "${TEST_OUTPUT_FILE}"
}

record_failure() {
  reason="$1"
  cat >> "${AGENTS_FILE}" <<EOF

## Failure Pattern
- Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- Code Cause: ${reason}
EOF
}

record_success() {
  cat >> "${AGENTS_FILE}" <<EOF

## Success Pattern
- Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- Pattern: Sequentially implementing one typed function at a time kept the unittest suite stable and preserved explicit zero-division behavior.
EOF
}

commit_success() {
  iteration="$1"

  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git add calculator.py tests/test_calculator.py AGENTS.md PROMPT.md README.md harness.sh loop_log.txt
    if git diff --cached --quiet; then
      git commit --allow-empty -m "Ralph loop iteration ${iteration}: passing tests"
    else
      git commit -m "Ralph loop iteration ${iteration}: passing tests"
    fi
  else
    echo "[loop] Skipping commit because this directory is not a Git repository."
  fi
}

recover_workspace() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git checkout .
  else
    echo "[loop] Skipping git checkout . recovery because this directory is not a Git repository."
  fi
}

main() {
  init_log
  iteration=1

  while [ "${iteration}" -le "${MAX_ITERATIONS}" ]; do
    echo
    echo "===== Iteration ${iteration}/${MAX_ITERATIONS} ====="
    echo "[loop] Iteration ${iteration}/${MAX_ITERATIONS} started at $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    if ! run_codex; then
      echo "[loop] Codex step failed."
      record_failure "${LAST_FAILURE_REASON}"
      recover_workspace
      echo "[loop] Iteration ${iteration}/${MAX_ITERATIONS} finished with recovery at $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
      iteration=$((iteration + 1))
      continue
    fi

    if run_tests; then
      echo "[loop] Tests passed."
      record_success
      commit_success "${iteration}"
      echo "[loop] Commit step completed."
      echo "[loop] Iteration ${iteration}/${MAX_ITERATIONS} finished successfully at $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
      echo "===== Ralph loop finished at $(date -u +"%Y-%m-%dT%H:%M:%SZ") ====="
      exit 0
    else
      LAST_FAILURE_REASON="$(classify_failure_reason)"
      echo "[loop] Tests failed."
      record_failure "${LAST_FAILURE_REASON}"
      recover_workspace
      echo "[loop] Iteration ${iteration}/${MAX_ITERATIONS} finished with recovery at $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    fi

    iteration=$((iteration + 1))
  done

  echo "===== Ralph loop finished at $(date -u +"%Y-%m-%dT%H:%M:%SZ") ====="
  exit 1
}

main "$@"
