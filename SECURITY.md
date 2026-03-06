# Security Policy

## Supported Versions

The following versions of Multi-Linter are currently supported with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please report it responsibly.

### How to Report

1. **Do NOT** create a public GitHub issue for security vulnerabilities
2. Email the security team at [INSERT EMAIL] with:
   - Description of the vulnerability
   - Steps to reproduce the issue
   - Potential impact of the vulnerability
   - Any suggested fixes (optional)

3. We aim to acknowledge your report within 48 hours
4. We will provide regular updates on the progress of fixing the vulnerability
5. Once the vulnerability is fixed, we will publicly acknowledge your contribution (if you wish)

### What to Expect

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 7 days
- **Fix Timeline**: Based on severity - critical issues within 30 days
- **Disclosure**: Public announcement after fix is released

## Security Best Practices

When using Multi-Linter in your projects:

1. **Pull the specific version tag** instead of using `latest`
   ```yaml
   uses: your-repo/multi-linter@v1.0.0
   ```

2. **Review linter configurations** before running
3. **Use read-only mode** when possible (no auto-fix in production CI)
4. **Scan for secrets** using dedicated tools in addition to Multi-Linter

## Third-Party Dependencies

Multi-Linter uses various third-party tools and linters. Each has its own security policy:

- [ESLint](https://github.com/eslint/eslint/security)
- [Python linters](https://github.com/psf/black/security) (via their respective repos)
- [Go linters](https://github.com/golangci/golangci-lint/security)
- [Rust linters](https://github.com/rust-lang/rust-clippy)

## Security Updates

Security updates will be released as patch versions and announced in:
- GitHub Releases
- CHANGELOG.md
- Security Advisories (if applicable)

## Contact

For security-related inquiries, please contact: [INSERT EMAIL]
