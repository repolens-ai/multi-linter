#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.markdownlint.paths | join(" ")' $CONFIG_FILE)
ARGS=($PATHS)

markdownlint "${ARGS[@]}" > /tmp/markdownlint.log 2>&1 || true

if [ -f /tmp/markdownlint.log ]; then
    while IFS= read -r line; do
        if echo "$line" | grep -E "^[^:]+:[0-9]+:" > /dev/null; then
            FILE=$(echo "$line" | cut -d: -f1)
            LINE=$(echo "$line" | cut -d: -f2)
            MSG=$(echo "$line" | cut -d: -f3-)
            echo "$FILE:$LINE:ERROR: $MSG" >> /tmp/linter.log
        fi
    done < /tmp/markdownlint.log
fi
