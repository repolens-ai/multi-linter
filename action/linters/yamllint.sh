#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.yamllint.paths | join(" ")' $CONFIG_FILE)
CONF=$(yq e '.linters.yamllint.config_file' $CONFIG_FILE)
ARGS=("-f" "parsable")
[ "$CONF" != "null" ] && ARGS+=("-c" "$CONF")
ARGS+=($PATHS)

yamllint "${ARGS[@]}" >> /tmp/linter.log 2>&1 || true
