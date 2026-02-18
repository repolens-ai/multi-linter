# Multi-Linter — Pro Edition

A unified, multi-language linter with Pro Features for CI/CD and local development. Supports JS/TS, Python, Go, Rust, YAML, and more, with DSL-driven configuration, parallel execution, GitHub annotations, pre-commit integration, and smart reporting.

## 🚀 Features

### Core Features
*   **Multi-language support**: JS/TS, Python, Go, Rust, YAML.
*   **Docker-first architecture**: Works locally and in CI/CD pipelines.
*   **DSL configuration**: Enable/disable linters, set paths, configure rules in a single YAML file.
*   **Standardized logging**: Unified format for all linter outputs.

### Pro Features
*   **Parallel Linter Execution** — Run all enabled linters concurrently to reduce CI runtime.
*   **Auto Language Detection** — Only runs linters for relevant changed files.
*   **Pro Reporting & GitHub Annotations** — PR annotations, JSON output, and JUnit XML for dashboards.
*   **Advanced Warning vs Error Handling** — Configurable `fail_on_warning` and smart exit codes.
*   **Pre-commit Integration** — Run Multi-Linter locally before commits.
*   **Premium UX Enhancements** — Colorized console output, optimized Dockerfile, and standardized wrapper scripts.

## 📂 Repository Structure

```
multi-linter/
├── .github/
│   └── workflows/
│       └── lint.yml               # GitHub Actions workflow
├── docker/
│   └── Dockerfile                 # Multi-linter container
├── linters/                        # Individual wrapper scripts
│   ├── eslint.sh
│   ├── prettier.sh
│   ├── flake8.sh
│   ├── black.sh
│   ├── mypy.sh
│   ├── golangci-lint.sh
│   ├── clippy.sh
│   └── yamllint.sh
├── scripts/
│   ├── entrypoint.sh              # Orchestrates all linters
│   └── reporter.sh                # Generates reports and GitHub annotations
├── config/
│   └── linter-config.yaml         # DSL configuration
├── .pre-commit-config.yaml        # Pre-commit integration
├── README.md
└── LICENSE
```

## ⚙️ DSL Configuration Example (`config/linter-config.yaml`)

```yaml
version: 1.0
fail_on_error: true
fail_on_warning: false
report_format: github  # github | json | junit | markdown

linters:
  eslint:
    enabled: true
    paths: ["src/**/*.ts", "src/**/*.js"]
    auto_fix: true
    config_file: ".eslintrc.json"
    fail_on_warning: false

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

  mypy:
    enabled: true
    paths: ["**/*.py"]

  golangci-lint:
    enabled: true
    paths: ["./..."]
    config_file: ".golangci.yml"

  clippy:
    enabled: true
    paths: ["."]
  
  yamllint:
    enabled: true
    paths: ["**/*.yml", "**/*.yaml"]
    config_file: ".yamllint.yaml"
```

## 💻 Usage

### 1. Local Usage via Docker

```bash
# Build the Docker image
docker build -t multi-linter -f docker/Dockerfile .

# Run against your current project
docker run -v $(pwd):/app -w /app multi-linter
```

**Optional**: Use a custom config file:
```bash
docker run -v $(pwd):/app -w /app -e CONFIG_FILE=/app/config/linter-config.yaml multi-linter
```

### 2. GitHub Actions Workflow

`.github/workflows/lint.yml`:
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
      - uses: actions/checkout@v3
      - name: Run Multi-Linter
        uses: docker://your-org/multi-linter:latest
        with:
          config_file: .github/linter-config.yaml
```
*Generates GitHub PR annotations and supports JSON/JUnit reports for CI dashboards.*

### 3. Pre-commit Integration

`.pre-commit-config.yaml`:
```yaml
repos:
  - repo: local
    hooks:
      - id: multi-linter
        name: Run Multi-Linter
        entry: docker run -v $(pwd):/app -w /app multi-linter
        language: system
        types: [python, javascript, go, rust, yaml]
```
*Runs Multi-Linter automatically before every commit, preventing bad code from being pushed.*

### 4. Advanced Reporting
*   **GitHub annotations**: Errors and warnings appear inline on PR files.
*   **JSON output**: For dashboards or CI logging.
*   **JUnit XML**: Integrates with CI tools like Jenkins or GitLab.

## 🎨 Premium UX
*   **Colorized output**: Blue for info, Green for start, Red/Yellow for failures/warnings.
*   **Smart logging**: Unified format across all linters (`file:line:SEVERITY: message`).
*   **Fail policies**: `fail_on_error` and `fail_on_warning` for granular CI control.
*   **Optimized Docker build**: Includes all dependencies (Node.js, Python, Go, Rust, yq) preinstalled.

## 🛠️ Extensibility
*   Add new linters via DSL without modifying scripts.
*   Customize paths, configs, and auto-fix per linter.
*   Supports per-linter environment variables.

## 📈 Next Steps / Pro Enhancements
*   Incremental linting for large repos (cache previous results).
*   Version pinning per linter for reproducible builds.
*   Advanced Markdown summary for PR comments.
*   Multi-stage Docker build to reduce image size.

---
This project provides a fully professional, CI/CD-ready presentation with usage examples, DSL config, pre-commit hooks, reporting, and workflow integration.
