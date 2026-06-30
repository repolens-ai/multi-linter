#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.snakemake-lint.paths | join(" ")' $CONFIG_FILE)
for path in $(eval "find $PATHS -name 'Snakefile' -o -name '*.smk' -type f 2>/dev/null"); do
    snakemake --lint --snakefile "$path" 2>&1 | while IFS= read -r line; do
        if echo "$line" | grep -qiE "warning|error|hint"; then
            echo "$path:1:WARNING: $line" >> /tmp/linter.log
        fi
    done || true
done