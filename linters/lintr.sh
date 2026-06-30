#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.lintr.paths | join(" ")' $CONFIG_FILE)
Rscript -e "lintr::lint_dir('$PATHS')" 2>&1 | while IFS= read -r line; do
    if echo "$line" | grep -qE "^[^:]+:[0-9]+:"; then
        echo "$line" >> /tmp/linter.log
    fi
done || true