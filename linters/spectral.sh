#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.spectral.paths | join(" ")' $CONFIG_FILE)
for path in $PATHS; do
    if [ -f "$path" ]; then
        spectral lint "$path" --format json 2>/dev/null | jq -r '.[] | .source + ":" + (.range.start.line|tostring) + ":ERROR: " + .message' >> /tmp/linter.log 2>/dev/null || true
    fi
done