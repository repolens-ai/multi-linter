#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.checkov.paths | join(" ")' $CONFIG_FILE)
checkov -d . --framework $(yq e '.linters.checkov.frameworks // "all"' $CONFIG_FILE) --compact -o json 2>/dev/null | jq -r '.[] | .check_id as $id | .results[].passed_resources[] | . // empty' 2>/dev/null | while IFS= read -r resource; do
    echo "$resource:1:INFO: Checkov passed: $resource" >> /tmp/linter.log
done
jq -r '.[] | .results[].failed_resources[]? | .resource + ":" + (.__details__.file_line // "1") + ":ERROR: " + .check_id + " " + .check_name' /tmp/results.json 2>/dev/null >> /tmp/linter.log || true