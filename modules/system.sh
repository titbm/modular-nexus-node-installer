#!/bin/bash

# system.sh — проверка системы и зависимостей
# Экспортируемые функции: system_check_dependencies, system_check_tmux_sessions

# Проверка зависимостей (curl проверяется в основном скрипте)
system_check_dependencies() {
    core_task "Проверить наличие необходимых зависимостей"
    
    local missing_deps=()
    
    # Проверка tmux
    core_status "Проверяем наличие tmux..."
    if ! command -v tmux &> /dev/null; then
        missing_deps+=("tmux")
    else
        core_result "tmux уже установлен"
    fi
    
    # Проверка jq (требуется для работы с JSON конфигурацией и GitHub API)
    core_status "Проверяем наличие jq..."
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    else
        core_result "jq уже установлен"
    fi
        missing_deps+=("jq")
    else
        core_result "jq уже установлен"
    fi
    
    # Установка недостающих зависимостей
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        core_status "Устанавливаем недостающие зависимости: ${missing_deps[*]}"
        
        # Определяем пакетный менеджер
        if command -v apt &> /dev/null; then
            sudo apt update -y || core_exit_error "Ошибка при обновлении списка пакетов"
            sudo apt install -y "${missing_deps[@]}" || core_exit_error "Ошибка при установке зависимостей: ${missing_deps[*]}"
        elif command -v yum &> /dev/null; then
            sudo yum install -y "${missing_deps[@]}" || core_exit_error "Ошибка при установке зависимостей: ${missing_deps[*]}"
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y "${missing_deps[@]}" || core_exit_error "Ошибка при установке зависимостей: ${missing_deps[*]}"
        else
            core_exit_error "Не удалось определить пакетный менеджер. Установите вручную: ${missing_deps[*]}"
        fi
        
        core_result "Зависимости успешно установлены"
    else
        core_result "Все необходимые зависимости уже установлены"
    fi
}

# Проверка и остановка tmux сессий с nexus
system_check_tmux_sessions() {
    core_task "Проверить наличие сессии tmux с nexus cli"
    
    core_status "Проверяем наличие сессии tmux с nexus cli..."
    
    if tmux has-session -t nexus 2>/dev/null; then
        core_result "Обнаружена сессия tmux с nexus cli, выполнить остановку"
        
        core_status "Останавливаем сессию tmux с nexus cli..."
        if tmux kill-session -t nexus 2>/dev/null; then
            core_result "Сессия tmux с nexus cli успешно остановлена"
        else
            core_error "Ошибка при остановке сессии tmux с nexus cli"
        fi
    else
        core_result "Активных сессий tmux с nexus cli не обнаружено"
    fi
    
    # Также проверим и остановим процессы nexus
    core_status "Проверяем наличие запущенных процессов nexus..."
    if pgrep -f "nexus" > /dev/null; then
        core_result "Обнаружены запущенные процессы nexus, выполнить остановку"
        pkill -f "nexus" 2>/dev/null || true
        sleep 2
        core_result "Процессы nexus остановлены"
    else
        core_result "Запущенных процессов nexus не обнаружено"
    fi
}
