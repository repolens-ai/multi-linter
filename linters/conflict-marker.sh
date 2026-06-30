#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.conflict-marker.paths | join(" ")' $CONFIG_FILE)
for path in $(eval "find $PATHS -type f 2>/dev/null"); do
    if grep -qE '^<<<<<<< |^=======$|^>>>>>>> ' "$path" 2>/dev/null; then
        LINE=$(grep -nE '^<<<<<<< |^=======$|^>>>>>>> ' "$path" | head -1 | cut -d: -f1)
        echo "$path:$LINE:ERROR: Git conflict marker found" >> /tmp/linter.log
    fi
done || true