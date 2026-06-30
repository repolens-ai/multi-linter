#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.dotnet-format.paths | join(" ")' $CONFIG_FILE)
for path in $PATHS; do
    if [ -f "$path" ] || [ -d "$path" ]; then
        dotnet format "$path" --verify-no-changes --report /tmp/dotnet-format.json 2>&1 || true
    fi
done
if [ -f /tmp/dotnet-format.json ]; then
    jq -r '.[] | .FilePath + ":" + (.Changes[].LineNumber|tostring) + ":WARNING: " + .Changes[].FormatDescription' /tmp/dotnet-format.json >> /tmp/linter.log 2>/dev/null || true
fi