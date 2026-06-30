# Multi-Linter Plugin System

## Overview

The plugin system allows you to add custom linters without modifying the core repository. Plugins are discovered automatically from the `plugins/` directory.

## Structure

```
plugins/
├── your-plugin/
│   ├── manifest.yaml    # Plugin metadata and configuration
│   ├── linter.sh        # Linter script (must be executable)
│   └── ...              # Additional files as needed
```

## Manifest Format

```yaml
name: plugin-name          # Unique plugin identifier
description: ...           # Brief description
version: 1.0.0             # Semantic version
language: python           # Target language (generic if none)
enabled: true              # Enable/disable without removing
paths:                     # File glob patterns to match
  - "**/*.py"
script: linter.sh          # Entry point script (relative to plugin dir)
args: []                   # Additional CLI arguments
```

## Plugin Script Interface

The script receives:
- `$1`: Path to the linter configuration YAML file
- Additional args from `manifest.yaml` `args` field

Output should be appended to `/tmp/linter.log` in this format:
```
filepath:line:LEVEL: message
```

Where LEVEL is `ERROR`, `WARNING`, or `INFO`.

## Discovery

Plugins are discovered at startup from:
1. `/usr/local/bin/plugins/` (Docker image built-in)
2. Custom path via `PLUGIN_DIR` environment variable

## Example

See the `example/` plugin for a working template.
