#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0

source "$PROJECT_ROOT/scripts/config-loader.sh"

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

make_test_config() {
    cat > /tmp/test-config.yaml << 'YAML'
version: "1.0"
fail_on_error: true
report_format: github
linters:
  eslint:
    enabled: true
    paths: ["**/*.js", "**/*.ts"]
    auto_fix: false
    config_file: ".eslintrc.json"
  flake8:
    enabled: true
    paths: ["**/*.py"]
    max_line_length: 120
  black:
    enabled: true
    paths: ["**/*.py"]
    auto_fix: false
  ruff:
    enabled: false
    paths: ["**/*.py"]
    auto_fix: true
  markdownlint:
    enabled: true
    paths: ["**/*.md"]
    config_file: ".markdownlint.yaml"
  shellcheck:
    enabled: true
    paths: ["**/*.sh"]
  hadolint:
    enabled: false
    paths: ["**/Dockerfile*"]
YAML
}

cleanup() {
    rm -f /tmp/test-config.yaml /tmp/merged-config.yaml /tmp/merged-*.yaml
    unset VALIDATE_JAVASCRIPT_ES VALIDATE_PYTHON VALIDATE_GO VALIDATE_RUST
    unset VALIDATE_SHELL VALIDATE_DOCKER VALIDATE_MARKDOWN
    unset ESLINT_CONFIG_FILE PRETTIER_CONFIG_FILE SHELLCHECK_CONFIG_FILE
    unset FIX_JAVASCRIPT_ES FIX_PYTHON FIX_GO
    unset FAIL_ON_ERROR REPORT_FORMAT DISABLE_ERRORS
}
trap cleanup EXIT

echo "=== Testing config-loader.sh ==="

# Test 1: linter_to_validate_var mapping
assert_eq "VALIDATE_JAVASCRIPT_ES" "$(linter_to_validate_var eslint)" "eslint -> VALIDATE_JAVASCRIPT_ES"
assert_eq "VALIDATE_PYTHON" "$(linter_to_validate_var flake8)" "flake8 -> VALIDATE_PYTHON"
assert_eq "VALIDATE_PYTHON" "$(linter_to_validate_var black)" "black -> VALIDATE_PYTHON"
assert_eq "VALIDATE_DOCKER" "$(linter_to_validate_var hadolint)" "hadolint -> VALIDATE_DOCKER"
assert_eq "" "$(linter_to_validate_var conflict-marker)" "conflict-marker has no validate var"
echo "  PASS: linter_to_validate_var mappings"

# Test 2: linter_to_fix_var mapping
assert_eq "FIX_JAVASCRIPT_ES" "$(linter_to_fix_var eslint)" "eslint -> FIX_JAVASCRIPT_ES"
assert_eq "FIX_PYTHON" "$(linter_to_fix_var black)" "black -> FIX_PYTHON"
assert_eq "" "$(linter_to_fix_var flake8)" "flake8 has no fix var"
echo "  PASS: linter_to_fix_var mappings"

# Test 3: linter_to_config_file_var mapping
assert_eq "ESLINT_CONFIG_FILE" "$(linter_to_config_file_var eslint)" "eslint -> ESLINT_CONFIG_FILE"
assert_eq "SHELLCHECK_CONFIG_FILE" "$(linter_to_config_file_var shellcheck)" "shellcheck -> SHELLCHECK_CONFIG_FILE"
echo "  PASS: linter_to_config_file_var mappings"

# Test 4: detect_validate_mode with no validate vars
unset VALIDATE_JAVASCRIPT_ES VALIDATE_PYTHON
assert_eq "mixed" "$(detect_validate_mode)" "no validate vars -> mixed"
echo "  PASS: detect_validate_mode with no vars"

# Test 5: detect_validate_mode with all true
export VALIDATE_JAVASCRIPT_ES=true
assert_eq "opt-in" "$(detect_validate_mode)" "all true -> opt-in"
echo "  PASS: detect_validate_mode with all true"

