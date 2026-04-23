# Agent Development Guidelines

## Core Principles

This project follows **Extreme Programming (XP)** and **Hexagonal Architecture**.

## Extreme Programming (XP)

- **TDD (Test-Driven Development)**: Write failing tests first, then implementation
  - Red: Write a failing test
  - Green: Write minimal code to pass
  - Refactor: Improve code while keeping tests passing
- Pair programming is encouraged
- Simple design: YAGNI - don't build features until needed
- Continuous refactoring
- Test coverage must remain above 80%

## Hexagonal Architecture (Ports & Adapters)

```
                    ┌─────────────────────┐
                    │   Driving Actor     │
                    │   (API/Web UI)     │
                    └────────┬────────────┘
                             │
                    ┌────────▼────────────┐
                    │    Input Port      │
                    │   (Interface)     │
                    └────────┬────────────┘
                             │
┌───────────────────────────────▼───────────────────────────────┐
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │              Application Core (Domain)                │   │
│   │                                                     │   │
│   │  - Domain Models                                    │   │
│   │  - Domain Services                                │   │
│   │  - Business Rules                                │   │
│   │                                                     │   │
│   └─────────────────────────────────────────────────────┘   │
│                             │                             │
│                    ┌────────▼────────────┐                 │
│                    │   Output Port      │                   │
│                    │   (Interface)     │                   │
│                    └────────┬────────────┘                 │
│                             │                             │
│                    ┌────────▼────────────┐                 │
│                    │  Adapters         │                   │
│                    │  (DB, API, etc.)  │                   │
│                    └─────────────────────┘                 │
└─────────────────────────────────────────────────────────┘
```

### Structure

- `domain/` - Pure domain models, no framework dependencies
- `application/` - Use cases, orchestration
- `ports/` - Interfaces (in/out)
- `adapters/` - Implementations (DB, API, etc.)

## SOLID Principles

- **S**ingle Responsibility: One reason to change per class
- **O**pen/Closed: Open for extension, closed for modification
- **L**iskov Substitution: Subtypes must be substitutable
- **I**nterface Segregation: Many specific interfaces over one general
- **D**ependency Inversion: Depend on abstractions, not concretions

## Testing Requirements

- Unit tests for all domain logic
- Integration tests for adapters
- Minimum 95% code coverage
- Tests must be deterministic (no flaky tests)
- **NEVER ignore or work around test failures** - all tests must pass before proceeding
- If a test fails, stop and fix the root cause - do not continue until tests pass
- Always check the exit code after running tests (non-zero indicates failure)

## Code Quality

- detekt with maxIssues: 0
- All detekt rules must pass before commit
- Follow existing code conventions

## Running the App

Use `./start.sh` to run Campaigner (runs Gleam app on port 8000).

Note: OpenCode must be running first for the sidebar to work:
```bash
opencode serve --port 14096 --hostname 127.0.0.1 --cors app://obsidian.md
```