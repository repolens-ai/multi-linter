#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.shellcheck.paths | join(" ")' "$CONFIG_FILE")

shellcheck --format=gcc $PATHS 2>&1 || true
