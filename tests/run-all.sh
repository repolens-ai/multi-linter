#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FAILED=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

run_test() {
    local test_script="$1"
    local name
    name=$(basename "$test_script")
    echo -e "\n${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Running: $name${NC}"
    echo -e "${YELLOW}========================================${NC}"
    if bash "$test_script"; then
        echo -e "${GREEN}✓ $name passed${NC}"
    else
        echo -e "${RED}✗ $name failed${NC}"
        FAILED=$((FAILED + 1))
    fi
}

echo -e "${YELLOW}Multi-Linter Test Runner${NC}"
echo "================================"
echo "Project root: $PROJECT_ROOT"
echo ""

# Run integration tests
if [ -f "$SCRIPT_DIR/integration/run-tests.sh" ]; then
    run_test "$SCRIPT_DIR/integration/run-tests.sh"
fi

# Run linter script tests
if [ -f "$SCRIPT_DIR/integration/test-scripts.sh" ]; then
    run_test "$SCRIPT_DIR/integration/test-scripts.sh"
fi

# Run unit tests
for test_script in "$SCRIPT_DIR/unit/"*.sh; do
    if [ -f "$test_script" ]; then
        run_test "$test_script"
    fi
done

echo ""
echo "================================"
if [ "$FAILED" -gt 0 ]; then
    echo -e "${RED}$FAILED test suite(s) failed${NC}"
    exit 1
else
    echo -e "${GREEN}All test suites passed!${NC}"
fi
