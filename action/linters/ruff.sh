#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.ruff.paths | join(" ")' $CONFIG_FILE)
AUTO_FIX=$(yq e '.linters.ruff.auto_fix' $CONFIG_FILE)
ARGS=($PATHS)
[ "$AUTO_FIX" = "true" ] && ARGS+=(--fix)

ruff check "${ARGS[@]}" 2>&1 | while IFS= read -r line; do
    if echo "$line" | grep -E "^[^:]+:[0-9]+:" > /dev/null; then
        echo "$line" >> /tmp/linter.log
    fi
done || true
