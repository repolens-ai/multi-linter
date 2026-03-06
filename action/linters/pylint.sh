#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.pylint.paths | join(" ")' $CONFIG_FILE)
ARGS=($PATHS)
ARGS+=("--output-format=text")

pylint "${ARGS[@]}" 2>&1 | while IFS= read -r line; do
    if echo "$line" | grep -E "^[^:]+:[0-9]+:" > /dev/null; then
        echo "$line" | sed 's/^[^:]\+:\([0-9]\+\):\s*\([CEW]\)/\1:\2:/' >> /tmp/linter.log
    fi
done || true
