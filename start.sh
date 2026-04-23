#!/bin/bash
set -e

echo "=== Building and Starting Campaigner App ==="

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
  echo "Installing npm dependencies..."
  npm install
fi

# Build and start the Electron app
npm start
