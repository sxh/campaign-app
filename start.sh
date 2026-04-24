#!/bin/bash
set -e

echo "=== Building and Starting Campaigner App ==="

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
  echo "Installing npm dependencies..."
  npm install
fi

# Clean previous build artifacts to ensure fresh compilation
echo "Cleaning build artifacts..."
gleam clean

# Build JavaScript target, filtering dependency warnings
echo "Building..."
BUILD_OUTPUT=$(gleam build --target javascript 2>&1)
PROJECT_WARNINGS=$(echo "$BUILD_OUTPUT" | awk '/^warning:/{w=$0; next} /build\/packages\//{w=""; next} w{print w; w=""}') || true
if [ -n "$PROJECT_WARNINGS" ]; then
    echo "WARNING: Project source warnings:"
    echo "$PROJECT_WARNINGS"
fi
echo "$BUILD_OUTPUT" | tail -1

# Build Erlang target for tests
echo "Building Erlang..."
gleam build --target erlang >/dev/null 2>&1

# Build to public/
npm run build

echo "=== Starting Electron app ==="
# Start the Electron app
npm run electron
