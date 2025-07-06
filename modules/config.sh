#!/bin/bash

# config.sh — управление конфигурацией
# Экспортируемые функции: config_load, config_save, config_get_nexus_id, config_get_restart_interval, config_set_restart_interval

# Загрузка конфигурации
config_load() {
    if [[ -f "$CONFIG_FILE" ]]; then
        return 0
    else
        # Создаем пустой конфигурационный файл
        echo '{}' > "$CONFIG_FILE"
        return 0
    fi
}

# Сохранение значения в конфигурацию
config_save() {
    local key="$1"
    local value="$2"
    
    # Создаем или обновляем JSON файл
    if [[ -f "$CONFIG_FILE" ]]; then
        local temp_file=$(mktemp)
        jq --arg key "$key" --arg value "$value" '.[$key] = $value' "$CONFIG_FILE" > "$temp_file" && mv "$temp_file" "$CONFIG_FILE"
    else
        echo "{\"$key\": \"$value\"}" > "$CONFIG_FILE"
    fi
}

# Получение значения из конфигурации
config_get() {
    local key="$1"
    local default_value="${2:-}"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        local value=$(jq -r --arg key "$key" '.[$key] // empty' "$CONFIG_FILE" 2>/dev/null)
        if [[ -n "$value" && "$value" != "null" ]]; then
            echo "$value"
        else
            echo "$default_value"
        fi
    else
        echo "$default_value"
    fi
}

# Получение Nexus ID
config_get_nexus_id() {
    core_task "Получить Nexus ID"
    
    local saved_nexus_id=$(config_get "nexus_id" "")
    
    if [[ -n "$saved_nexus_id" ]]; then
        echo ""
        core_user_instruction "Найден сохраненный Nexus ID: $saved_nexus_id"
        echo ""
        echo "Использовать сохраненный ID? (y/n, по умолчанию y): "
        read use_saved </dev/tty
        use_saved=${use_saved:-y}
        
        if [[ "$use_saved" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    echo ""
    core_user_instruction "ВАЖНО: Получите ваш Nexus ID"
    core_user_instruction "1. Откройте браузер и перейдите на: https://app.nexus.xyz/nodes"
    core_user_instruction "2. Войдите в свой аккаунт (кнопка Sign In)"
    core_user_instruction "3. Нажмите кнопку 'Add CLI Node'"
    core_user_instruction "4. Скопируйте появившиеся цифры - это ваш Nexus ID"
    echo ""
    
    local nexus_id
    while true; do
        echo "Введите ваш Nexus ID: "
        read nexus_id </dev/tty
        if [[ -n "$nexus_id" ]]; then
            config_save "nexus_id" "$nexus_id"
            core_result "Nexus ID сохранен: $nexus_id"
            break
        else
            core_error "Nexus ID не может быть пустым"
        fi
    done
}

# Получение интервала перезапуска
config_get_restart_interval() {
    config_get "restart_interval" ""
}

# Установка интервала перезапуска
config_set_restart_interval() {
    local interval="$1"
    config_save "restart_interval" "$interval"
}
