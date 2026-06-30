#!/bin/bash
CONFIG_FILE=$1
PATHS=$(yq e '.linters.arm-ttk.paths | join(" ")' $CONFIG_FILE)
for path in $(eval "find $PATHS -name '*.json' -type f 2>/dev/null"); do
    if grep -q '"$schema".*https://schema.management.azure.com' "$path" 2>/dev/null; then
        pwsh -Command "Import-Module ArmTemplateTester; Test-AzTemplate -TemplatePath '$path' -Format" 2>&1 | while IFS= read -r line; do
            if echo "$line" | grep -qE "^[^:]+:[0-9]+:"; then
                echo "$line" >> /tmp/linter.log
            fi
        done || true
    fi
done