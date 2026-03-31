See PROJECT.md for project description.

## Stack

Ruby 3.4.7 · Sinatra (modular, `Sinatra::Base`) · ERB · RSpec 3 · rack-test · Playwright (system tests)

## Key commands

- `bundle exec ruby app.rb` — run server
- `bundle exec rspec` — all tests
- `bundle exec rspec spec/unit` — unit tests only
- `bundle exec rspec spec/requests` — request tests only (rack-test)
- `bundle exec rspec spec/system` — system tests only (Playwright)
- `bundle exec rubocop` — lint
- `bundle exec rubocop -a` — lint with auto-fix

## File structure

```
app.rb          # entry point, mounts routes
config.ru       # Rack config
routes/         # Sinatra::Base subclasses per domain
services/       # external APIs and business logic
widgets/        # dashboard widget objects
views/          # ERB templates
spec/
  unit/         # tests for services and widgets
  requests/     # rack-test route tests
  system/       # Playwright tests
  support/      # factories, helpers, mocks
```

## Conventions

- All classes in `services/` and `widgets/` use explicit interfaces via `initialize` with dependency injection
- External HTTP calls only in `services/` — never in routes or widgets
- Routes are thin: fetch data via service, pass to template, contain no logic
- Each widget is a standalone class with a `render` or `to_h` method — has no knowledge of Sinatra
- All public methods on classes must have unit test coverage

## Constraints

- Do not add external API calls outside `services/` without explicit request
- In tests, mock all external HTTP requests (WebMock or equivalent) — real network calls are forbidden
- Run `bundle exec rubocop` and `bundle exec rspec` before every commit — do not commit if either fails
- Do not create god objects: if a class does more than one thing, split it
- Do not change the `spec/` structure without explicit request
- Playwright tests are only for verifying HTML/PNG rendering, not for business logic
