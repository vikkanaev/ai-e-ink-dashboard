# Дизайн сервера e-ink Dashboard

## Обзор

Сервер на Sinatra собирает данные из внешних API, кэширует их локально и раздаёт e-ink клиенту (ESP32) в виде PNG-изображения. Данные обновляются в фоне каждые 10 минут — в ритм с ESP32.

```
Внешние API (Wakatime, Google Calendar, Claude)
        ↓  (Scheduler, каждые 10 мин)
    DataStore (JSON-файл + in-memory кэш)
        ↓
  GET /dashboard/image  →  ImageRenderer  →  1-bit PNG  →  ESP32
  GET /api/data         →  JSON виджетов  →  отладка / мониторинг
```

---

## Архитектурные решения

| Решение | Обоснование |
|---------|-------------|
| Faraday для HTTP | Единый интерфейс с middleware; удобный DI через адаптер |
| DataStore как JSON-файл | Данные < 10 KB; нет внешних процессов (Redis, SQLite) |
| `rufus-scheduler` внутри процесса | Локальный сервер; не нужен cron или Sidekiq |
| Ferrum (headless Chrome) для скриншотов | Современный CSS-рендеринг; wkhtmltopdf устарел |
| DI через `initialize` во всех классах | Позволяет мокировать HTTP и время в тестах без патчинга |

---

## Файловая структура

```
Gemfile
app.rb                          # точка входа, монтирует маршруты, стартует Scheduler
config.ru                       # Rack конфиг

services/
  external_api_base.rb          # абстрактный базовый класс для всех внешних API
  wakatime_service.rb           # Wakatime API
  google_calendar_service.rb    # Google Calendar API
  claude_tokens_service.rb      # Claude / Codex token usage
  data_store.rb                 # локальное хранилище с TTL
  scheduler.rb                  # фоновый опрос API
  image_renderer.rb             # HTML → 1-bit PNG

widgets/
  wakatime_widget.rb
  calendar_widget.rb
  tokens_widget.rb

routes/
  dashboard_routes.rb           # GET /dashboard/image, GET /dashboard/preview
  api_routes.rb                 # GET /api/data, GET /api/status

views/
  dashboard.erb                 # HTML-шаблон 800×480

spec/
  unit/
    services/
    widgets/
  requests/
  system/
  support/
    fixtures/                   # wakatime_response.json, calendar_response.json, …
```

---

## Граф зависимостей

```
app.rb
  ├── Scheduler
  │     ├── WakatimeService      ← ExternalApiBase
  │     ├── GoogleCalendarService ← ExternalApiBase
  │     ├── ClaudeTokensService  ← ExternalApiBase
  │     └── DataStore
  │
  ├── DashboardRoutes (Sinatra::Base)
  │     ├── DataStore (read)
  │     ├── WakatimeWidget
  │     ├── CalendarWidget
  │     ├── TokensWidget
  │     └── ImageRenderer
  │
  └── ApiRoutes (Sinatra::Base)
        └── DataStore (read)
```

---

## `services/external_api_base.rb`

Абстрактный базовый класс. Вся HTTP-логика сосредоточена здесь.

```ruby
# Интерфейс (не реальный код, только контракт)
class ExternalApiBase
  DEFAULT_TIMEOUT = 10   # секунды
  DEFAULT_RETRIES = 3
  RETRY_DELAY    = 1     # базовая задержка; удваивается при каждом retry

  # connection: DI-точка для тестов (передаётся Faraday::Connection или стаб)
  def initialize(timeout: DEFAULT_TIMEOUT, retries: DEFAULT_RETRIES, connection: nil)

  # Публичный метод. Возвращает распарсенный результат или бросает ServiceError.
  def call

  # --- abstract ---
  def url            # → String; raises NotImplementedError
  def parse_response(response)  # → Hash/Array; принимает Faraday::Response; raises NotImplementedError

  # --- вложенные исключения ---
  # ServiceError < StandardError
  # TimeoutError < ServiceError
  # NetworkError < ServiceError
  # ParseError   < ServiceError
end
```

### Retry-логика

Реализуется через middleware `faraday-retry` в стеке Faraday:

- HTTP 4xx → `ServiceError` без retry (клиентская ошибка)
- HTTP 5xx → retry с backoff (1 с, 2 с, 4 с)
- `Faraday::TimeoutError` / `Faraday::ConnectionFailed` → retry с backoff
- После исчерпания попыток → `NetworkError` или `TimeoutError`

### Конкретные реализации

```ruby
class WakatimeService < ExternalApiBase
  # initialize(api_key:, date: Date.today, **kwargs)
  # kwargs пробрасываются в super (timeout:, retries:, connection:)
  # url → 'https://wakatime.com/api/v1/users/current/summaries?...'
  # parse_response(response) → { total_seconds:, languages: [], date: }
  #   response.body уже распарсен Faraday middleware :json
end

class GoogleCalendarService < ExternalApiBase
  # initialize(access_token:, calendar_id: 'primary', date: Date.today, **kwargs)
  # url → 'https://www.googleapis.com/calendar/v3/calendars/{id}/events?...'
  # parse_response(response) → [{ summary:, start:, end:, location: }, ...]
end

class ClaudeTokensService < ExternalApiBase
  # initialize(api_key:, **kwargs)
  # parse_response(response) → { used:, limit:, reset_at: }
end
```

