#!/bin/bash

MERGED_CONFIG=""

linter_to_validate_var() {
    local linter="$1"
    case "$linter" in
        eslint)              echo "VALIDATE_JAVASCRIPT_ES" ;;
        prettier)            echo "VALIDATE_CSS" ;;
        stylelint)           echo "VALIDATE_CSS" ;;
        markdownlint)        echo "VALIDATE_MARKDOWN" ;;
        tsc)                 echo "VALIDATE_TYPESCRIPT_ES" ;;
        biome)               echo "VALIDATE_JAVASCRIPT_ES" ;;
        jsonlint)            echo "VALIDATE_JSON" ;;
        htmlhint)            echo "VALIDATE_HTML" ;;
        flake8|black|mypy|pylint|isort|bandit|ruff)
                             echo "VALIDATE_PYTHON" ;;
        golangci-lint|gofmt|govet)
                             echo "VALIDATE_GO" ;;
        clippy|rustfmt)      echo "VALIDATE_RUST" ;;
        yamllint)            echo "VALIDATE_YAML" ;;
        github-linter)       echo "VALIDATE_YAML" ;;
        shellcheck|shfmt)    echo "VALIDATE_SHELL" ;;
        hadolint)            echo "VALIDATE_DOCKER" ;;
        checkstyle|google-java-format)
                             echo "VALIDATE_JAVA" ;;
        ktlint)              echo "VALIDATE_KOTLIN" ;;
        terraform|tflint)    echo "VALIDATE_TERRAFORM" ;;
        cfn-lint)            echo "VALIDATE_CLOUDFORMATION" ;;
        kubeconform)         echo "VALIDATE_KUBERNETES" ;;
        ansible-lint)        echo "VALIDATE_ANSIBLE" ;;
        actionlint|zizmor)   echo "VALIDATE_GITHUB_ACTIONS" ;;
        rubocop)             echo "VALIDATE_RUBY" ;;
        luacheck)            echo "VALIDATE_LUA" ;;
        chktex)              echo "VALIDATE_LATEX" ;;
        sqlfluff)            echo "VALIDATE_SQL" ;;
        dotenv-linter)       echo "VALIDATE_DOTENV" ;;
        gitleaks)            echo "VALIDATE_GITLEAKS" ;;
        codespell)           echo "VALIDATE_CODESPELL" ;;
        xmllint)             echo "VALIDATE_XML" ;;
        protolint)           echo "VALIDATE_PROTO" ;;
        commitlint)          echo "VALIDATE_COMMITLINT" ;;
        editorconfig-checker)
                             echo "VALIDATE_EDITORCONFIG" ;;
        goreleaser)          echo "VALIDATE_GOREELEASER" ;;
        spectral)            echo "VALIDATE_OPENAPI" ;;
        textlint)            echo "VALIDATE_TEXT" ;;
        checkov)             echo "VALIDATE_CHECKOV" ;;
        trivy)               echo "VALIDATE_TRIVY" ;;
        jscpd)               echo "VALIDATE_JSCPD" ;;
        cpplint|clang-format)
                             echo "VALIDATE_CPP" ;;
        terragrunt)          echo "VALIDATE_TERRAGRUNT" ;;
        renovate-config-validator)
                             echo "VALIDATE_RENOVATE" ;;
        php-lint|phpcs|phpstan|psalm)
                             echo "VALIDATE_PHP" ;;
        perlcritic)          echo "VALIDATE_PERL" ;;
        lintr)               echo "VALIDATE_R" ;;
        scalafmt)            echo "VALIDATE_SCALA" ;;
        dotnet-format)       echo "VALIDATE_CSHARP" ;;
        dart-analyze)        echo "VALIDATE_DART" ;;
        clj-kondo)           echo "VALIDATE_CLOJURE" ;;
        coffeelint)          echo "VALIDATE_COFFEE" ;;
        npm-groovy-lint)     echo "VALIDATE_GROOVY" ;;
        psscriptanalyzer)    echo "VALIDATE_POWERSHELL" ;;
        snakemake-lint|snakefmt)
                             echo "VALIDATE_SNAKEMAKE" ;;
        conflict-marker)     echo "" ;;
        asl-validator)       echo "VALIDATE_ASL" ;;
        arm-ttk)             echo "VALIDATE_ARM" ;;
        pre-commit)          echo "VALIDATE_PRE_COMMIT" ;;
        *)                   echo "" ;;
    esac
}

