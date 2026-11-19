#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.npm-groovy-lint.paths | join(" ")' $CONFIG_FILE)
for path in $(eval "find $PATHS -name '*.groovy' -o -name '*.gvy' -o -name '*.gsh' -type f 2>/dev/null"); do
    npm-groovy-lint --format json --output /tmp/groovy-output.json "$path" 2>/dev/null || true
done
if [ -f /tmp/groovy-output.json ]; then
    jq -r '.[] | .fileName + ":" + (.lineNumber|tostring) + ":WARNING: " + .errMsg' /tmp/groovy-output.json >> /tmp/linter.log 2>/dev/null || true
fi