#!/bin/bash
set -e

CONFIG_FILE=${CONFIG_FILE:-/tmp/config/linter-config.yaml}
echo -e "\033[1;34mStarting Multi-Linter with config: $CONFIG_FILE\033[0m"

# Parse enabled linters
LINTERS=$(yq e '.linters | keys' $CONFIG_FILE -o=json)

# Auto-detect changed files if in a git repo
CHANGED_FILES=""
if [ -d .git ]; then
    # Try to get changed files against main or previous commit
    CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD 2>/dev/null || git ls-files)
else
    CHANGED_FILES=$(find . -type f -not -path '*/.*')
fi

# Run all enabled linters in parallel
for linter in $(echo $LINTERS | jq -r '.[]'); do
    ENABLED=$(yq e ".linters.$linter.enabled" $CONFIG_FILE)
    if [ "$ENABLED" = "true" ]; then
        
        # Auto Language Detection
        SHOULD_RUN=false
        case $linter in
            eslint|prettier)
                echo "$CHANGED_FILES" | grep -E "\.(js|ts|jsx|tsx)$" > /dev/null && SHOULD_RUN=true
                ;;
            flake8|black|mypy)
                echo "$CHANGED_FILES" | grep -E "\.py$" > /dev/null && SHOULD_RUN=true
                ;;
            golangci-lint)
                echo "$CHANGED_FILES" | grep -E "\.go$" > /dev/null && SHOULD_RUN=true
                ;;
            clippy)
                echo "$CHANGED_FILES" | grep -E "\.rs$" > /dev/null && SHOULD_RUN=true
                ;;
            yamllint)
                echo "$CHANGED_FILES" | grep -E "\.(yml|yaml)$" > /dev/null && SHOULD_RUN=true
                ;;
            *)
                SHOULD_RUN=true
                ;;
        esac

        if [ "$SHOULD_RUN" = "true" ]; then
            echo -e "\033[1;32mRunning $linter...\033[0m"
            /usr/local/bin/$linter.sh "$CONFIG_FILE" &
        else
            echo "No relevant files for $linter, skipping."
        fi
    else
        echo "$linter is disabled, skipping."
    fi
done

wait  # Wait for all background jobs to finish

# Aggregate and report results
/usr/local/bin/reporter.sh "$CONFIG_FILE"

echo -e "\033[1;34mLinting complete.\033[0m"