linter_to_fix_var() {
    local linter="$1"
    case "$linter" in
        eslint)              echo "FIX_JAVASCRIPT_ES" ;;
        prettier)            echo "FIX_CSS" ;;
        stylelint)           echo "FIX_CSS" ;;
        black|isort|ruff)    echo "FIX_PYTHON" ;;
        gofmt)               echo "FIX_GO" ;;
        rustfmt)             echo "FIX_RUST" ;;
        shfmt)               echo "FIX_SHELL" ;;
        rubocop)             echo "FIX_RUBY" ;;
        ktlint)              echo "FIX_KOTLIN" ;;
        snakefmt)            echo "FIX_SNAKEMAKE" ;;
        clang-format)        echo "FIX_CPP" ;;
        dotnet-format)       echo "FIX_CSHARP" ;;
        google-java-format)  echo "FIX_JAVA" ;;
        scalafmt)            echo "FIX_SCALA" ;;
        phpcs)               echo "FIX_PHP" ;;
        biome)               echo "FIX_JAVASCRIPT_ES" ;;
        *)                   echo "" ;;
    esac
}

linter_to_config_file_var() {
    local linter="$1"
    local upper
    upper=$(echo "$linter" | tr '[:lower:]-.' '[:upper:]__')
    echo "${upper}_CONFIG_FILE"
}

linter_to_file_name_var() {
    local linter="$1"
    local upper
    upper=$(echo "$linter" | tr '[:lower:]-.' '[:upper:]__')
    echo "${upper}_FILE_NAME"
}

detect_validate_mode() {
    local any_true=false
    local any_false=false

    while IFS='=' read -r var val; do
        if [[ "$var" == VALIDATE_* ]]; then
            if [ "$val" = "true" ]; then
                any_true=true
            elif [ "$val" = "false" ]; then
                any_false=true
            fi
        fi
    done < <(env)

    if [ "$any_true" = "true" ] && [ "$any_false" != "true" ]; then
        echo "opt-in"
    elif [ "$any_false" = "true" ] && [ "$any_true" != "true" ]; then
        echo "opt-out"
    else
        echo "mixed"
    fi
}

get_validate_var_value() {
    local var_name="$1"
    local val
    val=$(env | grep -E "^${var_name}=" | head -1 | cut -d= -f2-)
    echo "$val"
}

resolve_linter_enabled() {
    local linter="$1"
    local config_file="$2"
    local validate_var
    validate_var=$(linter_to_validate_var "$linter")

    if [ -n "$validate_var" ]; then
        local env_val
        env_val=$(get_validate_var_value "$validate_var")
        if [ "$env_val" = "true" ]; then
            echo "true"
            return 0
        elif [ "$env_val" = "false" ]; then
            echo "false"
            return 0
        fi
    fi

    local mode
    mode=$(detect_validate_mode)
    if [ "$mode" = "opt-in" ]; then
        local default
        default=$(yq e ".linters.\"$linter\".enabled // false" "$config_file")
        local has_env
        if [ -n "$validate_var" ]; then
            has_env=$(env | grep -E "^${validate_var}=" | head -1 || echo "")
        else
            has_env=""
        fi
        if [ -z "$has_env" ]; then
            echo "false"
            return 0
        fi
        echo "$default"
    elif [ "$mode" = "opt-out" ]; then
        local default
        default=$(yq e ".linters.\"$linter\".enabled // false" "$config_file")
        local has_env
        if [ -n "$validate_var" ]; then
            has_env=$(env | grep -E "^${validate_var}=" | head -1 || echo "")
        else
            has_env=""
        fi
        if [ -z "$has_env" ]; then
            echo "$default"
            return 0
        fi
        local env_val
        env_val=$(get_validate_var_value "$validate_var")
        if [ "$env_val" = "false" ]; then
            echo "false"
            return 0
        fi
        echo "$default"
    else
        yq e ".linters.\"$linter\".enabled // false" "$config_file"
    fi
}