# Test 6: detect_validate_mode with all false
unset VALIDATE_JAVASCRIPT_ES
export VALIDATE_PYTHON=false
assert_eq "opt-out" "$(detect_validate_mode)" "all false -> opt-out"
echo "  PASS: detect_validate_mode with all false"

# Test 7: detect_validate_mode with mixed true/false
export VALIDATE_JAVASCRIPT_ES=true
export VALIDATE_PYTHON=false
assert_eq "mixed" "$(detect_validate_mode)" "mixed -> mixed"
echo "  PASS: detect_validate_mode with mixed"

# Test 8: resolve_linter_enabled with explicit VALIDATE_*=true
unset VALIDATE_PYTHON
export VALIDATE_JAVASCRIPT_ES=true
make_test_config
assert_eq "true" "$(resolve_linter_enabled eslint /tmp/test-config.yaml)" "VALIDATE_JAVASCRIPT_ES=true -> eslint enabled"
echo "  PASS: resolve_linter_enabled with explicit true"

# Test 9: resolve_linter_enabled with explicit VALIDATE_*=false
export VALIDATE_JAVASCRIPT_ES=false
make_test_config
assert_eq "false" "$(resolve_linter_enabled eslint /tmp/test-config.yaml)" "VALIDATE_JAVASCRIPT_ES=false -> eslint disabled"
echo "  PASS: resolve_linter_enabled with explicit false"

# Test 10: resolve_linter_enabled opt-in mode (unset linter disabled)
export VALIDATE_JAVASCRIPT_ES=true
unset VALIDATE_PYTHON VALIDATE_SHELL VALIDATE_DOCKER VALIDATE_MARKDOWN
make_test_config
assert_eq "false" "$(resolve_linter_enabled flake8 /tmp/test-config.yaml)" "opt-in: unset linter disabled"
assert_eq "false" "$(resolve_linter_enabled hadolint /tmp/test-config.yaml)" "opt-in: config-disabled stays disabled"
echo "  PASS: resolve_linter_enabled opt-in mode"

# Test 11: apply_env_overrides with VALIDATE_JAVASCRIPT_ES=true
unset VALIDATE_PYTHON VALIDATE_SHELL VALIDATE_DOCKER VALIDATE_MARKDOWN
export VALIDATE_JAVASCRIPT_ES=true
make_test_config
apply_env_overrides /tmp/test-config.yaml /tmp/merged-test11.yaml > /dev/null 2>&1
result=$(yq e '.linters.eslint.enabled' /tmp/merged-test11.yaml)
assert_eq "true" "$result" "merged: eslint enabled by env var"
result=$(yq e '.linters.hadolint.enabled' /tmp/merged-test11.yaml)
assert_eq "false" "$result" "merged: hadolint disabled by opt-in mode"
echo "  PASS: apply_env_overrides with opt-in"

# Test 12: apply_env_overrides with VALIDATE_PYTHON=false (opt-out)
unset VALIDATE_JAVASCRIPT_ES VALIDATE_PYTHON VALIDATE_SHELL VALIDATE_DOCKER VALIDATE_MARKDOWN
export VALIDATE_PYTHON=false
make_test_config
apply_env_overrides /tmp/test-config.yaml /tmp/merged-test12.yaml > /dev/null 2>&1
result=$(yq e '.linters.flake8.enabled' /tmp/merged-test12.yaml)
assert_eq "false" "$result" "opt-out: flake8 disabled"
result=$(yq e '.linters.eslint.enabled' /tmp/merged-test12.yaml)
assert_eq "true" "$result" "opt-out: eslint stays enabled (no var set)"
echo "  PASS: apply_env_overrides with opt-out"

# Test 13: apply_env_overrides with *CONFIG_FILE env var
unset VALIDATE_JAVASCRIPT_ES VALIDATE_PYTHON VALIDATE_SHELL VALIDATE_DOCKER VALIDATE_MARKDOWN
export ESLINT_CONFIG_FILE=/custom/.eslintrc.json
make_test_config
apply_env_overrides /tmp/test-config.yaml /tmp/merged-test13.yaml > /dev/null 2>&1
result=$(yq e '.linters.eslint.config_file' /tmp/merged-test13.yaml)
assert_eq "/custom/.eslintrc.json" "$result" "config_file override via env var"
echo "  PASS: apply_env_overrides with *_CONFIG_FILE"

