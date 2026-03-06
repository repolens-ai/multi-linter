#!/bin/bash
set -e

CONFIG_FILE=${1:-config/linter-config.yaml}

LINTER_NAME="shfmt"
CONFIG_PATH=$($YQ_PATH e ".linters.$LINTER_NAME.paths[0]" "$CONFIG_FILE" 2>/dev/null || echo "**/*.sh")
AUTO_FIX=$($YQ_PATH e ".linters.$LINTER_NAME.auto_fix" "$CONFIG_FILE" 2>/dev/null || echo "false")

if command -v shfmt &> /dev/null; then
    echo "Running shfmt..."
    if [ "$AUTO_FIX" = "true" ]; then
        shfmt -w $CONFIG_PATH
    else
        shfmt -d $CONFIG_PATH
    fi
else
    echo "shfmt not found, skipping"
fi
