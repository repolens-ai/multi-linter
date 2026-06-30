#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.textlint.paths | join(" ")' $CONFIG_FILE)
if [ -f .textlintrc ] || [ -f .textlintrc.json ] || [ -f .textlintrc.js ]; then
    npx textlint "$PATHS" -f json 2>/dev/null | jq -r '.[] | .filePath + ":" + (.messages[] | .line|tostring) + ":WARNING: " + .message' >> /tmp/linter.log 2>/dev/null || true
fi