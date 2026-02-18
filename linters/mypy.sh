#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.mypy.paths | join(" ")' $CONFIG_FILE)
mypy $PATHS --show-column-numbers --no-error-summary >> /tmp/linter.log 2>&1 || true
