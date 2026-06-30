#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.psscriptanalyzer.paths | join(" ")' $CONFIG_FILE)
for path in $(eval "find $PATHS -name '*.ps1' -o -name '*.psm1' -o -name '*.psd1' -type f 2>/dev/null"); do
    pwsh -Command "Invoke-ScriptAnalyzer -Path '$path' -Recurse -EnableExit" 2>&1 | while IFS= read -r line; do
        if echo "$line" | grep -qE "^[^:]+:Line [0-9]+:"; then
            echo "$line" >> /tmp/linter.log
        fi
    done || true
done