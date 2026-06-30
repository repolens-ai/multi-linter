#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.coffeelint.paths | join(" ")' $CONFIG_FILE)
coffeelint --reporter csv $PATHS 2>&1 | while IFS= read -r line; do
    if echo "$line" | grep -qE "^[^:]+,[0-9]+,"; then
        FILE=$(echo "$line" | cut -d, -f1)
        LINE=$(echo "$line" | cut -d, -f2)
        MSG=$(echo "$line" | cut -d, -f4-)
        echo "$FILE:$LINE:WARNING: $MSG" >> /tmp/linter.log
    fi
done || true