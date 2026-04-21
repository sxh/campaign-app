#!/bin/bash
set -e

echo "Setting up git hooks..."

# Set the hooks path to .githooks directory
git config core.hooksPath .githooks

echo "Git hooks configured. The pre-commit hook will now run detekt and tests before each commit."
echo "To skip hooks, use 'git commit --no-verify'."