#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0

source "$PROJECT_ROOT/scripts/plugin-loader.sh"

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

cleanup() {
    rm -rf /tmp/test-plugins
}
trap cleanup EXIT

echo "=== Testing plugin-loader.sh ==="

# Set up test plugin directory
TEST_PLUGIN_DIR=/tmp/test-plugins
mkdir -p "$TEST_PLUGIN_DIR/valid-plugin"
mkdir -p "$TEST_PLUGIN_DIR/invalid-plugin"
mkdir -p "$TEST_PLUGIN_DIR/no-name-plugin"

cat > "$TEST_PLUGIN_DIR/valid-plugin/manifest.yaml" << 'YAML'
name: valid-plugin
description: A valid test plugin
version: 1.0.0
language: python
enabled: true
paths:
  - "**/*.py"
script: linter.sh
args: ["--strict"]
YAML

cat > "$TEST_PLUGIN_DIR/valid-plugin/linter.sh" << 'SCRIPT'
#!/bin/bash
echo "Valid plugin running with config: $1"
echo "test.py:1:ERROR: Test error from plugin" >> /tmp/linter.log
SCRIPT
chmod +x "$TEST_PLUGIN_DIR/valid-plugin/linter.sh"

cat > "$TEST_PLUGIN_DIR/invalid-plugin/manifest.yaml" << 'YAML'
name: invalid-plugin
description: Missing script field
version: 1.0.0
enabled: true
paths:
  - "**/*.txt"
YAML

cat > "$TEST_PLUGIN_DIR/no-name-plugin/manifest.yaml" << 'YAML'
description: No name field
version: 1.0.0
enabled: true
paths:
  - "**/*.md"
script: linter.sh
YAML

# Test 1: discover_plugins finds valid plugins
plugins=$(discover_plugins "$TEST_PLUGIN_DIR")
assert_contains "$plugins" "valid-plugin" "discover_plugins should find valid-plugin"
echo "  PASS: discover_plugins finds valid-plugin"

# Test 2: discover_plugins also finds invalid-plugin (has name field)
assert_contains "$plugins" "invalid-plugin" "discover_plugins should find invalid-plugin (has name)"
echo "  PASS: discover_plugins finds plugins by name field"

# Test 3: discover_plugins on non-existent directory
empty_output=$(discover_plugins "/nonexistent/path" || true)
assert_eq "" "$empty_output" "discover_plugins should return empty for missing dir"
echo "  PASS: discover_plugins handles missing directory"

# Test 4: load_plugin_config loads plugin metadata
config=$(load_plugin_config "valid-plugin" "$TEST_PLUGIN_DIR")
assert_contains "$config" "valid-plugin" "load_plugin_config should contain name"
echo "  PASS: load_plugin_config loads valid plugin"

# Test 5: load_plugin_config returns 1 for missing
rc=0
load_plugin_config "nonexistent" "$TEST_PLUGIN_DIR" || rc=$?
assert_failure "$rc" "load_plugin_config should fail for missing plugin"
echo "  PASS: load_plugin_config fails for missing plugin"

# Test 6: validate_plugin_manifest on valid plugin
validate_plugin_manifest "$TEST_PLUGIN_DIR/valid-plugin/manifest.yaml" && rc=0 || rc=$?
assert_success "$rc" "validate_plugin_manifest should pass for valid plugin"
echo "  PASS: validate_plugin_manifest validates valid plugin"

# Test 7: validate_plugin_manifest on invalid (missing script)
validate_plugin_manifest "$TEST_PLUGIN_DIR/invalid-plugin/manifest.yaml" && rc=0 || rc=$?
assert_failure "$rc" "validate_plugin_manifest should fail for missing script field"
echo "  PASS: validate_plugin_manifest catches missing script"

# Test 8: validate_plugin_manifest on missing file
validate_plugin_manifest "/nonexistent/manifest.yaml" && rc=0 || rc=$?
assert_failure "$rc" "validate_plugin_manifest should fail for non-existent file"
echo "  PASS: validate_plugin_manifest handles missing file"

# Test 9: run_plugin executes plugin script
rm -f /tmp/linter.log
touch /tmp/linter.log
run_plugin "valid-plugin" "$TEST_PLUGIN_DIR" "/tmp/fake-config.yaml"
assert_contains "$(cat /tmp/linter.log)" "Test error from plugin" "run_plugin should write to log"
echo "  PASS: run_plugin executes plugin and writes to log"

# Test 10: run_plugin on non-existent
rc=0
run_plugin "nonexistent" "$TEST_PLUGIN_DIR" "/tmp/fake-config.yaml" || rc=$?
assert_failure "$rc" "run_plugin should fail for non-existent plugin"
echo "  PASS: run_plugin fails for non-existent plugin"

echo ""
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
fi
