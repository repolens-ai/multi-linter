#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.rustfmt.paths | join(" ")' $CONFIG_FILE)
AUTO_FIX=$(yq e '.linters.rustfmt.auto_fix' $CONFIG_FILE)

if [ "$AUTO_FIX" = "true" ]; then
    rustfmt --edition 2021 $PATHS 2>&1 || true
else
    rustfmt --check --edition 2021 $PATHS 2>&1 | while IFS= read -r line; do
        echo "$line" >> /tmp/linter.log
    done || true
fi
