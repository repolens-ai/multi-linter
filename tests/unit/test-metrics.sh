#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0

# shellcheck source=scripts/metrics.sh
source "$PROJECT_ROOT/scripts/metrics.sh"

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

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-}"
    if echo "$haystack" | grep -qF "$needle"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "FAIL: $msg (expected to contain: '$needle')"
    fi
}

cleanup() {
    rm -f /tmp/test-metrics-*
}
trap cleanup EXIT

echo "=== Testing metrics.sh ==="

# Test 1: init_metrics creates empty file
METRICS_FILE=/tmp/test-metrics-init.json
export METRICS_FILE
rm -f "$METRICS_FILE"
init_metrics
assert_eq "" "$(cat "$METRICS_FILE")" "init_metrics should create empty file"
echo "  PASS: init_metrics creates empty file"

# Test 2: record_linter_result appends entry
init_metrics
record_linter_result "eslint" 0 1.5 2 1
assert_contains "$(cat "$METRICS_FILE")" "eslint" "record_linter_result should include linter name"
assert_contains "$(cat "$METRICS_FILE")" "success" "record_linter_result should mark success on exit 0"
echo "  PASS: record_linter_result records success"

# Test 3: record_linter_result records failure
init_metrics
record_linter_result "flake8" 1 0.5 3 0
assert_contains "$(cat "$METRICS_FILE")" "failure" "record_linter_result should mark failure on non-zero exit"
echo "  PASS: record_linter_result records failure"

# Test 4: metrics_summary with data
init_metrics
record_linter_result "eslint" 0 1.0 1 2
record_linter_result "flake8" 1 2.0 3 4
summary=$(metrics_summary)
assert_eq "$(echo "$summary" | jq '.linters_total')" "2" "metrics_summary should count 2 entries"
assert_eq "$(echo "$summary" | jq '.failures')" "1" "metrics_summary should count 1 failure"
assert_eq "$(echo "$summary" | jq '.successes')" "1" "metrics_summary should count 1 success"
echo "  PASS: metrics_summary aggregates correctly"

# Test 5: metrics_summary with empty file
METRICS_FILE=/tmp/test-metrics-empty.json
rm -f "$METRICS_FILE"
empty_summary=$(metrics_summary)
assert_eq "0" "$(echo "$empty_summary" | jq '.linters_total')" "metrics_summary should handle empty"
echo "  PASS: metrics_summary handles empty file"

# Test 6: metrics_prometheus outputs prometheus format
METRICS_FILE=/tmp/test-metrics-prom.json
export METRICS_FILE
init_metrics
record_linter_result "eslint" 0 1.5 2 1
prom_output=$(metrics_prometheus)
assert_contains "$prom_output" "multi_linter_duration_seconds" "prometheus output should contain duration"
assert_contains "$prom_output" "eslint" "prometheus output should contain linter name"
echo "  PASS: metrics_prometheus outputs prometheus format"

# Test 7: metrics_markdown outputs markdown
METRICS_FILE=/tmp/test-metrics-md.json
export METRICS_FILE
init_metrics
record_linter_result "eslint" 0 1.5 2 1
md_output=$(metrics_markdown)
assert_contains "$md_output" "Multi-Linter Performance Report" "markdown should have report title"
assert_contains "$md_output" "| Linter |" "markdown should have table header"
echo "  PASS: metrics_markdown outputs markdown format"

# Test 8: metrics_json returns JSON
METRICS_FILE=/tmp/test-metrics-json.json
export METRICS_FILE
init_metrics
record_linter_result "eslint" 0 1.5 2 1
json_output=$(metrics_json)
assert_eq "$(echo "$json_output" | jq '.linters_total')" "1" "metrics_json should have correct count"
echo "  PASS: metrics_json returns valid JSON"

echo ""
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
fi
