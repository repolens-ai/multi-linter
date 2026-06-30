#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.php-lint.paths | join(" ")' $CONFIG_FILE)
for path in $(eval "find $PATHS -name '*.php' -type f 2>/dev/null"); do
    php -l "$path" 2>&1 | while IFS= read -r line; do
        if echo "$line" | grep -qiE "error|Parse|Fatal"; then
            echo "$path:1:ERROR: $line" >> /tmp/linter.log
        fi
    done || true
done