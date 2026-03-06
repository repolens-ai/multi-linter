#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.shellcheck.paths | join(" ")' "$CONFIG_FILE")

# Run shellcheck - allow warnings (exit 2) but fail on errors (exit 1)
# shellcheck exit codes: 0=no issues, 1=errors, 2=warnings, 3=style
set +e
OUTPUT=$(shellcheck --format=gcc $PATHS 2>&1)
RESULT=$?
set -e

echo "$OUTPUT"

# Exit 1 only if there are actual errors (exit code 1)
# Allow warnings (exit code 2) and style notes (exit code 3)
if [ $RESULT -eq 1 ]; then
    exit 1
fi
exit 0
