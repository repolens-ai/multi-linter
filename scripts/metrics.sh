#!/bin/bash

METRICS_FILE=${METRICS_FILE:-/tmp/metrics.json}

init_metrics() {
    : > "$METRICS_FILE"
}

record_linter_result() {
    local linter=$1
    local exit_code=$2
    local duration=$3
    local errors=$4
    local warnings=$5
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local status="success"
    [ "$exit_code" -ne 0 ] && status="failure"

    jq -n \
        --arg linter "$linter" \
        --arg status "$status" \
        --arg duration "$duration" \
        --arg errors "$errors" \
        --arg warnings "$warnings" \
        --arg ts "$ts" \
        --arg exit_code "$exit_code" \
        '{linter: $linter, status: $status, exit_code: $exit_code, duration_seconds: $duration, errors: $errors, warnings: $warnings, timestamp: $ts}' >> "$METRICS_FILE"
}

metrics_summary() {
    if [ ! -f "$METRICS_FILE" ] || [ ! -s "$METRICS_FILE" ]; then
        echo '{"linters_total": 0}'
        return
    fi
    jq -s '{
        linters_total: length,
        total_duration_seconds: ([.[].duration_seconds | tonumber] | add // 0),
        total_errors: ([.[].errors | tonumber] | add // 0),
        total_warnings: ([.[].warnings | tonumber] | add // 0),
        failures: ([.[] | select(.status == "failure")] | length),
        successes: ([.[] | select(.status == "success")] | length),
        avg_duration_seconds: (if length > 0 then ([.[].duration_seconds | tonumber] | add // 0) / length else 0 end)
    }' "$METRICS_FILE"
}

metrics_prometheus() {
    if [ ! -f "$METRICS_FILE" ] || [ ! -s "$METRICS_FILE" ]; then
        return
    fi
    echo "# HELP multi_linter_duration_seconds Linter execution duration"
    echo "# TYPE multi_linter_duration_seconds gauge"
    jq -r -s '.[] | "multi_linter_duration_seconds{linter=\"\(.linter)\",status=\"\(.status)\"} \(.duration_seconds)"' "$METRICS_FILE"
    echo "# HELP multi_linter_errors_total Total errors per linter"
    echo "# TYPE multi_linter_errors_total counter"
    jq -r -s '.[] | "multi_linter_errors_total{linter=\"\(.linter)\"} \(.errors)"' "$METRICS_FILE"
    echo "# HELP multi_linter_warnings_total Total warnings per linter"
    echo "# TYPE multi_linter_warnings_total counter"
    jq -r -s '.[] | "multi_linter_warnings_total{linter=\"\(.linter)\"} \(.warnings)"' "$METRICS_FILE"
}

metrics_json() {
    metrics_summary
}

metrics_markdown() {
    local summary
    summary=$(metrics_summary)
    echo "## Multi-Linter Performance Report"
    echo ""
    echo "| Metric | Value |"
    echo "|--------|-------|"
    echo "$summary" | jq -r '
        "| Linters executed | \(.linters_total) |",
        "| Total duration | \(.total_duration_seconds)s |",
        "| Average duration | \(.avg_duration_seconds)s |",
        "| Total errors | \(.total_errors) |",
        "| Total warnings | \(.total_warnings) |",
        "| Failures | \(.failures) |",
        "| Successes | \(.successes) |"
    '
    echo ""
    echo "### Per-Linter Breakdown"
    echo ""
    echo "| Linter | Duration (s) | Errors | Warnings | Status |"
    echo "|--------|--------------|--------|----------|--------|"
    jq -r -s '.[] | "| \(.linter) | \(.duration_seconds) | \(.errors) | \(.warnings) | \(.status) |"' "$METRICS_FILE"
}
