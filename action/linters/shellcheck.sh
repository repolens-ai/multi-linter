#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.shellcheck.paths[0]' "$CONFIG_FILE")

# Exclude this script itself and reporter.sh from checking
shellcheck --format=gcc \
    --exclude=SC2034 \
    --exclude=SC2086 \
    --exclude=SC2206 \
    "$PATHS" 2>&1 || true
