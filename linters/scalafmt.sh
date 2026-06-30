#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.scalafmt.paths | join(" ")' $CONFIG_FILE)
scalafmt --test $PATHS 2>&1 | while IFS= read -r line; do
    if echo "$line" | grep -qiE "error|invalid|diff"; then
        echo "$line" >> /tmp/linter.log
    fi
done || true