#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.prettier.paths | join(" ")' $CONFIG_FILE)
AUTO_FIX=$(yq e '.linters.prettier.auto_fix' $CONFIG_FILE)

if [ "$AUTO_FIX" = "true" ]; then
    prettier --write $PATHS >> /tmp/linter.log 2>&1 || true
else
    prettier --check $PATHS 2>&1 | grep "Checking" -v | grep "All matched files use Prettier" -v | while read -r line; do
        [ -z "$line" ] && continue
        echo "$line:1:WARNING: File is not formatted with Prettier." >> /tmp/linter.log
    done || true
fi
