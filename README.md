# ai-e-ink-dashboard

Домашний дашборд на e-ink дисплее. Sinatra-сервер собирает данные из внешних API, рендерит их как HTML-страницу 800×480, конвертирует в 1-битный PNG и раздаёт по локальной сети. ESP32 с e-paper дисплеем скачивает изображение каждые 10 минут.

```
Wakatime · Google Calendar · Claude API
               ↓
           сервер
      (сбор + кэш данных)
               ↓
     HTML/CSS → 1-bit PNG
               ↓
    ESP32 + e-paper 7.5" 800×480
```

## Документация

- [Архитектура сервера](docs/design-server.md) — слои, классы, порядок реализации
- [UI дизайн](docs/design-ui.md) — сетка, виджеты, правила 1-bit рендеринга

## Требования

- Ruby 3.4.7
- Node.js (для Playwright)
- Chromium (устанавливается отдельно, см. ниже)

## Установка

```sh
bundle install
npx playwright@1.58.2 install chromium
```

## Переменные окружения

Скопируйте `.envrc.example` или создайте `.env`:

```sh
WAKATIME_API_KEY=...
GOOGLE_ACCESS_TOKEN=...
GOOGLE_CALENDAR_ID=primary   # необязательно
ANTHROPIC_API_KEY=...
```

Сервер запускается и без переменных — виджеты без данных покажут «нет данных».

## Запуск

```sh
bundle exec ruby app.rb        # запуск сервера на порту 4567
```

Или через Rack:

```sh
bundle exec rackup             # запуск через config.ru
```

### Эндпоинты

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/dashboard/image` | 1-bit PNG для ESP32 |
| GET | `/dashboard/preview` | HTML-версия для браузера |
| GET | `/api/data` | JSON со всеми данными виджетов |
| GET | `/api/status` | статус сервера |

## Тесты

```sh
bundle exec rspec                     # все тесты
bundle exec rspec spec/unit           # unit-тесты (сервисы, виджеты)
bundle exec rspec spec/requests       # request-тесты (rack-test)
bundle exec rspec spec/system         # system-тесты (Playwright + Ferrum)
```

## Линтер

```sh
bundle exec rubocop                   # проверка
bundle exec rubocop -a                # авто-исправление
```

## Стек

| Слой | Технология |
|------|-----------|
| Сервер | Sinatra 4 (modular) · Puma |
| HTTP-клиент | Faraday + faraday-retry |
| Кэш | DataStore (JSON-файл + TTL) |
| Рендеринг PNG | Ferrum (headless Chrome) + ChunkyPNG |
| Планировщик | rufus-scheduler |
| Тесты | RSpec · rack-test · WebMock · Playwright |
