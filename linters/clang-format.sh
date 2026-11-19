#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.clang-format.paths | join(" ")' $CONFIG_FILE)
for pattern in $PATHS; do
    for path in $(eval "find . -path '$pattern' -type f 2>/dev/null"); do
        clang-format --dry-run --Werror "$path" 2>&1 | while IFS= read -r line; do
            echo "$path:1:WARNING: $line" >> /tmp/linter.log
        done || true
    done
done