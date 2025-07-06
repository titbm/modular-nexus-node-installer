#!/bin/bash

# automation.sh — настройка автоматизации
# Экспортируемые функции: automation_setup, automation_setup_auto_update, automation_setup_restart, automation_remove_cron_jobs

# Удаление существующих cron заданий для nexus
automation_remove_cron_jobs() {
    local temp_cron=$(mktemp)
    crontab -l 2>/dev/null | grep -v "nexus" > "$temp_cron"
    crontab "$temp_cron"
    rm -f "$temp_cron"
}

# Настройка автообновления
automation_setup_auto_update() {
    core_status "Настраиваем автообновление версии ноды..."
    
    # Создаем скрипт автообновления
    local update_script="$HOME/.nexus-auto-update.sh"
    
    cat > "$update_script" << 'EOF'
#!/bin/bash

# Скрипт автообновления Nexus CLI
CONFIG_FILE="$HOME/.nexus-installer-config.json"

# Функция для получения конфигурации
get_config() {
    local key="$1"
    if [[ -f "$CONFIG_FILE" ]]; then
        jq -r --arg key "$key" '.[$key] // empty' "$CONFIG_FILE" 2>/dev/null
    fi
}

# Получение версий
get_installed_version() {
    if command -v nexus &> /dev/null; then
        nexus version 2>/dev/null | head -n1 | cut -d' ' -f2 || echo ""
    else
        echo ""
    fi
}

get_latest_version() {
    curl -s https://api.github.com/repos/nexus-xyz/nexus-cli/releases/latest | jq -r .tag_name 2>/dev/null || echo ""
}

# Основная логика
main() {
    local installed_version=$(get_installed_version)
    local latest_version=$(get_latest_version)
    
    if [[ -z "$latest_version" ]]; then
        echo "Не удалось получить информацию о последней версии"
        exit 1
    fi
    
    if [[ "$installed_version" == "$latest_version" ]]; then
        echo "Установлена актуальная версия: $installed_version"
        exit 0
    fi
    
    echo "Обнаружена новая версия: $latest_version (текущая: $installed_version)"
    
    # Получаем Nexus ID и интервал перезапуска
    local nexus_id=$(get_config "nexus_id")
    local restart_interval=$(get_config "restart_interval")
    
    if [[ -z "$nexus_id" ]]; then
        echo "Nexus ID не найден в конфигурации"
        exit 1
    fi
    
    # Удаляем задания на перезапуск
    if [[ -n "$restart_interval" ]]; then
        crontab -l 2>/dev/null | grep -v "nexus.*restart" | crontab -
    fi
    
    # Останавливаем tmux сессию
    tmux kill-session -t nexus 2>/dev/null || true
    
    # Обновляем Nexus CLI
    export PATH="$HOME/.nexus/bin:$PATH"
    NEXUS_NON_INTERACTIVE=1 curl -sSL https://raw.githubusercontent.com/nexus-xyz/nexus-cli/main/install.sh | bash
    
    # Запускаем новую версию
    sleep 5
    tmux new-session -d -s nexus "nexus start --node-id $nexus_id"
    
    # Восстанавливаем задания на перезапуск
    if [[ -n "$restart_interval" && "$restart_interval" != "0" ]]; then
        local restart_script="$HOME/.nexus-restart.sh"
        echo "*/$restart_interval * * * * $restart_script # nexus restart" | crontab -
    fi
    
    echo "Nexus CLI обновлен до версии $latest_version"
}

main "$@"
EOF
    
    chmod +x "$update_script"
    
    # Добавляем в cron (каждый час)
    local temp_cron=$(mktemp)
    crontab -l 2>/dev/null > "$temp_cron"
    echo "0 * * * * $update_script # nexus auto-update" >> "$temp_cron"
    crontab "$temp_cron"
    rm -f "$temp_cron"
    
    core_result "Автообновление настроено (проверка каждый час)"
}

# Настройка автоматического перезапуска
automation_setup_restart() {
    local interval="$1"
    
    core_status "Настраиваем автоматический перезапуск ноды каждые $interval минут..."
    
    # Создаем скрипт перезапуска
    local restart_script="$HOME/.nexus-restart.sh"
    
    cat > "$restart_script" << 'EOF'
#!/bin/bash

# Скрипт перезапуска Nexus CLI
CONFIG_FILE="$HOME/.nexus-installer-config.json"

# Получение Nexus ID
get_nexus_id() {
    if [[ -f "$CONFIG_FILE" ]]; then
        jq -r '.nexus_id // empty' "$CONFIG_FILE" 2>/dev/null
    fi
}

main() {
    local nexus_id=$(get_nexus_id)
    
    if [[ -z "$nexus_id" ]]; then
        echo "Nexus ID не найден в конфигурации"
        exit 1
    fi
    
    # Останавливаем текущую сессию
    tmux kill-session -t nexus 2>/dev/null || true
    
    # Ждем завершения процессов
    sleep 5
    
    # Запускаем новую сессию
    export PATH="$HOME/.nexus/bin:$PATH"
    tmux new-session -d -s nexus "nexus start --node-id $nexus_id"
    
    echo "Nexus CLI перезапущен с ID: $nexus_id"
}

main "$@"
EOF
    
    chmod +x "$restart_script"
    
    # Добавляем в cron
    local temp_cron=$(mktemp)
    crontab -l 2>/dev/null > "$temp_cron"
    echo "*/$interval * * * * $restart_script # nexus restart" >> "$temp_cron"
    crontab "$temp_cron"
    rm -f "$temp_cron"
    
    # Сохраняем интервал в конфигурацию
    config_set_restart_interval "$interval"
    
    core_result "Автоматический перезапуск настроен каждые $interval минут"
}

# Основная функция настройки автоматизации
automation_setup() {
    core_task "Настроить автоматизацию"
    
    # Удаляем существующие cron задания
    automation_remove_cron_jobs
    
    # Настройка автообновления
    echo ""
    echo "Включить автообновление версии ноды? (y/n, по умолчанию y): "
    read auto_update </dev/tty
    auto_update=${auto_update:-y}
    
    if [[ "$auto_update" =~ ^[Yy]$ ]]; then
        automation_setup_auto_update
    else
        core_result "Автообновление отключено"
    fi
    
    # Настройка перезапуска
    echo ""
    echo "Как часто перезапускать ноду (в минутах, по умолчанию не перезапускать)? "
    read restart_interval </dev/tty
    
    if [[ -n "$restart_interval" && "$restart_interval" =~ ^[0-9]+$ && "$restart_interval" -gt 0 ]]; then
        automation_setup_restart "$restart_interval"
    else
        core_result "Автоматический перезапуск не настроен"
        config_set_restart_interval ""
    fi
}
