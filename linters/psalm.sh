#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.psalm.paths | join(" ")' $CONFIG_FILE)
psalm --output-format=emacs $PATHS 2>&1 | while IFS= read -r line; do
    echo "$line" >> /tmp/linter.log
done || true