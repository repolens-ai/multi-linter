#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.black.paths | join(" ")' $CONFIG_FILE)
AUTO_FIX=$(yq e '.linters.black.auto_fix' $CONFIG_FILE)

if [ "$AUTO_FIX" = "true" ]; then
    black $PATHS >> /tmp/linter.log 2>&1 || true
else
    # In check mode, parse output to list files needing reformatting
    black --check $PATHS 2>&1 | grep "would reformat" | while read -r line; do
        FILE=$(echo "$line" | awk '{print $NF}')
        echo "$FILE:1:ERROR: File matches black reformatting rules." >> /tmp/linter.log
    done || true
fi
