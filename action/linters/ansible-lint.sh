#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.ansible-lint.paths | join(" ")' $CONFIG_FILE)

ansible-lint $PATHS 2>&1 | while IFS= read -r line; do
    if echo "$line" | grep -E "^[^:]+:[0-9]+:" > /dev/null; then
        echo "$line" >> /tmp/linter.log
    fi
done || true
