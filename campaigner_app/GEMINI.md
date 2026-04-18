# Project Mandates

## Development Methodology: Extreme Programming (XP)
All development in this project must follow Extreme Programming practices. This includes:
- **Test-Driven Development (TDD):** Write a failing test before any production code.
- **Simple Design:** Implement the simplest thing that could possibly work.
- **Refactoring:** Continuously improve the code's design without changing its behavior.
- **Small Releases:** Deliver functional increments frequently.

## Core Requirement: Test-Driven Development (TDD)
You MUST follow the TDD lifecycle for every change:
1. **Red:** Write a test that fails for the expected reason.
2. **Green:** Write the minimum code necessary to make the test pass.
3. **Refactor:** Clean up the code while ensuring tests stay green.

No production code should be written without a corresponding failing test case.

## Architecture: Hexagonal Architecture (Ports & Adapters)
The application must follow Hexagonal Architecture principles:
- **Core Domain:** Business logic and domain entities must be isolated from external technologies (databases, UI, frameworks).
- **Ports:** Define interfaces (using Gleam records/functions) for communicating with the outside world.
- **Adapters:** Implement ports for specific technologies (e.g., Mist for HTTP, Simplifile for File System).
- **Dependency Rule:** Dependencies must point inward toward the Core Domain. The Core must not depend on any Adapters.
