#!/bin/bash
set -e

CONFIG_FILE=${CONFIG_FILE:-/tmp/config/linter-config.yaml}

# Cleanup function
cleanup() {
    rm -f /tmp/*.json /tmp/*.log 2>/dev/null || true
}
trap cleanup EXIT

# Validate config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "\033[1;31mError: Config file not found: $CONFIG_FILE\033[0m"
    exit 1
fi

# Validate yq is installed
if ! command -v yq &> /dev/null; then
    echo -e "\033[1;31mError: yq is not installed\033[0m"
    exit 1
fi

# Validate config is valid YAML
if ! yq e '.' "$CONFIG_FILE" &> /dev/null; then
    echo -e "\033[1;31mError: Invalid YAML in config file: $CONFIG_FILE\033[0m"
    exit 1
fi

echo -e "\033[1;34mStarting Multi-Linter with config: $CONFIG_FILE\033[0m"

# Timeout for each linter (default: 5 minutes)
LINTER_TIMEOUT=${LINTER_TIMEOUT:-300}

# Parse enabled linters
LINTERS=$(yq e '.linters | keys' $CONFIG_FILE -o=json)

# Auto-detect changed files if in a git repo
CHANGED_FILES=""
if [ -d .git ]; then
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
            eslint|prettier|stylelint|tsc|biome|htmlhint)
                echo "$CHANGED_FILES" | grep -E "\.(js|ts|jsx|tsx|css|scss|less|html)$" > /dev/null && SHOULD_RUN=true
                ;;
            jsonlint)
                echo "$CHANGED_FILES" | grep -E "\.json$" > /dev/null && SHOULD_RUN=true
                ;;
            markdownlint)
                echo "$CHANGED_FILES" | grep -E "\.md$" > /dev/null && SHOULD_RUN=true
                ;;
            flake8|black|mypy|pylint|isort|bandit|ruff)
                echo "$CHANGED_FILES" | grep -E "\.py$" > /dev/null && SHOULD_RUN=true
                ;;
            golangci-lint|gofmt|govet)
                echo "$CHANGED_FILES" | grep -E "\.go$" > /dev/null && SHOULD_RUN=true
                ;;
            clippy|rustfmt)
                echo "$CHANGED_FILES" | grep -E "\.rs$" > /dev/null && SHOULD_RUN=true
                ;;
            yamllint|github-linter)
                echo "$CHANGED_FILES" | grep -E "\.(yml|yaml)$" > /dev/null && SHOULD_RUN=true
                ;;
            shellcheck|shfmt)
                echo "$CHANGED_FILES" | grep -E "\.sh$" > /dev/null && SHOULD_RUN=true
                ;;
            hadolint)
                echo "$CHANGED_FILES" | grep -i "Dockerfile" > /dev/null && SHOULD_RUN=true
                ;;
            checkstyle)
                echo "$CHANGED_FILES" | grep -E "\.java$" > /dev/null && SHOULD_RUN=true
                ;;
            ktlint)
                echo "$CHANGED_FILES" | grep -E "\.kt$" > /dev/null && SHOULD_RUN=true
                ;;
            terraform|tflint)
                echo "$CHANGED_FILES" | grep -E "\.tf$" > /dev/null && SHOULD_RUN=true
                ;;
            cfn-lint)
                echo "$CHANGED_FILES" | grep -E "cloudformation.*\.(yml|yaml)$" > /dev/null && SHOULD_RUN=true
                ;;
            kubeconform)
                echo "$CHANGED_FILES" | grep -E "\.yaml$" > /dev/null && SHOULD_RUN=true
                ;;
            ansible-lint)
                echo "$CHANGED_FILES" | grep -E "\.(yml|yaml)$" > /dev/null && SHOULD_RUN=true
                ;;
            actionlint)
                echo "$CHANGED_FILES" | grep -E "\.github/workflows/.*\.(yml|yaml)$" > /dev/null && SHOULD_RUN=true
                ;;
            rubocop)
                echo "$CHANGED_FILES" | grep -E "\.rb$" > /dev/null && SHOULD_RUN=true
                ;;
            luacheck)
                echo "$CHANGED_FILES" | grep -E "\.lua$" > /dev/null && SHOULD_RUN=true
                ;;
            chktex)
                echo "$CHANGED_FILES" | grep -E "\.tex$" > /dev/null && SHOULD_RUN=true
                ;;
            sqlfluff)
                echo "$CHANGED_FILES" | grep -E "\.sql$" > /dev/null && SHOULD_RUN=true
                ;;
            dotenv-linter)
                echo "$CHANGED_FILES" | grep -E "^\.env" > /dev/null && SHOULD_RUN=true
                ;;
            gitleaks)
                SHOULD_RUN=true
                ;;
            codespell)
                echo "$CHANGED_FILES" | grep -E "\.(md|txt)$" > /dev/null && SHOULD_RUN=true
                ;;
            xmllint)
                echo "$CHANGED_FILES" | grep -E "\.xml$" > /dev/null && SHOULD_RUN=true
                ;;
            protolint)
                echo "$CHANGED_FILES" | grep -E "\.proto$" > /dev/null && SHOULD_RUN=true
                ;;
            *)
                SHOULD_RUN=true
                ;;
        esac

        if [ "$SHOULD_RUN" = "true" ]; then
            if [ ! -f "/usr/local/bin/$linter.sh" ]; then
                echo -e "\033[1;33mWarning: Linter script not found: $linter.sh, skipping.\033[0m"
                continue
            fi
            echo -e "\033[1;32mRunning $linter (timeout: ${LINTER_TIMEOUT}s)...\033[0m"
            timeout $LINTER_TIMEOUT /usr/local/bin/$linter.sh "$CONFIG_FILE" &
        else
            echo "No relevant files for $linter, skipping."
        fi
    else
        echo "$linter is disabled, skipping."
    fi
done

wait

# Check for linter timeouts or failures
FAILED_LINTERS=0
for job in $(jobs -p); do
    if wait $job; then
        :
    else
        FAILED_LINTERS=$((FAILED_LINTERS + 1))
        echo -e "\033[1;33mWarning: A linter failed or timed out\033[0m"
    fi
done

# Aggregate and report results
/usr/local/bin/reporter.sh "$CONFIG_FILE"

echo -e "\033[1;34mLinting complete.\033[0m"

# Exit with error if any linter failed
if [ $FAILED_LINTERS -gt 0 ]; then
    echo -e "\033[1;31mWarning: $FAILED_LINTERS linter(s) failed\033[0m"
fi
