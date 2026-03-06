#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.eslint.paths | join(" ")' $CONFIG_FILE)
AUTO_FIX=$(yq e '.linters.eslint.auto_fix' $CONFIG_FILE)
ARGS=($PATHS)
[ "$AUTO_FIX" = "true" ] && ARGS+=("--fix")

# Run eslint and capture JSON output
eslint "${ARGS[@]}" --format json > /tmp/eslint.json || true

# Convert ESLint JSON into standard log format for reporter
# severity 1 = warning, severity 2 = error
jq -r '.[] | .filePath as $path | .messages[] | "\($path):\(.line):\(if .severity == 2 then "ERROR" else "WARNING" end): \(.message)"' /tmp/eslint.json >> /tmp/linter.log
