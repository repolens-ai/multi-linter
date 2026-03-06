# Multi-Linter

A Docker-based, multi-language linting tool with **40+ linters** across **20+ languages**. Supports GitHub Actions and GitHub Marketplace.

## Features

- **40+ Linters** - Support for JavaScript, TypeScript, Python, Go, Rust, YAML, Shell, Docker, Java, Kotlin, Terraform, and more
- **Parallel Execution** - Run all enabled linters concurrently
- **Auto Language Detection** - Only runs linters for relevant changed files
- **GitHub Annotations** - Errors and warnings appear inline on PR files
- **Multiple Output Formats** - GitHub, JSON, JUnit, Markdown
- **Auto-fix Support** - Many linters support automatic fixes
- **GitHub Actions** - Ready-to-use action published to GitHub Marketplace
- **Docker-first** - Works locally and in any CI/CD pipeline

## Supported Languages & Linters

| Language | Linters |
|----------|---------|
| JavaScript/TypeScript | ESLint, Prettier, Stylelint, Markdownlint, TypeScript, Biome, JSONLint, HTMLHint |
| Python | Flake8, Black, MyPy, Pylint, isort, Bandit, Ruff |
| Go | golangci-lint, gofmt, govet |
| Rust | Clippy, rustfmt |
| YAML | YAML-Lint, GitHub Actions Linter Config |
| Shell | ShellCheck, shfmt |
| Docker | Hadolint |
| Java | Checkstyle |
| Kotlin | ktlint |
| Terraform | Terraform validate, TFLint |
| Cloud | CFN-Lint, Kubeconform |
| DevOps | Ansible-Lint, Actionlint |
| Ruby | RuboCop |
| Lua | Luacheck |
| LaTeX | ChkTeX |
| SQL | SQLFluff |
| XML | xmllint |
| Protocol Buffers | Protolint |
| Security | Gitleaks, Codespell, dotenv-linter |

## Quick Start

### GitHub Actions

```yaml
name: Lint

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: repolense-ai/multi-linter@v1
        with:
          config_file: config/linter-config.yaml
```

### Local Usage via Docker

```bash
# Build the Docker image
docker build -t multi-linter -f action/Dockerfile .

# Run against your current project
docker run -v $(pwd):/app -w /app multi-linter
```

## Configuration

Create a `config/linter-config.yaml` file:

```yaml
version: 1.0
fail_on_error: true
report_format: github

linters:
  eslint:
    enabled: true
    paths: ["src/**/*.ts", "src/**/*.js"]
    auto_fix: true
  prettier:
    enabled: true
    paths: ["src/**/*.ts", "src/**/*.js"]
    auto_fix: true
  flake8:
    enabled: true
    paths: ["**/*.py"]
    max_line_length: 120
  black:
    enabled: true
    paths: ["**/*.py"]
    auto_fix: true
  # ... more linters
```

## Action Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `config_file` | Path to linter config | `config/linter-config.yaml` |
| `fail_on_error` | Exit on errors | `true` |
| `report_format` | Output format | `github` |

## Publishing to GitHub Marketplace

1. Create a release with a semantic version tag (e.g., `v1.0.0`)
2. The `publish.yml` workflow will build and push the Docker image
3. Submit to GitHub Marketplace from your repository settings

## License

MIT
