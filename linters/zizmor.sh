#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.zizmor.paths | join(" ")' $CONFIG_FILE)
zizmor $PATHS --format json 2>/dev/null | jq -r '.[]? | .file + ":" + (.line|tostring) + ":ERROR: " + .message' >> /tmp/linter.log 2>/dev/null || true