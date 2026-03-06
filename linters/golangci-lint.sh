#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.golangci-lint.paths | join(" ")' $CONFIG_FILE)
CONF=$(yq e '.linters.golangci-lint.config_file' $CONFIG_FILE)
ARGS=("run" "--out-format" "line-number")
[ "$CONF" != "null" ] && ARGS+=("-c" "$CONF")
ARGS+=($PATHS)

golangci-lint "${ARGS[@]}" >> /tmp/linter.log 2>&1 || true
