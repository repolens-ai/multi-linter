#!/bin/bash

CONFIG_FILE=$1
LINTER_NAME="linter-name"

PATHS=$(yq e ".linters.$LINTER_NAME.paths | join(\" \")" "$CONFIG_FILE" 2>/dev/null)
if [ -z "$PATHS" ] || [ "$PATHS" = "null" ]; then
    exit 0
fi

AUTO_FIX=$(yq e ".linters.$LINTER_NAME.auto_fix // false" "$CONFIG_FILE")
CONFIG_FILE_PATH=$(yq e ".linters.$LINTER_NAME.config_file // \"\"" "$CONFIG_FILE")

ARGS=()
eval "ARGS+=($PATHS)"

if [ "$AUTO_FIX" = "true" ]; then
    ARGS+=("--fix")
fi

if [ -n "$CONFIG_FILE_PATH" ] && [ "$CONFIG_FILE_PATH" != "null" ]; then
    ARGS+=("--config" "$CONFIG_FILE_PATH")
fi

# Run linter and append output to log
# Replace 'linter-command' with the actual command
linter-command "${ARGS[@]}" >> /tmp/linter.log 2>&1 || true
