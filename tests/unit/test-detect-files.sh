#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0

source "$PROJECT_ROOT/scripts/detect-files.sh"

assert_eq() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-}"
    if [ "$expected" = "$actual" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "FAIL: $msg (expected: '$expected', actual: '$actual')"
    fi
}

assert_success() {
    if [ "$1" -eq 0 ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "FAIL: $2 (expected success, got exit code $1)"
    fi
}

assert_failure() {
    if [ "$1" -ne 0 ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "FAIL: $2 (expected failure, got success)"
    fi
}

echo "=== Testing detect-files.sh ==="

# Test 1: python files detected
should_run_linter "flake8" "src/main.py
README.md
test.sh" && rc=0 || rc=$?
assert_success "$rc" "flake8 should run on .py files"
echo "  PASS: flake8 detected .py files"

# Test 2: no python files
should_run_linter "flake8" "README.md
test.sh" && rc=0 || rc=$?
assert_failure "$rc" "flake8 should NOT run without .py files"
echo "  PASS: flake8 skipped without .py files"

# Test 3: JS/TS detected
should_run_linter "eslint" "src/component.tsx" && rc=0 || rc=$?
assert_success "$rc" "eslint should run on .tsx files"
echo "  PASS: eslint detected .tsx files"

# Test 4: no matching files
should_run_linter "eslint" "main.py" && rc=0 || rc=$?
assert_failure "$rc" "eslint should NOT run on .py files"
echo "  PASS: eslint skipped on .py files"

# Test 5: gitleaks always runs
should_run_linter "gitleaks" "" && rc=0 || rc=$?
assert_success "$rc" "gitleaks should always run"
echo "  PASS: gitleaks always runs"

# Test 6: Go linters
should_run_linter "gofmt" "main.go" && rc=0 || rc=$?
assert_success "$rc" "gofmt should run on .go files"
echo "  PASS: gofmt detected .go files"

# Test 7: Dockerfile detection
should_run_linter "hadolint" "Dockerfile" && rc=0 || rc=$?
assert_success "$rc" "hadolint should run on Dockerfile"
echo "  PASS: hadolint detected Dockerfile"

# Test 8: Rust linters
should_run_linter "clippy" "src/lib.rs" && rc=0 || rc=$?
assert_success "$rc" "clippy should run on .rs files"
echo "  PASS: clippy detected .rs files"

# Test 9: YAML linters
should_run_linter "yamllint" "config/deploy.yml" && rc=0 || rc=$?
assert_success "$rc" "yamllint should run on .yml files"
echo "  PASS: yamllint detected .yml files"

# Test 10: Shell linters
should_run_linter "shellcheck" "script.sh" && rc=0 || rc=$?
assert_success "$rc" "shellcheck should run on .sh files"
echo "  PASS: shellcheck detected .sh files"

# Test 11: Unknown linter (default to run)
should_run_linter "unknown-linter" "" && rc=0 || rc=$?
assert_success "$rc" "unknown linter should run by default"
echo "  PASS: unknown linter runs by default"

# Test 12: detect_changed_files in non-git directory
ORIG_DIR=$(pwd)
TMP_DIR=$(mktemp -d)
mkdir -p "$TMP_DIR/subdir"
echo "test" > "$TMP_DIR/subdir/test.py"
output=$(cd "$TMP_DIR" && detect_changed_files 2>/dev/null)
if echo "$output" | grep -qF "test.py"; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: detect_changed_files should find test.py (got: '$output')"
fi
echo "  PASS: detect_changed_files finds files"
rm -rf "$TMP_DIR"
cd "$ORIG_DIR"

echo ""
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
fi
