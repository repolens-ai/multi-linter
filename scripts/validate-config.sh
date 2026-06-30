#!/bin/bash

set -euo pipefail

CONFIG_FILE=${1:-config/linter-config.yaml}
SCHEMA_FILE=${SCHEMA_FILE:-config/linter-config.schema.json}
HAS_ERRORS=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/logging.sh
source "$SCRIPT_DIR/logging.sh"

if [ -x /tmp/yq ]; then
    YQ=/tmp/yq
elif command -v yq &>/dev/null; then
    YQ=yq
else
    log_error "yq not found"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    log_error "Config file not found: $CONFIG_FILE"
    exit 1
fi

log_info "Validating config file: $CONFIG_FILE"

$YQ e '.version' "$CONFIG_FILE" > /dev/null 2>&1 || { log_error "Missing required field 'version'"; HAS_ERRORS=1; }
$YQ e '.fail_on_error' "$CONFIG_FILE" > /dev/null 2>&1 || { log_error "Missing required field 'fail_on_error'"; HAS_ERRORS=1; }
$YQ e '.report_format' "$CONFIG_FILE" > /dev/null 2>&1 || { log_error "Missing required field 'report_format'"; HAS_ERRORS=1; }
$YQ e '.linters' "$CONFIG_FILE" > /dev/null 2>&1 || { log_error "Missing required section 'linters'"; HAS_ERRORS=1; }

FORMAT=$($YQ e '.report_format // ""' "$CONFIG_FILE")
case "$FORMAT" in
    github|json|text|yaml|junit|markdown) ;;
    *)
        log_error "Invalid report_format '$FORMAT'. Must be one of: github, json, text, yaml, junit, markdown"
        HAS_ERRORS=1
        ;;
esac

FAIL_ON_ERROR=$($YQ e '.fail_on_error // ""' "$CONFIG_FILE")
if [ "$FAIL_ON_ERROR" != "true" ] && [ "$FAIL_ON_ERROR" != "false" ]; then
    log_error "fail_on_error must be boolean (true/false)"
    HAS_ERRORS=1
fi

VERSION=$($YQ e '.version // ""' "$CONFIG_FILE")
if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+$'; then
    log_error "Invalid version format '$VERSION'. Must be like '1.0'"
    HAS_ERRORS=1
fi

LINTERS=$($YQ e '.linters | keys | .[]' "$CONFIG_FILE" 2>/dev/null || echo "")
if [ -z "$LINTERS" ]; then
    log_error "No linters defined in configuration"
    HAS_ERRORS=1
fi

for linter in $LINTERS; do
    HAS_ENABLED=$($YQ e ".linters.$linter | has(\"enabled\")" "$CONFIG_FILE" 2>/dev/null || echo "false")
    if [ "$HAS_ENABLED" != "true" ]; then
        log_error "Linter '$linter' missing 'enabled' field"
        HAS_ERRORS=1
        continue
    fi

    ENABLED=$($YQ e ".linters.$linter.enabled" "$CONFIG_FILE" 2>/dev/null || echo "false")

    HAS_PATHS=$($YQ e ".linters.$linter | has(\"paths\")" "$CONFIG_FILE" 2>/dev/null || echo "false")
    if [ "$HAS_PATHS" != "true" ]; then
        log_error "Linter '$linter' missing 'paths' field"
        HAS_ERRORS=1
    fi

    if [ "$ENABLED" = "true" ]; then
        SCRIPT_PATH="/usr/local/bin/${linter}.sh"
        if [ ! -f "$SCRIPT_PATH" ]; then
            log_warn "No built-in script for linter '$linter' at $SCRIPT_PATH (may use plugin)"
        fi
    fi
done

if command -v check-jsonschema &>/dev/null && [ -f "$SCHEMA_FILE" ]; then
    log_info "Validating against JSON schema: $SCHEMA_FILE"
    $YQ e -j '.' "$CONFIG_FILE" | check-jsonschema --schemafile "$SCHEMA_FILE" - && log_info "Schema validation passed" || { log_error "Schema validation failed"; HAS_ERRORS=1; }
else
    log_debug "Schema validation skipped (install check-jsonschema for schema validation)"
fi

if [ $HAS_ERRORS -gt 0 ]; then
    log_error "Config validation FAILED with $HAS_ERRORS error(s)"
    exit 1
fi

log_info "Config validation passed!"
exit 0
