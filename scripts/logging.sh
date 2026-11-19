#!/bin/bash

LOG_LEVEL=${LOG_LEVEL:-info}
LOG_FILE=${LOG_FILE:-/tmp/linter.log}
METRICS_FILE=${METRICS_FILE:-/tmp/metrics.json}

log_debug() { [ "$LOG_LEVEL" = "debug" ] || return 0; echo -e "\033[1;90m[DEBUG] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $1\033[0m"; echo "[DEBUG] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"; }
log_info()  { echo -e "\033[1;34m[INFO]  $(date -u +"%Y-%m-%dT%H:%M:%SZ") $1\033[0m"; echo "[INFO]  $(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"; return 0; }
log_warn()  { echo -e "\033[1;33m[WARN]  $(date -u +"%Y-%m-%dT%H:%M:%SZ") $1\033[0m"; echo "[WARN]  $(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"; return 0; }
log_error() { echo -e "\033[1;31m[ERROR] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $1\033[0m" >&2; echo "[ERROR] $(date -u +"%Y-%m-%dT%H:%M:%SZ") $1" >> "$LOG_FILE"; return 0; }

record_metric() {
    local linter=$1
    local status=$2
    local duration=$3
    local errors=$4
    local warnings=$5
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local entry
    entry=$(jq -n \
        --arg linter "$linter" \
        --arg status "$status" \
        --arg duration "$duration" \
        --arg errors "$errors" \
        --arg warnings "$warnings" \
        --arg ts "$ts" \
        '{linter: $linter, status: $status, duration_seconds: $duration, errors: $errors, warnings: $warnings, timestamp: $ts}') || true
    echo "$entry" >> "$METRICS_FILE" || true
    return 0
}

report_metrics_summary() {
    if [ ! -f "$METRICS_FILE" ] || [ ! -s "$METRICS_FILE" ]; then
        return 0
    fi
    log_info "--- Performance Summary ---"
    local count
    count=$(jq -s 'length' "$METRICS_FILE" 2>/dev/null || echo "0")
    if [ "$count" = "0" ]; then
        return 0
    fi
    local total_duration
    total_duration=$(jq -s '[.[].duration_seconds | tonumber] | add // 0' "$METRICS_FILE" 2>/dev/null || echo "0")
    local total_errors
    total_errors=$(jq -s '[.[].errors | tonumber] | add // 0' "$METRICS_FILE" 2>/dev/null || echo "0")
    local total_warnings
    total_warnings=$(jq -s '[.[].warnings | tonumber] | add // 0' "$METRICS_FILE" 2>/dev/null || echo "0")
    log_info "Linters executed: $count"
    log_info "Total duration: ${total_duration}s"
    log_info "Total errors: $total_errors"
    log_info "Total warnings: $total_warnings"
    if [ "$count" -gt 0 ]; then
        local avg
        avg=$(echo "scale=2; $total_duration / $count" | bc 2>/dev/null || echo "$total_duration")
        log_info "Average duration: ${avg}s per linter"
    fi
    return 0
}

cleanup_logs() {
    rm -f /tmp/*.json /tmp/*.log /tmp/*.metrics 2>/dev/null || true
    return 0
}
