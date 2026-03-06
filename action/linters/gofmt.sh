#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.gofmt.paths | join(" ")' $CONFIG_FILE)
AUTO_FIX=$(yq e '.linters.gofmt.auto_fix' $CONFIG_FILE)

if [ "$AUTO_FIX" = "true" ]; then
    gofmt -w $PATHS 2>&1 || true
else
    gofmt -l $PATHS 2>&1 | while IFS= read -r line; do
        echo "$line:1:ERROR: File is not gofmted" >> /tmp/linter.log
    done || true
fi
