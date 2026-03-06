#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.isort.paths | join(" ")' $CONFIG_FILE)
AUTO_FIX=$(yq e '.linters.isort.auto_fix' $CONFIG_FILE)
ARGS=($PATHS)
[ "$AUTO_FIX" = "true" ] && ARGS+=("--diff")

isort "${ARGS[@]}" --check 2>&1 | while IFS= read -r line; do
    if echo "$line" | grep -E "\.py:[0-9]+" > /dev/null; then
        echo "$line" | sed 's/\.py:\([0-9]\+\)/.py:\1:ERROR:/' >> /tmp/linter.log
    fi
done || true
