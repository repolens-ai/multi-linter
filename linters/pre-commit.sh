#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.pre-commit.paths | join(" ")' $CONFIG_FILE)
for path in $PATHS; do
    if [ -f "$path" ]; then
        pre-commit validate-config "$path" 2>&1 | while IFS= read -r line; do
            if echo "$line" | grep -qiE "error|invalid|fail"; then
                echo "$path:1:ERROR: $line" >> /tmp/linter.log
            fi
        done || true
    fi
done