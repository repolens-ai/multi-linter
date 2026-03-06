#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.flake8.paths | join(" ")' $CONFIG_FILE)
MAX_LINE=$(yq e '.linters.flake8.max_line_length' $CONFIG_FILE)
ARGS=($PATHS)
[ "$MAX_LINE" != "null" ] && ARGS+=("--max-line-length" "$MAX_LINE")

flake8 "${ARGS[@]}" --format='%(path)s:%(row)d:ERROR: %(code)s %(text)s' >> /tmp/linter.log 2>&1 || true
