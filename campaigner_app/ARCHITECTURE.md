# Project Mandates & Engineering Standards

## Development Methodology: Extreme Programming (XP)
All development in this project must follow Extreme Programming practices. This includes:
- **Test-Driven Development (TDD):** Write a failing test before any production code.
- **Simple Design:** Implement the simplest thing that could possibly work.
- **Refactoring:** Continuously improve the code's design without changing its behavior.
- **Small Releases:** Deliver functional increments frequently.
- **Small Steps:** Perform every change in the smallest possible increments. Commit after every successful step (e.g., one failing test, one passing test, one refactor).
- **Make the Change Easy:** When making a change, first refactor the code to make the change as easy as possible (without changing behavior), then implement the easy change.

## Core Requirement: Test-Driven Development (TDD)
You MUST follow the TDD lifecycle for every change:
1. **Red:** Write a test that fails for the expected reason.
2. **Green:** Write the minimum code necessary to make the test pass.
3. **Refactor:** Clean up the code while ensuring tests stay green.

No production code should be written without a corresponding failing test case.

## Definition of Done (Quality Gates)
Work is NOT considered complete until it passes all the following quality gates:
- **Zero Lint Errors:** `gleam format --check` must pass.
- **Zero Warnings:** `gleam check` must return no warnings.
- **High Logic Coverage:** Project logic coverage must be at least **97%**.
- **Green Tests:** All unit and integration tests must pass.

These criteria are enforced by the pre-commit hook and the project `Makefile`.

## Architecture: Hexagonal Architecture (Ports & Adapters)
The application must follow Hexagonal Architecture principles:
- **Core Domain:** Business logic and domain entities must be isolated from external technologies. Keep domain logic pure and independent.
- **Ports:** Define interfaces (using Gleam records/functions) for ALL external communication (I/O, Logging, Database).
- **Adapters:** Implement ports for specific technologies.
- **Dependency Rule:** Dependencies MUST point inward. Infrastructure and Web layers depend on Services and Domain; the reverse is NEVER allowed.
- **Composition Root:** All wiring of Config, Context, and Adapters happens at the entry point (`system.gleam`).

## Advanced Engineering Standards
- **Opaque Types & Value Objects:** Use opaque types for domain entities (`Stats`, `VaultPath`) and consider type aliases or value objects for domain-specific primitives to ensure type safety.
- **Railway-Oriented Programming (ROP):** Prefer flat pipelines using `result.try` (`use <- result.try(...)`) over nested `case` expressions for error handling.
- **Total Functions:** Functions should return `Result` types for all expected failure modes instead of using default "empty" values.
- **Logic-Free Views:** Views should be "dumb" and focus purely on rendering. All data transformation, formatting, and string mapping should happen in the Service layer.
- **BEAM Concurrency & Performance:** Leverage the BEAM for parallel I/O with timeouts. For large-scale operations, use worker pools or chunking patterns to manage resource pressure.
- **Test Segregation:** Maintain a clear distinction between fast Unit tests (using Fakes/Mocks) and slower Integration tests (using real infrastructure).
- **Structured Observability:** The Logger port should ideally support structured data to facilitate production monitoring.
