#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.asl-validator.paths | join(" ")' $CONFIG_FILE)
for path in $(eval "find $PATHS -name '*.asl.json' -type f 2>/dev/null"); do
    asl-validator --json-path "$path" 2>&1 | jq -r '.errors[]? | (.location // "unknown") + ":1:ERROR: " + .message' >> /tmp/linter.log 2>/dev/null || true
done