#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.commitlint.paths | join(" ")' $CONFIG_FILE)
if [ -f .commitlintrc.js ] || [ -f .commitlintrc.json ] || [ -f .commitlintrc.yaml ]; then
    npx commitlint --from HEAD~1 --to HEAD 2>&1 | while IFS= read -r line; do
        echo ".git/COMMIT_EDITMSG:1:ERROR: $line" >> /tmp/linter.log
    done || true
fi