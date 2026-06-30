#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0

# shellcheck source=scripts/logging.sh
source "$PROJECT_ROOT/scripts/logging.sh"

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
    rm -f /tmp/test-log-* /tmp/test-metrics-*
}
trap cleanup EXIT

echo "=== Testing logging.sh ==="

# Test 1: log_info writes to log file
LOG_FILE=/tmp/test-log-output.log
export LOG_FILE
rm -f "$LOG_FILE"
log_info "test info message"
assert_contains "$(cat "$LOG_FILE")" "[INFO]  " "log_info should write INFO level"
assert_contains "$(cat "$LOG_FILE")" "test info message" "log_info should write the message"
echo "  PASS: log_info writes to log file"

# Test 2: log_error writes to stderr and log
LOG_FILE=/tmp/test-log-error.log
rm -f "$LOG_FILE"
log_error "test error" 2>/dev/null
assert_contains "$(cat "$LOG_FILE")" "[ERROR]" "log_error should write ERROR to log"
echo "  PASS: log_error writes to log"

# Test 3: log_debug respects LOG_LEVEL
LOG_FILE=/tmp/test-log-debug.log
LOG_LEVEL=info
rm -f "$LOG_FILE"
log_debug "should not appear"
log_content=$(cat "$LOG_FILE" 2>/dev/null || echo "")
assert_eq "" "$log_content" "log_debug should not appear at info level"
LOG_LEVEL=debug
log_debug "should appear"
assert_contains "$(cat "$LOG_FILE" 2>/dev/null)" "should appear" "log_debug should appear at debug level"
echo "  PASS: log_debug respects LOG_LEVEL"

# Test 4: record_metric writes structured JSON
METRICS_FILE=/tmp/test-metrics.json
export METRICS_FILE
rm -f "$METRICS_FILE"
record_metric "test-linter" "success" 1.5 2 3
assert_contains "$(cat "$METRICS_FILE")" "test-linter" "record_metric should include linter name"
assert_contains "$(cat "$METRICS_FILE")" "success" "record_metric should include status"
assert_contains "$(cat "$METRICS_FILE")" "1.5" "record_metric should include duration"
echo "  PASS: record_metric writes structured JSON"

# Test 5: report_metrics_summary with no metrics file
METRICS_FILE=/tmp/test-metrics-none.json
rm -f "$METRICS_FILE"
output=$(report_metrics_summary)
assert_eq "" "$output" "report_metrics_summary should be silent with no metrics"
echo "  PASS: report_metrics_summary handles empty metrics gracefully"

# Test 6: cleanup_logs removes temp files
touch /tmp/cleanup-test.json /tmp/cleanup-test.log
cleanup_logs
assert_eq "" "$(cat /tmp/cleanup-test.json 2>/dev/null || echo '')" "cleanup_logs should remove json files"
assert_eq "" "$(cat /tmp/cleanup-test.log 2>/dev/null || echo '')" "cleanup_logs should remove log files"
echo "  PASS: cleanup_logs removes temp files"

echo ""
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
fi
