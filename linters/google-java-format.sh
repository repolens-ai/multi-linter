#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.google-java-format.paths | join(" ")' $CONFIG_FILE)
for path in $(eval "find $PATHS -name '*.java' -type f 2>/dev/null"); do
    if ! google-java-format --dry-run --set-exit-if-changed "$path" 2>/dev/null; then
        echo "$path:1:WARNING: Formatting issue detected (run google-java-format)" >> /tmp/linter.log
    fi
done || true