resolve_linter_config_file() {
    local linter="$1"
    local config_file_var
    config_file_var=$(linter_to_config_file_var "$linter")
    local val
    val=$(get_validate_var_value "$config_file_var")
    if [ -n "$val" ]; then
        echo "$val"
        return 0
    fi

    local file_name_var
    file_name_var=$(linter_to_file_name_var "$linter")
    val=$(get_validate_var_value "$file_name_var")
    if [ -n "$val" ]; then
        echo "$val"
        return 0
    fi

    echo ""
}

resolve_linter_auto_fix() {
    local linter="$1"
    local config_file="$2"
    local fix_var
    fix_var=$(linter_to_fix_var "$linter")

    if [ -n "$fix_var" ]; then
        local env_val
        env_val=$(get_validate_var_value "$fix_var")
        if [ "$env_val" = "true" ]; then
            echo "true"
            return 0
        elif [ "$env_val" = "false" ]; then
            echo "false"
            return 0
        fi
    fi

    yq e ".linters.\"$linter\".auto_fix // false" "$config_file"
}

apply_env_overrides() {
    local input_config="$1"
    local output_config="${2:-/tmp/merged-config.yaml}"

    if [ ! -f "$input_config" ]; then
        echo "ERROR: Config file not found: $input_config" >&2
        return 1
    fi

    cp "$input_config" "$output_config"

    if [ -n "${FAIL_ON_ERROR:-}" ]; then
        yq e -i ".fail_on_error = (\"$FAIL_ON_ERROR\" == \"true\")" "$output_config"
    fi
    if [ -n "${REPORT_FORMAT:-}" ]; then
        yq e -i ".report_format = \"$REPORT_FORMAT\"" "$output_config"
    fi
    if [ -n "${DISABLE_ERRORS:-}" ] && [ "$DISABLE_ERRORS" = "true" ]; then
        yq e -i ".fail_on_error = false" "$output_config"
    fi

    local linters
    linters=$(yq e '.linters | keys | .[]' "$input_config" 2>/dev/null || echo "")
    if [ -z "$linters" ]; then
        echo "$output_config"
        return 0
    fi

    local mode
    mode=$(detect_validate_mode)

    while IFS= read -r linter; do
        [ -z "$linter" ] && continue

        local validate_var
        validate_var=$(linter_to_validate_var "$linter")

        if [ -n "$validate_var" ]; then
            local env_val
            env_val=$(get_validate_var_value "$validate_var")
            if [ "$env_val" = "true" ]; then
                yq e -i ".linters.\"$linter\".enabled = true" "$output_config"
            elif [ "$env_val" = "false" ]; then
                yq e -i ".linters.\"$linter\".enabled = false" "$output_config"
            elif [ "$mode" = "opt-in" ]; then
                yq e -i ".linters.\"$linter\".enabled = false" "$output_config"
            fi
        elif [ "$mode" = "opt-in" ]; then
            local config_enabled
            config_enabled=$(yq e ".linters.\"$linter\".enabled // false" "$input_config")
            if [ "$config_enabled" != "true" ]; then
                yq e -i ".linters.\"$linter\".enabled = false" "$output_config"
            fi
        fi

        local config_file_var
        config_file_var=$(linter_to_config_file_var "$linter")
        local cf_val
        cf_val=$(get_validate_var_value "$config_file_var")
        if [ -z "$cf_val" ]; then
            local file_name_var
            file_name_var=$(linter_to_file_name_var "$linter")
            cf_val=$(get_validate_var_value "$file_name_var")
        fi
        if [ -n "$cf_val" ]; then
            yq e -i ".linters.\"$linter\".config_file = \"$cf_val\"" "$output_config"
        fi

        local fix_var
        fix_var=$(linter_to_fix_var "$linter")
        if [ -n "$fix_var" ]; then
            local fix_val
            fix_val=$(get_validate_var_value "$fix_var")
            if [ "$fix_val" = "true" ]; then
                yq e -i ".linters.\"$linter\".auto_fix = true" "$output_config"
            elif [ "$fix_val" = "false" ]; then
                yq e -i ".linters.\"$linter\".auto_fix = false" "$output_config"
            fi
        fi
    done <<< "$linters"

    MERGED_CONFIG="$output_config"
    echo "$output_config"
}