---

## `services/data_store.rb`

Файловый JSON-кэш с in-memory слоем и TTL.

```ruby
# Интерфейс
class DataStore
  # store_path: путь к JSON-файлу (default: 'tmp/data_store.json')
  # clock: DI для тестов (default: Time)
  def initialize(store_path: 'tmp/data_store.json', clock: Time)

  def write(key, value, ttl:)   # записать значение с TTL в секундах
  def read(key)                 # прочитать; nil если нет или просрочено
  def stale?(key)               # true если данных нет или TTL истёк
  def fetch(key, ttl:, &block)  # read || (block.call -> write -> return)
end
```

Основной паттерн использования:

```ruby
data = store.fetch(:wakatime, ttl: 600) { WakatimeService.new(...).call }
```

---

## `services/scheduler.rb`

```ruby
class Scheduler
  # services: { wakatime: WakatimeService, calendar: GoogleCalendarService, ... }
  # interval: 600 (секунды)
  def initialize(data_store:, services:, interval: 600)

  def start   # rufus-scheduler; первый poll — сразу при старте
  def stop
end
```

- Каждый сервис опрашивается независимо: ошибка одного не блокирует остальные
- TTL в DataStore может отличаться по сервисам (wakatime: 600 с, calendar: 300 с, tokens: 3600 с)

---

## `services/image_renderer.rb`

```ruby
class ImageRenderer
  WIDTH     = 800
  HEIGHT    = 480
  THRESHOLD = 128   # порог квантизации в 1 бит

  def initialize(html_renderer: nil, png_converter: nil)

  # data: { wakatime: WakatimeWidget#to_h, calendar: CalendarWidget#to_h, ... }
  # → PNG bytes (String)
  def render(dashboard_data)
end
```

Цепочка: данные → ERB-шаблон → HTML-строка → Ferrum (скриншот) → PNG → 1-bit квантизация.

---

## `routes/dashboard_routes.rb`

```
GET /dashboard/image    → 200 image/png  (для ESP32)
GET /dashboard/preview  → 200 text/html  (для браузера, отладка)
```

Маршруты тонкие: берут данные из DataStore, передают в виджеты и ImageRenderer, возвращают результат.

## `routes/api_routes.rb`

```
GET /api/data    → 200 application/json  { wakatime: {…}, calendar: {…}, tokens: {…}, updated_at: }
                 → 503 если DataStore пуст
GET /api/status  → 200 application/json  { status: 'ok', last_updated: …, uptime: … }
```

---

## Виджеты

Каждый виджет — тонкий слой трансформации данных. Не знает о Sinatra и HTTP.

```ruby
class WakatimeWidget
  def initialize(data:)           # data от WakatimeService#call
  def to_h                        # { total_hours:, top_language:, bar_percentage:, date: }
end

class CalendarWidget
  def initialize(events:)         # events от GoogleCalendarService#call
  def to_h                        # { events: [{time:, title:, location:}], today: }
end

class TokensWidget
  def initialize(data:)           # data от ClaudeTokensService#call
  def to_h                        # { used:, limit:, percentage:, reset_at: }
end
```

---

## Тесты

| Директория | Инструмент | Что проверяет |
|-----------|-----------|---------------|
| `spec/unit/services/` | RSpec + WebMock | Retry-логика, парсинг ответов, TTL в DataStore |
| `spec/unit/widgets/` | RSpec | Трансформация данных в `to_h` |
| `spec/requests/` | rack-test | HTTP-статусы и Content-Type маршрутов |
| `spec/system/` | Playwright | HTML/PNG рендеринг в браузере |

Все внешние HTTP-запросы в тестах мокируются через WebMock. Реальные сетевые вызовы запрещены.

---

## Порядок реализации

| Шаг | Что создать |
|-----|------------|
| 1 | `Gemfile`, `.rubocop.yml` |
| 2 | `services/external_api_base.rb` + `spec/unit/services/external_api_base_spec.rb` |
| 3 | `services/data_store.rb` + спеки |
| 4 | Конкретные API-сервисы + спеки |
| 5 | Виджеты + спеки |
| 6 | `views/dashboard.erb` |
| 7 | `services/image_renderer.rb` + спеки |
| 8 | `routes/` + request-спеки |
| 9 | `services/scheduler.rb` + спеки |
| 10 | `app.rb`, `config.ru` |
| 11 | `spec/system/` — Playwright тесты |

---

## Зависимости (Gemfile)

```ruby
gem 'sinatra', '~> 4.0'         # модульный режим
gem 'puma', '~> 6.0'            # веб-сервер
gem 'faraday', '~> 2.0'         # HTTP-клиент
gem 'faraday-retry', '~> 2.2'   # retry middleware для Faraday
gem 'rufus-scheduler', '~> 3.9' # фоновый планировщик
gem 'ferrum', '~> 0.15'         # headless Chrome для скриншотов
gem 'chunky_png', '~> 1.4'      # 1-bit PNG квантизация
gem 'dotenv', '~> 3.0'          # переменные окружения

group :development, :test do
  gem 'rspec', '~> 3.13'
  gem 'rack-test', '~> 2.1'
  gem 'webmock', '~> 3.23'
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'playwright-ruby-client'
end
```
