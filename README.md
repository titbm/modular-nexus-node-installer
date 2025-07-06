# Модульный установщик Nexus Node

Простой модульный bash-установщик для Nexus Node с автоматической загрузкой актуальных модулей с GitHub.

## Запуск

```bash
curl -sSL https://raw.githubusercontent.com/titbm/modular-nexus-node-installer/main/nexus-install.sh | bash
```

## Особенности

- Модульная архитектура - легко расширяется
- Загрузка модулей с GitHub при каждом запуске
- Сохранение конфигурации в JSON
- Автообновление и перезапуск ноды
- Русский интерфейс с цветным выводом

## Модули

- `core.sh` - базовые функции
- `config.sh` - управление конфигурацией  
- `system.sh` - проверка системы
- `memory.sh` - управление памятью
- `swap.sh` - файл подкачки
- `nexus.sh` - установка Nexus CLI
- `node.sh` - запуск ноды
- `automation.sh` - автоматизация

## Управление

```bash
# Просмотр логов
tmux attach-session -t nexus

# Выход из tmux
Ctrl+B, затем D

# Остановка ноды
tmux kill-session -t nexus
```

## Конфигурация

Сохраняется в `~/.nexus-installer-config.json`

## Разработка

См. `copilot-instructions.md` для создания новых модулей.
