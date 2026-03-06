# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Support for 40+ linters across 20+ languages
- GitHub Actions integration and marketplace publishing
- Multi-stage Dockerfile for optimized builds
- Non-root user for security
- Docker layer caching in CI
- Test fixtures and test workflow
- ShellCheck validation in CI

### Changed
- Improved entrypoint.sh with auto language detection
- Optimized linter scripts for parallel execution

### Fixed
- Various shell script improvements

## [1.0.0] - 2024-01-01

### Added
- Initial release
- 8 linters: eslint, prettier, flake8, black, mypy, golangci-lint, clippy, yamllint
- DSL-driven YAML configuration
- Parallel execution
- GitHub annotations support
- Auto language detection
