#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.dart-analyze.paths | join(" ")' $CONFIG_FILE)
for dir in $PATHS; do
    if [ -f "$dir/pubspec.yaml" ] || [ -f "$dir/pubspec.yml" ]; then
        dart analyze "$dir" --fatal-infos 2>&1 | while IFS= read -r line; do
            if echo "$line" | grep -qE "^[^:]+:[0-9]+:[0-9]+:"; then
                echo "$line" >> /tmp/linter.log
            fi
        done || true
    fi
done