#!/bin/bash

# core.sh — базовые функции вывода и логирования
# Экспортируемые функции: core_header, core_block_header, core_task, core_status, core_result, core_error, core_user_instruction, core_final_message

# Цветовые константы
readonly CORE_GREEN='\033[1;32m'
readonly CORE_YELLOW='\033[1;33m'
readonly CORE_RED='\033[1;31m'
readonly CORE_BLUE='\033[1;34m'
readonly CORE_CYAN='\033[1;36m'
readonly CORE_NC='\033[0m'

# Основной заголовок с рамкой
core_header() {
    local title="$1"
    clear
    echo ""
    printf "${CORE_GREEN}🚀 %s 🚀${CORE_NC}\n" "$title"
    printf "${CORE_GREEN}===============================================${CORE_NC}\n"
    printf "${CORE_GREEN}Автоматический установщик ноды Nexus${CORE_NC}\n"
    printf "${CORE_GREEN}===============================================${CORE_NC}\n"
    echo ""
}

# Заголовок блока с рамками
core_block_header() {
    local title="$1"
    echo ""
    printf "${CORE_GREEN}===============================================${CORE_NC}\n"
    printf "${CORE_GREEN}%s${CORE_NC}\n" "$title"
    printf "${CORE_GREEN}===============================================${CORE_NC}\n"
    echo ""
}

# Задача с галочкой (белый цвет)
core_task() {
    local task="$1"
    printf "✅ %s\n" "$task"
}

# Статус выполнения
core_status() {
    local status="$1"
    printf "${CORE_YELLOW}%s${CORE_NC}\n" "$status"
}

# Результат выполнения процесса (белый цвет)
core_result() {
    local result="$1"
    printf "✅ %s\n" "$result"
}

# Ошибка
core_error() {
    local error="$1"
    printf "${CORE_RED}❌ %s${CORE_NC}\n" "$error" >&2
}

# Инструкция для пользователя
core_user_instruction() {
    local instruction="$1"
    printf "${CORE_CYAN}%s${CORE_NC}\n" "$instruction"
}

# Финальное сообщение
core_final_message() {
    local message="$1"
    echo ""
    printf "${CORE_GREEN}%s${CORE_NC}\n" "$message"
    echo ""
}

# Функция для завершения работы с ошибкой
core_exit_error() {
    local error="$1"
    core_error "$error"
    exit 1
}
