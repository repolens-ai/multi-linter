#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.stylelint.paths | join(" ")' $CONFIG_FILE)
AUTO_FIX=$(yq e '.linters.stylelint.auto_fix' $CONFIG_FILE)
ARGS=($PATHS)
[ "$AUTO_FIX" = "true" ] && ARGS+=("--fix")

stylelint "${ARGS[@]}" --formatter json > /tmp/stylelint.json 2>&1 || true

if [ -f /tmp/stylelint.json ]; then
    jq -r '.[] | .source as $path | .warnings[] | "\($path):\(.line):\(.severity | if . == "error" then "ERROR" else "WARNING" end): \(.text)"' /tmp/stylelint.json >> /tmp/linter.log 2>/dev/null || true
fi
