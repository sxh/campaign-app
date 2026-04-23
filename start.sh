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

# Build and start the Electron app
npm start
