#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.terragrunt.paths | join(" ")' $CONFIG_FILE)
for dir in $PATHS; do
    if [ -f "$dir/terragrunt.hcl" ]; then
        terragrunt hclfmt --terragrunt-check --terragrunt-working-dir "$dir" 2>&1 | while IFS= read -r line; do
            echo "$dir/terragrunt.hcl:1:ERROR: $line" >> /tmp/linter.log
        done || true
    fi
done