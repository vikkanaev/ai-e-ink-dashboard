# Инструменты агентного окружения

Полный список установленных MCP-серверов, маркетплейсов, скилов и агентов с описанием назначения каждого.

---

## MCP-серверы

MCP (Model Context Protocol) — протокол подключения внешних сервисов к агенту. Сервер становится инструментом, который агент может вызывать во время сессии.

| Инструмент | Статус | Проблема, которую решает |
|---|---|---|
| [**context7**](https://context7.com) | ✅ Connected | Агент не знает актуальный API библиотек — он обучен на старых данных. Context7 динамически подгружает актуальную документацию в контекст прямо во время сессии. Достаточно написать "use context7" в промпте. ([GitHub](https://github.com/upstash/context7)) |
| [**tavily**](https://tavily.com) | ✅ Connected | Поиск актуальной информации в интернете (новости, документация, ответы на вопросы). Решает проблему устаревших знаний модели. ([GitHub](https://github.com/tavily-ai/tavily-mcp)) |

---

## Маркетплейсы

Маркетплейс — GitHub-репозиторий с каталогом плагинов и скилов. Подключение маркетплейса даёт `claude plugins` доступ к его содержимому.

| Маркетплейс | Источник | Что предоставляет |
|---|---|---|
| [**claude-plugins-official**](https://github.com/anthropics/claude-plugins-official) | `anthropics/claude-plugins-official` | Официальные плагины Anthropic (superpowers, clangd-lsp и др.) |
| [**dapi**](https://github.com/dapi/claude-code-marketplace) | `dapi/claude-code-marketplace` | Плагины курса: himalaya, pr-review-fix-loop, spec-reviewer, zellij-workflow |
| [**playwright-skill**](https://github.com/lackeyjb/playwright-skill) | `lackeyjb/playwright-skill` | Скил для браузерной автоматизации через Playwright |

---

## Скилы

Скил — инструкция с инструментами, которую агент загружает по требованию. Экономит токены: загружается только когда нужен, не висит в контексте постоянно.

### Core (устанавливаются через `make ai`)

| Скил | Источник | Проблема, которую решает |
|---|---|---|
| [**playwright-cli**](https://github.com/microsoft/playwright-cli) | `microsoft/playwright-cli` | Агент не умеет управлять браузером без CLI-обёртки. Даёт команды для открытия страниц, клика, снятия скриншотов и взаимодействия с DOM. |
| [**prompt-engineering**](https://github.com/CodeAlive-AI/prompt-engineering-skill) | `CodeAlive-AI/prompt-engineering-skill` | Написать хороший промпт с нуля сложно. Скил помогает оптимизировать и структурировать инструкции для LLM: zero-shot, few-shot, chain-of-thought и другие техники. |
| [**ccbox**](https://github.com/diskd-ai/ccbox) | `diskd-ai/ccbox` | Нельзя вернуться к истории предыдущих сессий. Скил читает `.jsonl`-логи и строит timeline: что просили, что агент делал, что изменилось. |
| [**ccbox-insights**](https://github.com/diskd-ai/ccbox) | `diskd-ai/ccbox` | Ошибки повторяются от сессии к сессии. Скил анализирует историю и предлагает конкретные улучшения в инструкции проекта — на основе реальных фейлов. |

### Extra (устанавливаются через `make extra`)

| Скил | Источник | Проблема, которую решает |
|---|---|---|
| [**tgcli**](https://github.com/dapi/tgcli) | `dapi/tgcli` | Агент не видит Telegram. Скил даёт чтение, поиск и отправку сообщений через CLI. |
| [**gws-gmail**](https://github.com/googleworkspace/cli) | `googleworkspace/cli` | Полный доступ к Gmail: отправка, чтение, управление письмами. |
| [**gws-gmail-send**](https://github.com/googleworkspace/cli) | `googleworkspace/cli` | Отправка email из агентской сессии. |
| [**gws-gmail-reply**](https://github.com/googleworkspace/cli) | `googleworkspace/cli` | Ответ на конкретное письмо с сохранением треда. |
| [**gws-gmail-reply-all**](https://github.com/googleworkspace/cli) | `googleworkspace/cli` | Reply-all с автоматической обработкой треда. |
| [**gws-gmail-forward**](https://github.com/googleworkspace/cli) | `googleworkspace/cli` | Пересылка письма новым получателям. |
| [**gws-gmail-triage**](https://github.com/googleworkspace/cli) | `googleworkspace/cli` | Быстрый обзор непрочитанного inbox: отправитель, тема, дата. |
| [**gws-calendar**](https://github.com/googleworkspace/cli) | `googleworkspace/cli` | Управление Google Calendar: просмотр и создание событий. |
| [**gws-calendar-agenda**](https://github.com/googleworkspace/cli) | `googleworkspace/cli` | Показать предстоящие события по всем календарям. |
| [**gws-calendar-insert**](https://github.com/googleworkspace/cli) | `googleworkspace/cli` | Создать новое событие в Google Calendar. |
| [**gws-docs**](https://github.com/googleworkspace/cli) | `googleworkspace/cli` | Чтение и запись Google Docs из агентской сессии. |
| [**gws-docs-write**](https://github.com/googleworkspace/cli) | `googleworkspace/cli` | Добавление текста в существующий Google Doc. |
| [**gws-drive**](https://github.com/googleworkspace/cli) | `googleworkspace/cli` | Управление файлами и папками в Google Drive. |
| [**gws-drive-upload**](https://github.com/googleworkspace/cli) | `googleworkspace/cli` | Загрузка файла в Google Drive с автоматическими метаданными. |
| [**gws-sheets**](https://github.com/googleworkspace/cli) | `googleworkspace/cli` | Чтение и запись Google Sheets. |
| [**gws-tasks**](https://github.com/googleworkspace/cli) | `googleworkspace/cli` | Управление списками задач в Google Tasks. |
| [**gws-meet**](https://github.com/googleworkspace/cli) | `googleworkspace/cli` | Управление конференциями Google Meet. |
| [**fpf-problem-solving**](https://github.com/CodeAlive-AI/fpf-problem-solving-skill) | `CodeAlive-AI/fpf-problem-solving-skill` | Сложные задачи решаются поверхностно без структуры. FPF (First Principles Framework) — усилитель мышления: декомпозиция, оценка альтернатив, архитектурные решения от первых принципов. |

### Дополнительно установленные (вне Makefile)

| Скил | Источник | Проблема, которую решает |
|---|---|---|
| [**docmost**](https://docmost.com) | `superpowers@claude-plugins-official` | Управление документацией через Docmost CLI: страницы, пространства, workspace. ([GitHub](https://github.com/docmost/docmost)) |
| **retro** | локальный | Ретроспектива разработки фичи: что сработало, где процесс ломался, какие action items берём в работу. |

---

## Агенты (субагенты)

Агент — специализированный субагент с фокусом на конкретной области. Основной агент делегирует ему задачу, получает результат и продолжает работу. Все 16 установлены из [SuperClaude-Org/SuperClaude_Framework](https://github.com/SuperClaude-Org/SuperClaude_Framework/tree/master/plugins/superclaude/agents).

| Агент | Проблема, которую решает |
|---|---|
| [**backend-architect**](https://github.com/SuperClaude-Org/SuperClaude_Framework/blob/master/plugins/superclaude/agents/backend-architect.md) | Проектирование надёжных backend-систем с фокусом на целостность данных, безопасность и отказоустойчивость. |
| [**frontend-architect**](https://github.com/SuperClaude-Org/SuperClaude_Framework/blob/master/plugins/superclaude/agents/frontend-architect.md) | Создание доступных и производительных UI с фокусом на UX и современные фреймворки. |
| [**devops-architect**](https://github.com/SuperClaude-Org/SuperClaude_Framework/blob/master/plugins/superclaude/agents/devops-architect.md) | Автоматизация инфраструктуры и деплоя с фокусом на надёжность и observability. |
| [**system-architect**](https://github.com/SuperClaude-Org/SuperClaude_Framework/blob/master/plugins/superclaude/agents/system-architect.md) | Проектирование масштабируемой архитектуры с фокусом на поддерживаемость и долгосрочные технические решения. |
| [**security-engineer**](https://github.com/SuperClaude-Org/SuperClaude_Framework/blob/master/plugins/superclaude/agents/security-engineer.md) | Поиск уязвимостей и проверка соответствия стандартам безопасности. |
| [**performance-engineer**](https://github.com/SuperClaude-Org/SuperClaude_Framework/blob/master/plugins/superclaude/agents/performance-engineer.md) | Оптимизация производительности системы через анализ метрик и устранение узких мест. |
| [**quality-engineer**](https://github.com/SuperClaude-Org/SuperClaude_Framework/blob/master/plugins/superclaude/agents/quality-engineer.md) | Обеспечение качества через комплексные стратегии тестирования и систематическое выявление граничных случаев. |
| [**refactoring-expert**](https://github.com/SuperClaude-Org/SuperClaude_Framework/blob/master/plugins/superclaude/agents/refactoring-expert.md) | Улучшение качества кода и снижение технического долга через систематический рефакторинг. |
| [**python-expert**](https://github.com/SuperClaude-Org/SuperClaude_Framework/blob/master/plugins/superclaude/agents/python-expert.md) | Production-ready Python-код по принципам SOLID и современным best practices. |
| [**requirements-analyst**](https://github.com/SuperClaude-Org/SuperClaude_Framework/blob/master/plugins/superclaude/agents/requirements-analyst.md) | Превращает размытые идеи в конкретные спецификации через систематический сбор требований. |
| [**root-cause-analyst**](https://github.com/SuperClaude-Org/SuperClaude_Framework/blob/master/plugins/superclaude/agents/root-cause-analyst.md) | Расследование сложных проблем для поиска первопричины через анализ доказательств и проверку гипотез. |
| [**deep-research-agent**](https://github.com/SuperClaude-Org/SuperClaude_Framework/blob/master/plugins/superclaude/agents/deep-research-agent.md) | Комплексное исследование с адаптивными стратегиями и интеллектуальной исследовательской логикой. |
| [**technical-writer**](https://github.com/SuperClaude-Org/SuperClaude_Framework/blob/master/plugins/superclaude/agents/technical-writer.md) | Создание понятной технической документации для конкретной аудитории с фокусом на usability. |
| [**learning-guide**](https://github.com/SuperClaude-Org/SuperClaude_Framework/blob/master/plugins/superclaude/agents/learning-guide.md) | Обучение концепциям программирования через прогрессивное обучение и практические примеры. |
| [**socratic-mentor**](https://github.com/SuperClaude-Org/SuperClaude_Framework/blob/master/plugins/superclaude/agents/socratic-mentor.md) | Сократический метод для программирования: направляет к знанию через вопросы, а не прямые ответы. |
| [**business-panel-experts**](https://github.com/SuperClaude-Org/SuperClaude_Framework/blob/master/plugins/superclaude/agents/business-panel-experts.md) | Синтез бизнес-стратегии от панели экспертов (Christensen, Porter, Drucker и др.): последовательный, дискуссионный и сократический режимы. |
