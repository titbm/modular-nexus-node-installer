# Примеры использования модульного установщика Nexus Node

## Основное использование

```bash
# Установка с GitHub
curl -sSL https://raw.githubusercontent.com/titbm/modular-nexus-node-installer/main/nexus-install.sh | bash

# Локальная установка (для разработки)
bash nexus-install.sh
```

## Конфигурация по умолчанию

При первом запуске будут запрошены:
- Nexus ID (сохраняется в ~/.nexus-installer-config.json)
- Размер файла подкачки (по умолчанию 12Гб)
- Автообновление (по умолчанию включено)
- Интервал перезапуска (по умолчанию отключен)

## Неинтерактивная установка

Для автоматической установки создайте конфигурацию заранее:

```bash
# Создать конфигурацию
cat > ~/.nexus-installer-config.json << EOF
{
  "nexus_id": "your-nexus-id-here",
  "restart_interval": "60"
}
EOF

# Запустить установку
curl -sSL https://raw.githubusercontent.com/titbm/modular-nexus-node-installer/main/nexus-install.sh | bash
```

## Переменные окружения

```bash
# Неинтерактивный режим Nexus CLI
export NEXUS_NON_INTERACTIVE=1

# Пользовательский путь к конфигурации
export NEXUS_CONFIG_FILE="$HOME/my-nexus-config.json"
```

## Ручное управление

```bash
# Просмотр статуса
tmux list-sessions | grep nexus

# Подключение к ноде
tmux attach-session -t nexus

# Отключение от ноды (внутри tmux)
Ctrl+B, затем D

# Остановка ноды
tmux kill-session -t nexus

# Перезапуск ноды
tmux kill-session -t nexus
tmux new-session -d -s nexus "nexus start --node-id YOUR_ID"
```

## Управление cron заданиями

```bash
# Просмотр заданий
crontab -l

# Удаление всех заданий nexus
crontab -l | grep -v nexus | crontab -

# Ручное добавление перезапуска каждые 30 минут
echo "*/30 * * * * $HOME/.nexus-restart.sh # nexus restart" | crontab -
```

## Логи и отладка

```bash
# Просмотр логов установки
tail -f /var/log/nexus-install.log

# Просмотр логов автообновления
tail -f /var/log/nexus-auto-update.log

# Проверка процессов
ps aux | grep nexus

# Проверка сетевых соединений
netstat -tulpn | grep nexus
```

## Удаление

```bash
# Остановка ноды
tmux kill-session -t nexus 2>/dev/null || true

# Удаление cron заданий
crontab -l | grep -v nexus | crontab -

# Удаление файлов
rm -f ~/.nexus-installer-config.json
rm -f ~/.nexus-auto-update.sh
rm -f ~/.nexus-restart.sh
rm -rf ~/.nexus/

# Удаление файла подкачки (опционально)
sudo swapoff /swapfile
sudo rm -f /swapfile
sudo sed -i '/\/swapfile/d' /etc/fstab
```
