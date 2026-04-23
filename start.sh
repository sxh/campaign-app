#!/bin/bash
# Start the Campaigner app
# Note: OpenCode must be running first for the sidebar to work
# Run: opencode serve --port 14096 --hostname 127.0.0.1 --cors app://obsidian.md

cd "$(dirname "$0")/campaigner_app"
exec gleam run