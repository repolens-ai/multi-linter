#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.checkstyle.paths | join(" ")' $CONFIG_FILE)

if [ -f /tmp/config/google_checks.xml ]; then
    java -jar /usr/local/bin/checkstyle.jar -c /tmp/config/google_checks.xml $PATHS 2>&1 | while IFS= read -r line; do
        if echo "$line" | grep -E "^[^:]+:[0-9]+:" > /dev/null; then
            echo "$line" >> /tmp/linter.log
        fi
    done || true
else
    echo "checkstyle: Config file not found, skipping" >> /tmp/linter.log
fi
