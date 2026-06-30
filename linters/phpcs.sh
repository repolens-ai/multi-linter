#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.phpcs.paths | join(" ")' $CONFIG_FILE)
STANDARD=$(yq e '.linters.phpcs.standard // "PSR12"' $CONFIG_FILE)
phpcs --standard=$STANDARD --report=emacs $PATHS 2>&1 | while IFS= read -r line; do
    echo "$line" >> /tmp/linter.log
done || true