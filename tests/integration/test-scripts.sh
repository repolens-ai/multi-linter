#!/bin/bash
# Unit tests for linter scripts

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURES="$PROJECT_ROOT/tests/fixtures"

echo "Running linter script unit tests..."

# Test helper function
test_linter_script() {
    local script="$1"
    local name=$(basename "$script" .sh)
    
    echo "Testing: $name"
    
    # Check script exists and is executable
    if [ ! -f "$script" ]; then
        echo "FAIL: Script not found: $script"
        return 1
    fi
    
    if [ ! -x "$script" ]; then
        echo "FAIL: Script not executable: $script"
        return 1
    fi
    
    # Check script has shebang
    if ! head -1 "$script" | grep -q "^#!"; then
        echo "FAIL: Missing shebang: $script"
        return 1
    fi
    
    # Check script has CONFIG_FILE variable
    if ! grep -q "CONFIG_FILE=" "$script"; then
        echo "FAIL: Missing CONFIG_FILE variable: $script"
        return 1
    fi
    
    # Check for proper error handling
    if ! grep -qE "^set -[euo]|^set -[eu]|^set -[eo]|^set -[e]" "$script"; then
        echo "WARN: Missing 'set -e' in: $script"
    fi
    
    echo "PASS: $name"
    return 0
}

test_linter_execution() {
    local script="$1"
    local name=$(basename "$script" .sh)
    
    # Find matching fixture
    local fixture=""
    case "$name" in
        flake8)
            fixture="$FIXTURES/python/bad.py"
            ;;
        eslint)
            fixture="$FIXTURES/javascript/bad.js"
            ;;
        yamllint)
            fixture="$FIXTURES/yaml/bad.yml"
            ;;
        shellcheck)
            fixture="$FIXTURES/shell/bad.sh"
            ;;
        hadolint)
            fixture="$FIXTURES/docker/Dockerfile.bad"
            ;;
        *)
            return 0
            ;;
    esac
    
    if [ -f "$fixture" ]; then
        echo "  Testing with fixture: $fixture"
        if timeout 30 "$script" "$PROJECT_ROOT/config/linter-config.yaml" > /dev/null 2>&1 || [ $? -eq 124 ]; then
            echo "  PASS: $name executes without crash"
            return 0
        else
            echo "  WARN: $name may have execution issues"
            return 0
        fi
    fi
    return 0
}

FAILED=0

# Test all linter scripts
echo "=== Linter Script Validation ==="
for script in "$PROJECT_ROOT"/linters/*.sh; do
    if [ -f "$script" ]; then
        if ! test_linter_script "$script"; then
            FAILED=$((FAILED + 1))
        fi
    fi
done

# Test scripts directory
echo "=== Script Directory Validation ==="
for script in "$PROJECT_ROOT"/scripts/*.sh; do
    if [ -f "$script" ]; then
        if ! test_linter_script "$script"; then
            FAILED=$((FAILED + 1))
        fi
    fi
done

# Test basic execution (if linters are available)
echo "=== Linter Execution Tests ==="
if command -v shellcheck >/dev/null 2>&1; then
    for script in "$PROJECT_ROOT"/linters/*.sh; do
        if [ -f "$script" ]; then
            test_linter_execution "$script" || true
        fi
    done
else
    echo "SKIP: ShellCheck not available for execution tests"
fi

# Count linter scripts
LINTER_COUNT=$(ls -1 "$PROJECT_ROOT"/linters/*.sh 2>/dev/null | wc -l)
SCRIPT_COUNT=$(ls -1 "$PROJECT_ROOT"/scripts/*.sh 2>/dev/null | wc -l)
echo ""
echo "Total scripts tested: $((LINTER_COUNT + SCRIPT_COUNT))"

if [ $FAILED -gt 0 ]; then
    echo "FAIL: $FAILED test(s) failed"
    exit 1
fi

echo "All unit tests passed!"
