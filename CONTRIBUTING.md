# Contributing to Multi-Linter

Thank you for your interest in contributing to Multi-Linter!

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/repolense/multi-linter.git`
3. Create a feature branch: `git checkout -b feature/my-feature`

## Development Setup

### Prerequisites
- Docker
- Git
- [Optional] ShellCheck for local script validation

### Running Locally

```bash
# Build the Docker image
docker build -t multi-linter -f action/Dockerfile .

# Run against test fixtures
docker run --rm -v $(pwd)/tests/fixtures:/app multi-linter

# Run against your own project
docker run -v $(pwd):/app -w /app multi-linter
```

## Adding a New Linter

1. **Create the linter script** in `linters/`:
   ```bash
   # linters/mylinter.sh
   #!/bin/bash
   CONFIG_FILE=$1
   PATHS=$(yq e '.linters.mylinter.paths | join(" ")' $CONFIG_FILE)
   
   mylinter $PATHS 2>&1 | while IFS= read -r line; do
       if echo "$line" | grep -E "^[^:]+:[0-9]+:" > /dev/null; then
           echo "$line" >> /tmp/linter.log
       fi
   done || true
   ```

2. **Add configuration** to `config/linter-config.yaml`:
   ```yaml
   mylinter:
     enabled: true
     paths: ["**/*.ext"]
     fail_on_warning: false
   ```

3. **Add file detection** to `scripts/entrypoint.sh`:
   ```bash
   mylinter)
       echo "$CHANGED_FILES" | grep -E "\.ext$" > /dev/null && SHOULD_RUN=true
       ;;
   ```

4. **Add to Dockerfile** if new tools are needed (in `action/Dockerfile`)

5. **Test your changes**:
   - Add test fixtures in `tests/fixtures/`
   - Run the test workflow

## Code Style

- Use shellcheck to validate scripts
- Follow existing script patterns
- Use meaningful variable names
- Add error handling with `|| true` for linter commands

## Submitting Changes

1. Ensure all tests pass
2. Update documentation if needed
3. Commit with clear messages
4. Push to your fork
5. Create a pull request

## Reporting Issues

Use GitHub Issues to report:
- Bug reports
- Feature requests
- Linter issues

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
