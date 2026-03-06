#!/bin/bash
CONFIG_FILE=$1
FORMAT=$(yq e '.report_format' $CONFIG_FILE)

echo -e "\033[1;34mAggregating linter results...\033[0m"

# Parse /tmp/linter.log for errors/warnings and provide annotations
if [ -f /tmp/linter.log ]; then
    if [ "$FORMAT" = "github" ]; then
        grep -E "^[^:]+:[0-9]+:.*" /tmp/linter.log | while read -r line; do
            FILE=$(echo "$line" | cut -d: -f1)
            LINE_NO=$(echo "$line" | cut -d: -f2)
            MESSAGE=$(echo "$line" | cut -d: -f3-)
            
            if echo "$MESSAGE" | grep -iq "error"; then
                echo "::error file=${FILE},line=${LINE_NO}::${MESSAGE}"
            else
                echo "::warning file=${FILE},line=${LINE_NO}::${MESSAGE}"
            fi
        done
        echo "::notice ::Multi-Linter finished. Check linter logs above."
    elif [ "$FORMAT" = "json" ]; then
        echo "{ \"result\": \"Linting complete\" }"
    elif [ "$FORMAT" = "junit" ]; then
        echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        echo "<testsuites name=\"Multi-Linter\">"
        echo "  <testsuite name=\"Linting\">"
        grep -E "^[^:]+:[0-9]+:.*" /tmp/linter.log | while read -r line; do
            FILE=$(echo "$line" | cut -d: -f1)
            LINE=$(echo "$line" | cut -d: -f2)
            MSG=$(echo "$line" | cut -d: -f3-)
            echo "    <testcase name=\"$FILE\" classname=\"$FILE\">"
            echo "      <failure message=\"Line $LINE: $MSG\" type=\"LintError\"/>"
            echo "    </testcase>"
        done
        echo "  </testsuite>"
        echo "</testsuites>"
    fi
fi

FAIL_ON_ERROR=$(yq e '.fail_on_error' $CONFIG_FILE)
EXIT_CODE=0

if [ -f /tmp/linter.log ]; then
    if grep -iq "error" /tmp/linter.log; then
        if [ "$FAIL_ON_ERROR" = "true" ]; then
            echo -e "\033[1;31mFail on error enabled. Errors found.\033[0m"
            EXIT_CODE=1
        fi
    fi

    # Check for warnings if fail_on_warning is globally or specifically enabled
    # Here we check if any linter has fail_on_warning: true and has warnings
    # For simplicity, if ANY warning exists and any linter has it enabled, we might fail.
    # But better logic: check if linter-config.yaml has any fail_on_warning: true
    HAS_FAIL_ON_WARNING=$(yq e '.linters[].fail_on_warning' $CONFIG_FILE | grep -q "true" && echo "true" || echo "false")
    if [ "$HAS_FAIL_ON_WARNING" = "true" ] && grep -iq "warning" /tmp/linter.log; then
         echo -e "\033[1;33mFail on warning enabled. Warnings found.\033[0m"
         EXIT_CODE=1
    fi
fi

exit $EXIT_CODE
