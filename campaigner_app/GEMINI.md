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
- **Core Domain:** Business logic and domain entities must be isolated from external technologies. Keep domain logic pure and independent.
- **Ports:** Define interfaces (using Gleam records/functions) for ALL external communication (I/O, Logging, Database).
- **Adapters:** Implement ports for specific technologies.
- **Dependency Rule:** Dependencies MUST point inward. Infrastructure and Web layers depend on Services and Domain; the reverse is NEVER allowed.
- **Composition Root:** All wiring of Config, Context, and Adapters happens at the entry point (`system.gleam`).

## Advanced Engineering Standards
- **Opaque Types:** Use opaque types for domain entities (`Stats`, `VaultPath`) to protect invariants. Provide explicit constructors and getters.
- **Railway-Oriented Programming (ROP):** Prefer flat pipelines using `result.try` (`use <- result.try(...)`) over nested `case` expressions for error handling.
- **Total Functions:** Functions should return `Result` types for all expected failure modes instead of using default "empty" values.
- **Logic-Free Views:** Views should be "dumb" and focus purely on rendering. All data transformation and formatting should happen in the Service layer.
- **BEAM Concurrency:** Leverage the BEAM for parallel I/O but always implement timeouts and fault-tolerant patterns.
