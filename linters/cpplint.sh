#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.cpplint.paths | join(" ")' $CONFIG_FILE)
FILTERS=$(yq e '.linters.cpplint.filters // "-whitespace/indent"' $CONFIG_FILE)
cpplint --filter="$FILTERS" $PATHS 2>&1 | while IFS= read -r line; do
    echo "$line" >> /tmp/linter.log
done || true