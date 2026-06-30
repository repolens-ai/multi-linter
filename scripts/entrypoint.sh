#!/bin/bash
set -euo pipefail

CONFIG_FILE=${CONFIG_FILE:-/tmp/config/linter-config.yaml}
PLUGIN_DIR=${PLUGIN_DIR:-/usr/local/bin/plugins}
LINTER_TIMEOUT=${LINTER_TIMEOUT:-300}
LOG_LEVEL=${LOG_LEVEL:-info}
METRICS_FILE=${METRICS_FILE:-/tmp/metrics.json}
LOG_FILE=${LOG_FILE:-/tmp/linter.log}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/logging.sh
source "$SCRIPT_DIR/logging.sh"
# shellcheck source=scripts/detect-files.sh
source "$SCRIPT_DIR/detect-files.sh"
# shellcheck source=scripts/plugin-loader.sh
source "$SCRIPT_DIR/plugin-loader.sh"
# shellcheck source=scripts/config-loader.sh
source "$SCRIPT_DIR/config-loader.sh"
# shellcheck source=scripts/metrics.sh
source "$SCRIPT_DIR/metrics.sh"

cleanup() {
    cleanup_logs
}
trap cleanup EXIT

if [ ! -f "$CONFIG_FILE" ]; then
    log_error "Config file not found: $CONFIG_FILE"
    exit 1
fi

if ! command -v yq &> /dev/null; then
    log_error "yq is not installed"
    exit 1
fi

if ! yq e '.' "$CONFIG_FILE" &> /dev/null; then
    log_error "Invalid YAML in config file: $CONFIG_FILE"
    exit 1
fi

log_info "Starting Multi-Linter with config: $CONFIG_FILE"
log_debug "Log level: $LOG_LEVEL, Timeout: ${LINTER_TIMEOUT}s"

MERGED_CONFIG=$(apply_env_overrides "$CONFIG_FILE" /tmp/merged-config.yaml 2>&1)
if [ $? -ne 0 ]; then
    log_error "Failed to apply env overrides: $MERGED_CONFIG"
    exit 1
fi
if [ -n "$MERGED_CONFIG" ] && [ -f "$MERGED_CONFIG" ]; then
    CONFIG_FILE="$MERGED_CONFIG"
    log_info "Applied environment variable overrides to config"
fi

export DEFAULT_WORKSPACE="${DEFAULT_WORKSPACE:-/tmp}"
export FILTER_REGEX_INCLUDE="${FILTER_REGEX_INCLUDE:-}"
export FILTER_REGEX_EXCLUDE="${FILTER_REGEX_EXCLUDE:-}"

: > "$LOG_FILE"
: > "$METRICS_FILE"

LINTERS=$(yq e '.linters | keys' "$CONFIG_FILE" -o=json)

CHANGED_FILES=$(detect_changed_files)
log_debug "Detected $(echo "$CHANGED_FILES" | wc -l) files to check"

if [ -n "$FILTER_REGEX_INCLUDE" ]; then
    log_debug "Applying FILTER_REGEX_INCLUDE: $FILTER_REGEX_INCLUDE"
    CHANGED_FILES=$(echo "$CHANGED_FILES" | grep -E "$FILTER_REGEX_INCLUDE" || true)
fi
if [ -n "$FILTER_REGEX_EXCLUDE" ]; then
    log_debug "Applying FILTER_REGEX_EXCLUDE: $FILTER_REGEX_EXCLUDE"
    CHANGED_FILES=$(echo "$CHANGED_FILES" | grep -v -E "$FILTER_REGEX_EXCLUDE" || true)
fi
log_debug "Files to check after filtering: $(echo "$CHANGED_FILES" | wc -l)"

FAILED_LINTERS=0
declare -A LINTER_PIDS

# Run built-in linters
for linter in $(echo "$LINTERS" | jq -r '.[]'); do
    ENABLED=$(yq e ".linters.$linter.enabled" "$CONFIG_FILE")
    if [ "$ENABLED" != "true" ]; then
        log_info "$linter is disabled, skipping."
        continue
    fi

    if ! should_run_linter "$linter" "$CHANGED_FILES"; then
        log_info "No relevant files for $linter, skipping."
        continue
    fi

    if [ ! -f "/usr/local/bin/$linter.sh" ]; then
        log_warn "Linter script not found: $linter.sh, skipping."
        continue
    fi

    LINTER_SCRIPT="/usr/local/bin/$linter.sh"
    LINTER_TIMEOUT_SPECIFIC=$(yq e ".linters.$linter.timeout // $LINTER_TIMEOUT" "$CONFIG_FILE")
    log_info "Running $linter (timeout: ${LINTER_TIMEOUT_SPECIFIC}s)..."
    (
        START_TIME=$(date +%s)
        set +e
        timeout "$LINTER_TIMEOUT_SPECIFIC" "$LINTER_SCRIPT" "$CONFIG_FILE"
        EXIT_CODE=$?
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))

        ERRORS=$(grep -cE ":ERROR:" /tmp/linter.log 2>/dev/null || echo "0")
        WARNINGS=$(grep -cE ":WARNING:" /tmp/linter.log 2>/dev/null || echo "0")

        record_linter_result "$linter" "$EXIT_CODE" "$DURATION" "$ERRORS" "$WARNINGS"
    ) &
    LINTER_PIDS[$linter]=$!
done

# Run plugin linters
log_info "Discovering plugins from: $PLUGIN_DIR"
for plugin in $(discover_plugins "$PLUGIN_DIR"); do
    PLUGIN_ENABLED=$(yq e '.enabled // true' "$PLUGIN_DIR/$plugin/manifest.yaml")
    if [ "$PLUGIN_ENABLED" != "true" ]; then
        log_info "Plugin $plugin is disabled, skipping."
        continue
    fi

    log_info "Running plugin: $plugin"
    (
        START_TIME=$(date +%s)
        set +e
        run_plugin "$plugin" "$PLUGIN_DIR" "$CONFIG_FILE"
        EXIT_CODE=$?
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))

        ERRORS=$(grep -cE ":ERROR:" /tmp/linter.log 2>/dev/null || echo "0")
        WARNINGS=$(grep -cE ":WARNING:" /tmp/linter.log 2>/dev/null || echo "0")

        record_linter_result "plugin:$plugin" "$EXIT_CODE" "$DURATION" "$ERRORS" "$WARNINGS"
    ) &
    LINTER_PIDS["plugin:$plugin"]=$!
done

# Wait for all parallel jobs and collect results
for name in "${!LINTER_PIDS[@]}"; do
    pid="${LINTER_PIDS[$name]}"
    set +e
    wait "$pid"
    EXIT_CODE=$?
    set -e
    if [ "$EXIT_CODE" -ne 0 ] && [ "$EXIT_CODE" -ne 124 ]; then
        FAILED_LINTERS=$((FAILED_LINTERS + 1))
        log_warn "Linter/Plugin '$name' failed (exit code: $EXIT_CODE)"
    elif [ "$EXIT_CODE" -eq 124 ]; then
        FAILED_LINTERS=$((FAILED_LINTERS + 1))
        log_warn "Linter/Plugin '$name' timed out"
    fi
done

report_metrics_summary

/usr/local/bin/reporter.sh "$CONFIG_FILE"

log_info "Linting complete."

if [ $FAILED_LINTERS -gt 0 ]; then
    log_warn "$FAILED_LINTERS linter(s) failed or timed out"
fi

# Export metrics for downstream tools
if [ -f "$METRICS_FILE" ] && [ -s "$METRICS_FILE" ]; then
    metrics_json > /tmp/metrics-summary.json
fi
