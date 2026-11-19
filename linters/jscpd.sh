#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.jscpd.paths | join(" ")' $CONFIG_FILE)
THRESHOLD=$(yq e '.linters.jscpd.threshold // 50' $CONFIG_FILE)
jscpd --output /tmp/jscpd-report --min-lines 5 --threshold $THRESHOLD --format json $PATHS 2>/dev/null || true
if [ -f /tmp/jscpd-report/jscpd-report.json ]; then
    jq -r '.duplications[]? | .firstFile.name + ":" + (.firstFile.startLine|tostring) + ":WARNING: Duplicate found in " + .secondFile.name + " lines " + (.secondFile.startLine|tostring) + "-" + (.secondFile.endLine|tostring)' /tmp/jscpd-report/jscpd-report.json >> /tmp/linter.log 2>/dev/null || true
fi