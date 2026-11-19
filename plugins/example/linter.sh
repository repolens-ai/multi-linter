#!/bin/bash

CONFIG_FILE=$1

echo "Example plugin: checking for .example files..."

find . -name "*.example" -type f 2>/dev/null | while read -r file; do
    if grep -qi "TODO\|FIXME\|HACK" "$file" 2>/dev/null; then
        echo "$file:1:WARNING: Found TODO/FIXME/HACK in example file"
    fi
done >> /tmp/linter.log

echo "Example plugin complete."
