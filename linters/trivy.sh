#!/bin/bash
CONFIG_FILE=$1
SCAN_TYPE=$(yq e '.linters.trivy.scan_type // "config"' $CONFIG_FILE)
trivy $SCAN_TYPE --format json --quiet . 2>/dev/null | jq -r '.Results[]? | .Target as $target | .Misconfigurations[]? | $target + ":" + (.CauseMetadata.StartLine|tostring) + ":ERROR: " + .AVDID + " " + .Title' >> /tmp/linter.log 2>/dev/null || true