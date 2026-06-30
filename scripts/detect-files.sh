#!/bin/bash

detect_changed_files() {
    if [ -d .git ]; then
        git diff --name-only HEAD~1 HEAD 2>/dev/null || git ls-files
    else
        find . -type f -not -path '*/.*'
    fi
}

should_run_linter() {
    local linter=$1
    local changed_files=$2

    case $linter in
        eslint|prettier|stylelint|tsc|biome|htmlhint)
            echo "$changed_files" | grep -qE "\.(js|ts|jsx|tsx|css|scss|less|html)$" && return 0
            ;;
        jsonlint)
            echo "$changed_files" | grep -qE "\.json$" && return 0
            ;;
        markdownlint)
            echo "$changed_files" | grep -qE "\.md$" && return 0
            ;;
        flake8|black|mypy|pylint|isort|bandit|ruff)
            echo "$changed_files" | grep -qE "\.py$" && return 0
            ;;
        golangci-lint|gofmt|govet)
            echo "$changed_files" | grep -qE "\.go$" && return 0
            ;;
        clippy|rustfmt)
            echo "$changed_files" | grep -qE "\.rs$" && return 0
            ;;
        yamllint|github-linter)
            echo "$changed_files" | grep -qE "\.(yml|yaml)$" && return 0
            ;;
        shellcheck|shfmt)
            echo "$changed_files" | grep -qE "\.sh$" && return 0
            ;;
        hadolint)
            echo "$changed_files" | grep -qi "Dockerfile" && return 0
            ;;
        checkstyle)
            echo "$changed_files" | grep -qE "\.java$" && return 0
            ;;
        ktlint)
            echo "$changed_files" | grep -qE "\.kt$" && return 0
            ;;
        terraform|tflint)
            echo "$changed_files" | grep -qE "\.tf$" && return 0
            ;;
        cfn-lint)
            echo "$changed_files" | grep -qE "cloudformation.*\.(yml|yaml)$" && return 0
            ;;
        kubeconform|ansible-lint)
            echo "$changed_files" | grep -qE "\.yaml$" && return 0
            ;;
        actionlint)
            echo "$changed_files" | grep -qE "\.github/workflows/.*\.(yml|yaml)$" && return 0
            ;;
        rubocop)
            echo "$changed_files" | grep -qE "\.rb$" && return 0
            ;;
        luacheck)
            echo "$changed_files" | grep -qE "\.lua$" && return 0
            ;;
        chktex)
            echo "$changed_files" | grep -qE "\.tex$" && return 0
            ;;
        sqlfluff)
            echo "$changed_files" | grep -qE "\.sql$" && return 0
            ;;
        dotenv-linter)
            echo "$changed_files" | grep -qE "^\.env" && return 0
            ;;
        gitleaks)
            return 0
            ;;
        codespell)
            echo "$changed_files" | grep -qE "\.(md|txt)$" && return 0
            ;;
        xmllint)
            echo "$changed_files" | grep -qE "\.xml$" && return 0
            ;;
        protolint)
            echo "$changed_files" | grep -qE "\.proto$" && return 0
            ;;
        goreleaser)
            echo "$changed_files" | grep -qE "\.goreleaser\.(yml|yaml)$" && return 0
            ;;
        commitlint)
            echo "$changed_files" | grep -qE "^COMMIT_EDITMSG|\.git/" && return 0
            ;;
        editorconfig-checker)
            echo "$changed_files" | grep -qE "\.editorconfig" && return 0
            ;;
        spectral)
            echo "$changed_files" | grep -qE "\.(yaml|yml|json)$" && echo "$changed_files" | grep -qE "(openapi|swagger|asyncapi|api)" && return 0
            ;;
        textlint)
            echo "$changed_files" | grep -qE "\.(md|txt|rst|adoc)$" && return 0
            ;;
        checkov)
            echo "$changed_files" | grep -qE "\.(tf|yaml|yml|json)$" && return 0
            ;;
        trivy)
            return 0
            ;;
        jscpd)
            return 0
            ;;
        cpplint|clang-format)
            echo "$changed_files" | grep -qE "\.(c|cpp|cxx|cc|h|hpp|hxx)$" && return 0
            ;;
        terragrunt)
            echo "$changed_files" | grep -qE "terragrunt\.hcl$" && return 0
            ;;
        renovate-config-validator)
            echo "$changed_files" | grep -qE "renovate\.(json|json5)$" && return 0
            ;;
        php-lint|phpcs|phpstan|psalm)
            echo "$changed_files" | grep -qE "\.php$" && return 0
            ;;
        perlcritic)
            echo "$changed_files" | grep -qE "\.(pl|pm|t)$" && return 0
            ;;
        lintr)
            echo "$changed_files" | grep -qE "\.(r|R)$" && return 0
            ;;
        scalafmt)
            echo "$changed_files" | grep -qE "\.scala$" && return 0
            ;;
        dotnet-format)
            echo "$changed_files" | grep -qE "\.(cs|sln|csproj)$" && return 0
            ;;
        dart-analyze)
            echo "$changed_files" | grep -qE "\.dart$" && return 0
            ;;
        clj-kondo)
            echo "$changed_files" | grep -qE "\.(clj|cljs|cljc|edn)$" && return 0
            ;;
        coffeelint)
            echo "$changed_files" | grep -qE "\.coffee$" && return 0
            ;;
        zizmor)
            echo "$changed_files" | grep -qE "\.github/workflows/.*\.(yml|yaml)$" && return 0
            ;;
        npm-groovy-lint)
            echo "$changed_files" | grep -qE "\.(groovy|gvy|gsh)$" && return 0
            ;;
        google-java-format)
            echo "$changed_files" | grep -qE "\.java$" && return 0
            ;;
        psscriptanalyzer)
            echo "$changed_files" | grep -qE "\.(ps1|psm1|psd1)$" && return 0
            ;;
        snakemake-lint|snakefmt)
            echo "$changed_files" | grep -qE "(Snakefile|\.smk)$" && return 0
            ;;
        conflict-marker)
            return 0
            ;;
        asl-validator)
            echo "$changed_files" | grep -qE "\.asl\.json$" && return 0
            ;;
        arm-ttk)
            echo "$changed_files" | grep -qE "\.json$" && echo "$changed_files" | grep -qE "(azuredeploy|arm)" && return 0
            ;;
        pre-commit)
            echo "$changed_files" | grep -qE "\.pre-commit-config\.(yaml|yml)$" && return 0
            ;;
        *)
            return 0
            ;;
    esac
    return 1
}
