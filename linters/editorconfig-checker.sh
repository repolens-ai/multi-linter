#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.editorconfig-checker.paths | join(" ")' $CONFIG_FILE)
if command -v editorconfig-checker &>/dev/null; then
    editorconfig-checker -format gcc 2>&1 | while IFS= read -r line; do
        echo "$line" >> /tmp/linter.log
    done || true
fi