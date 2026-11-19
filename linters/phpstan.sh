#!/bin/bash
CONFIG_FILE=$1
LEVEL=$(yq e '.linters.phpstan.level // 6' $CONFIG_FILE)
PATHS=$(yq e '.linters.phpstan.paths | join(" ")' $CONFIG_FILE)
phpstan analyse --level=$LEVEL --error-format=raw $PATHS 2>&1 | while IFS= read -r line; do
    echo "$line" >> /tmp/linter.log
done || true