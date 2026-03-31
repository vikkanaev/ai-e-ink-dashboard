# CLAUDE.md Design

**Date:** 2026-03-31  
**Topic:** Project instructions file for AI agents (CLAUDE.md)

## Context

E-ink dashboard project: Sinatra server that fetches data from external APIs, renders HTML/CSS, converts to 1-bit PNG, and serves it over the local network to an ESP32 e-paper display.

The application has not been written yet — only infrastructure scaffolding exists.

## Decisions

### Stack
Ruby 3.4.7, Sinatra (modular, `Sinatra::Base`), ERB, RSpec 3, rack-test, Playwright.

### Test strategy
Full stack: unit tests for services and widgets, request tests via rack-test for routes, system tests via Playwright for HTML/PNG rendering verification.

### File structure
Layered: `routes/`, `services/`, `widgets/`, `views/`. Each layer has a single responsibility. `spec/` mirrors the structure with `unit/`, `requests/`, `system/`, `support/`.

### Conventions
- OOP-oriented: explicit `initialize` interfaces, dependency injection throughout
- Routes are thin — no business logic
- Widgets are Sinatra-agnostic objects
- External HTTP only in `services/`

### Constraints
- External API calls only in `services/`
- All external HTTP mocked in tests (WebMock or equivalent)
- No god objects
- `spec/` structure is stable — do not modify without explicit request
- Playwright tests are for rendering verification only

## Rationale

The layered structure and strict service isolation ensure testability without real network calls. OOP with DI makes it easy to swap implementations (e.g., mock services in tests). Thin routes keep Sinatra-specific code minimal and the domain logic portable.
