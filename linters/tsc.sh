#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.tsc.paths | join(" ")' $CONFIG_FILE)
ARGS=($PATHS)
ARGS+=("--noEmit")

npx tsc "${ARGS[@]}" 2>&1 | while IFS= read -r line; do
    if echo "$line" | grep -E "^[^/]+/[^(]" > /dev/null; then
        FILE=$(echo "$line" | sed 's/(\([0-9]\+,[0-9]\+\).*/:\1:ERROR:/' | sed 's/^\([^:]*\):.*/\1/')
        LINE=$(echo "$line" | sed 's/.*(\([0-9]\+,[0-9]\+\).*/\1/' | cut -d, -f1)
        MSG=$(echo "$line" | sed 's/.*) //')
        echo "$FILE:$LINE:ERROR: $MSG" >> /tmp/linter.log
    fi
done || true
