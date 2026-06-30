#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.perlcritic.paths | join(" ")' $CONFIG_FILE)
perlcritic --brutal $PATHS 2>&1 | while IFS= read -r line; do
    if echo "$line" | grep -qE "^[^:]+:[0-9]+:"; then
        echo "$line" >> /tmp/linter.log
    fi
done || true