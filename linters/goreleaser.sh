#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.goreleaser.paths | join(" ")' $CONFIG_FILE)
for path in $PATHS; do
    if [ -f "$path" ]; then
        goreleaser check "$path" 2>&1 | while IFS= read -r line; do
            echo "$path:1:ERROR: $line" >> /tmp/linter.log
        done || true
    fi
done