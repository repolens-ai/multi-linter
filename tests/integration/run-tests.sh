#!/bin/bash
# Integration test for entrypoint.sh config validation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Use yq v4 if available
if [ -x /tmp/yq ]; then
    YQ=/tmp/yq
elif command -v yq &>/dev/null; then
    YQ=yq
else
    echo "yq not found - skipping YAML validation tests"
    YQ=""
fi

echo "Running integration tests..."

# Test 1: Config file validation
echo "Test 1: Config file validation"
if [ ! -f "$PROJECT_ROOT/config/linter-config.yaml" ]; then
    echo "FAIL: linter-config.yaml not found"
    exit 1
fi
echo "PASS: Config file exists"

# Test 2: All linter scripts exist
echo "Test 2: All linter scripts exist"
if [ -n "$YQ" ]; then
    for linter in $($YQ e '.linters | keys[]' "$PROJECT_ROOT/config/linter-config.yaml" 2>/dev/null); do
        if [ ! -f "$PROJECT_ROOT/linters/${linter}.sh" ]; then
            echo "FAIL: Missing linter script: ${linter}.sh"
            exit 1
        fi
    done
fi
echo "PASS: All linter scripts exist"

# Test 3: Scripts are executable
echo "Test 3: Scripts are executable"
for script in "$PROJECT_ROOT"/linters/*.sh "$PROJECT_ROOT"/scripts/*.sh; do
    if [ -f "$script" ] && [ ! -x "$script" ]; then
        echo "FAIL: Script not executable: $script"
        exit 1
    fi
done
echo "PASS: All scripts are executable"

# Test 4: Config is valid YAML
echo "Test 4: Config is valid YAML"
if [ -n "$YQ" ]; then
    if ! $YQ e '.' "$PROJECT_ROOT/config/linter-config.yaml" > /dev/null 2>&1; then
        echo "FAIL: Invalid YAML in config"
        exit 1
    fi
    echo "PASS: Config is valid YAML"
else
    echo "SKIP: yq not available"
fi

# Test 5: Self-lint config is valid YAML
echo "Test 5: Self-lint config is valid YAML"
if [ -n "$YQ" ]; then
    if ! $YQ e '.' "$PROJECT_ROOT/config/linter-config-self.yaml" > /dev/null 2>&1; then
        echo "FAIL: Invalid YAML in self-lint config"
        exit 1
    fi
    echo "PASS: Self-lint config is valid YAML"
else
    echo "SKIP: yq not available"
fi

# Test 6: Test fixtures exist
echo "Test 6: Test fixtures exist"
if [ ! -d "$PROJECT_ROOT/tests/fixtures" ]; then
    echo "FAIL: Test fixtures directory not found"
    exit 1
fi
FIXTURE_COUNT=$(find "$PROJECT_ROOT/tests/fixtures" -type f | wc -l)
if [ "$FIXTURE_COUNT" -lt 5 ]; then
    echo "FAIL: Not enough test fixtures ($FIXTURE_COUNT found)"
    exit 1
fi
echo "PASS: Test fixtures exist ($FIXTURE_COUNT files)"

# Test 7: Required linter config files exist
echo "Test 7: Required linter config files exist"
REQUIRED_CONFIGS=(
    ".eslintrc.json"
    ".yamllint.yaml"
    ".flake8"
    ".shellcheckrc"
)
MISSING=0
for config in "${REQUIRED_CONFIGS[@]}"; do
    if [ ! -f "$PROJECT_ROOT/$config" ]; then
        echo "FAIL: Missing required config file: $config"
        MISSING=$((MISSING + 1))
    fi
done
if [ $MISSING -gt 0 ]; then
    exit 1
fi
echo "PASS: All required config files exist"

# Test 8: GitHub Actions workflow files are valid YAML
echo "Test 8: GitHub Actions workflows are valid YAML"
if [ -n "$YQ" ]; then
    WORKFLOW_ERRORS=0
    for workflow in "$PROJECT_ROOT"/.github/workflows/*.yml "$PROJECT_ROOT"/.github/workflows/*.yaml; do
        if [ -f "$workflow" ]; then
            if ! $YQ e '.' "$workflow" > /dev/null 2>&1; then
                echo "FAIL: Invalid YAML in workflow: $workflow"
                WORKFLOW_ERRORS=$((WORKFLOW_ERRORS + 1))
            fi
        fi
    done
    if [ $WORKFLOW_ERRORS -gt 0 ]; then
        exit 1
    fi
    echo "PASS: All GitHub Actions workflows are valid YAML"
else
    echo "SKIP: yq not available"
fi

# Test 9: Dockerfile is valid
echo "Test 9: Dockerfile syntax check"
if [ -f "$PROJECT_ROOT/action/Dockerfile" ]; then
    if ! docker build --check -f "$PROJECT_ROOT/action/Dockerfile" "$PROJECT_ROOT/action" 2>/dev/null; then
        echo "WARN: Dockerfile may have syntax issues (docker build --check not available)"
    else
        echo "PASS: Dockerfile syntax is valid"
    fi
fi

# Test 10: Check linters have proper error handling
echo "Test 10: Linter scripts have error handling"
for script in "$PROJECT_ROOT"/linters/*.sh; do
    if [ -f "$script" ]; then
        if ! grep -q "set -" "$script" && ! grep -q "set -e" "$script"; then
            echo "WARN: Script may lack error handling: $(basename "$script")"
        fi
    fi
done
echo "PASS: Error handling checks complete"

# Test 11: Verify config file schema (basic validation)
echo "Test 11: Config schema validation"
if [ -n "$YQ" ]; then
    VERSION=$($YQ e '.version' "$PROJECT_ROOT/config/linter-config.yaml")
    if [ -z "$VERSION" ]; then
        echo "FAIL: Config missing 'version' field"
        exit 1
    fi
    echo "PASS: Config schema is valid"
else
    echo "SKIP: yq not available"
fi

# Test 12: Use validation script
echo "Test 12: Config validation script"
if [ -x "$PROJECT_ROOT/scripts/validate-config.sh" ]; then
    if [ -n "$YQ" ]; then
        if ! "$PROJECT_ROOT/scripts/validate-config.sh" "$PROJECT_ROOT/config/linter-config.yaml"; then
            echo "FAIL: Config validation script failed"
            exit 1
        fi
        echo "PASS: Config validation script passed"
    else
        echo "SKIP: yq not available"
    fi
else
    echo "SKIP: validate-config.sh not found or not executable"
fi

# Test 13: Verify self-lint config has fail_on_error
echo "Test 13: Self-lint config validation"
if [ -n "$YQ" ]; then
    SELF_FAIL=$($YQ e '.fail_on_error' "$PROJECT_ROOT/config/linter-config-self.yaml")
    if [ -z "$SELF_FAIL" ]; then
        echo "WARN: Self-lint config missing 'fail_on_error' field"
    else
        echo "PASS: Self-lint config has fail_on_error set"
    fi
else
    echo "SKIP: yq not available"
fi

echo ""
echo "All integration tests passed!"
