#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.github-linter.paths | join(" ")' $CONFIG_FILE)

find .github/linters -name "*.yml" 2>/dev/null | while read -r file; do
    yamllint -c /tmp/config/.yamllint.yaml "$file" 2>&1 | while IFS= read -r line; do
        if echo "$line" | grep -E "^[^:]+:[0-9]+:" > /dev/null; then
            echo "$line" >> /tmp/linter.log
        fi
    done || true
done
