#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.govet.paths | join(" ")' $CONFIG_FILE)

go vet $PATHS 2>&1 | while IFS= read -r line; do
    if echo "$line" | grep -E "^[^:]+:[0-9]+:" > /dev/null; then
        echo "$line" | sed 's/^/:/' >> /tmp/linter.log
    else
        echo "$line" >> /tmp/linter.log
    fi
done || true
