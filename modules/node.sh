#!/bin/bash

# node.sh — управление запуском ноды
# Экспортируемые функции: node_start

# Запуск ноды
node_start() {
    core_task "Запустить Nexus CLI в фоновом режиме"
    
    # Получаем Nexus ID из конфигурации
    local nexus_id=$(config_get "nexus_id" "")
    
    if [[ -z "$nexus_id" ]]; then
        core_exit_error "Nexus ID не найден в конфигурации"
    fi
    
    core_status "Запускаем Nexus CLI в фоновом режиме с ID: $nexus_id"
    
    # Проверяем, что nexus-network доступен
    if ! command -v nexus-network &> /dev/null; then
        # Пытаемся найти в стандартном месте
        if [ -f "$HOME/.nexus/bin/nexus-network" ]; then
            export PATH="$HOME/.nexus/bin:$PATH"
            core_status "Добавлен путь к Nexus CLI в PATH"
        else
            core_exit_error "Nexus CLI не найден в PATH"
        fi
    fi
    
    # Создаем новую tmux сессию с именем nexus
    if tmux new-session -d -s nexus "$HOME/.nexus/bin/nexus-network start --node-id $nexus_id"; then
        core_result "Nexus CLI успешно запущен в tmux сессии 'nexus'"
        
        # Ждем немного и проверяем, что сессия все еще активна
        sleep 3
        if tmux has-session -t nexus 2>/dev/null; then
            core_result "Сессия tmux с Nexus CLI активна и работает"
        else
            core_exit_error "Сессия tmux с Nexus CLI завершилась неожиданно"
        fi
    else
        core_exit_error "Ошибка запуска Nexus CLI в tmux сессии"
    fi
    
    echo ""
    core_user_instruction "Команды для управления нодой:"
    core_user_instruction "  Просмотр логов: tmux attach-session -t nexus"
    core_user_instruction "  Выход из логов: Ctrl+B, затем D"
    core_user_instruction "  Остановка ноды: tmux kill-session -t nexus"
    echo ""
}
