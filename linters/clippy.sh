#!/bin/bash
CONFIG_FILE=$1
cargo clippy --all-targets --all-features --message-format=short -- -D warnings >> /tmp/linter.log 2>&1 || true
