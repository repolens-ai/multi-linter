#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.clj-kondo.paths | join(" ")' $CONFIG_FILE)
clj-kondo --lint $PATHS --config-dir .clj-kondo 2>&1 | while IFS= read -r line; do
    echo "$line" >> /tmp/linter.log
done || true