# Test 14: apply_env_overrides with FIX_* env var
unset VALIDATE_JAVASCRIPT_ES VALIDATE_PYTHON VALIDATE_SHELL VALIDATE_DOCKER VALIDATE_MARKDOWN
unset ESLINT_CONFIG_FILE
export FIX_JAVASCRIPT_ES=true
make_test_config
apply_env_overrides /tmp/test-config.yaml /tmp/merged-test14.yaml > /dev/null 2>&1
result=$(yq e '.linters.eslint.auto_fix' /tmp/merged-test14.yaml)
assert_eq "true" "$result" "auto_fix override via FIX_* env var"
echo "  PASS: apply_env_overrides with FIX_*"

# Test 15: apply_env_overrides with DISABLE_ERRORS=true
unset VALIDATE_JAVASCRIPT_ES VALIDATE_PYTHON VALIDATE_SHELL VALIDATE_DOCKER VALIDATE_MARKDOWN
unset ESLINT_CONFIG_FILE FIX_JAVASCRIPT_ES
export DISABLE_ERRORS=true
make_test_config
apply_env_overrides /tmp/test-config.yaml /tmp/merged-test15.yaml > /dev/null 2>&1
result=$(yq e '.fail_on_error' /tmp/merged-test15.yaml)
assert_eq "false" "$result" "DISABLE_ERRORS=true sets fail_on_error=false"
echo "  PASS: apply_env_overrides with DISABLE_ERRORS"

# Test 16: apply_env_overrides with REPORT_FORMAT
unset DISABLE_ERRORS
export REPORT_FORMAT=junit
make_test_config
apply_env_overrides /tmp/test-config.yaml /tmp/merged-test16.yaml > /dev/null 2>&1
result=$(yq e '.report_format' /tmp/merged-test16.yaml)
assert_eq "junit" "$result" "REPORT_FORMAT=junit override"
echo "  PASS: apply_env_overrides with REPORT_FORMAT"

# Test 17: *FILE_NAME also works for config override
unset ESLINT_CONFIG_FILE VALIDATE_JAVASCRIPT_ES VALIDATE_PYTHON
export ESLINT_FILE_NAME=/custom/.eslintrc.yaml
make_test_config
apply_env_overrides /tmp/test-config.yaml /tmp/merged-test17.yaml > /dev/null 2>&1
result=$(yq e '.linters.eslint.config_file' /tmp/merged-test17.yaml)
assert_eq "/custom/.eslintrc.yaml" "$result" "FILE_NAME override"
echo "  PASS: apply_env_overrides with *_FILE_NAME"

# Test 18: linter not covered by any VALIDATE_* keeps config value in mixed mode
unset VALIDATE_JAVASCRIPT_ES VALIDATE_PYTHON VALIDATE_SHELL VALIDATE_DOCKER VALIDATE_MARKDOWN
unset ESLINT_CONFIG_FILE ESLINT_FILE_NAME FIX_JAVASCRIPT_ES REPORT_FORMAT DISABLE_ERRORS
export VALIDATE_JAVASCRIPT_ES=true
export VALIDATE_PYTHON=false
unset VALIDATE_SHELL
make_test_config
apply_env_overrides /tmp/test-config.yaml /tmp/merged-test18.yaml > /dev/null 2>&1
result=$(yq e '.linters.eslint.enabled' /tmp/merged-test18.yaml)
assert_eq "true" "$result" "mixed mode: eslint true"
result=$(yq e '.linters.flake8.enabled' /tmp/merged-test18.yaml)
assert_eq "false" "$result" "mixed mode: flake8 false (opt-out)"
result=$(yq e '.linters.shellcheck.enabled' /tmp/merged-test18.yaml)
assert_eq "true" "$result" "mixed mode: shellcheck uses config default (true)"
echo "  PASS: apply_env_overrides mixed mode"

echo ""
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
fi
