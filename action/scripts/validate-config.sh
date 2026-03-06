#!/bin/bash
# Config validation script

set -e

CONFIG_FILE=${1:-config/linter-config.yaml}

# Find yq
if [ -x /tmp/yq ]; then
    YQ=/tmp/yq
elif command -v yq &>/dev/null; then
    YQ=yq
else
    echo "Error: yq not found"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    exit 1
fi

echo "Validating config file: $CONFIG_FILE"

# Check required fields
if ! $YQ e '.version' "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "Error: Missing required field 'version'"
    exit 1
fi

if ! $YQ e '.fail_on_error' "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "Error: Missing required field 'fail_on_error'"
    exit 1
fi

if ! $YQ e '.report_format' "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "Error: Missing required field 'report_format'"
    exit 1
fi

# Validate linters section
if ! $YQ e '.linters' "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "Error: Missing required section 'linters'"
    exit 1
fi

# Check each linter has required fields
LINTERS=$($YQ e '.linters | keys' "$CONFIG_FILE")
for linter in $(echo "$LINTERS" | grep -v "^#" | grep -v "^$" | sed 's/^[[:space:]]*//'); do
    if [ -n "$linter" ]; then
        if ! $YQ e ".linters.$linter.enabled" "$CONFIG_FILE" > /dev/null 2>&1; then
            echo "Error: Linter '$linter' missing 'enabled' field"
            exit 1
        fi
        
        if ! $YQ e ".linters.$linter.paths" "$CONFIG_FILE" > /dev/null 2>&1; then
            echo "Error: Linter '$linter' missing 'paths' field"
            exit 1
        fi
    fi
done

# Validate report_format values
FORMAT=$($YQ e '.report_format' "$CONFIG_FILE")
case "$FORMAT" in
    github|json|text|yaml)
        ;;
    *)
        echo "Error: Invalid report_format '$FORMAT'. Must be one of: github, json, text, yaml"
        exit 1
        ;;
esac

# Validate fail_on_error is boolean
if ! $YQ e '.fail_on_error' "$CONFIG_FILE" | grep -qE 'true|false'; then
    echo "Error: fail_on_error must be boolean"
    exit 1
fi

# Validate version format
VERSION=$($YQ e '.version' "$CONFIG_FILE")
if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+$'; then
    echo "Error: Invalid version format '$VERSION'. Must be like '1.0'"
    exit 1
fi

echo "Config validation passed!"
exit 0
