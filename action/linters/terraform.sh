#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.terraform.paths | join(" ")' $CONFIG_FILE)

terraform validate $PATHS 2>&1 | while IFS= read -r line; do
    echo "$line" >> /tmp/linter.log
done || true
