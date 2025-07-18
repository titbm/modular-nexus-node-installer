#!/bin/bash

# Nexus Node Installer - Модульный установщик ноды
set -euo pipefail

# Конфигурация
VERSION="0.0.1"
BASE_URL="https://raw.githubusercontent.com/titbm/modular-nexus-node-installer/main/modules"
CONFIG_FILE="$HOME/.nexus-installer-config.json"

# Функция загрузки модулей
load_module() {
    local module="$1"
    local temp_file="/tmp/nexus_${module}_$$"
    
    if curl -sSL "$BASE_URL/${module}.sh" > "$temp_file" 2>/dev/null; then
        source "$temp_file"
        rm -f "$temp_file"
    else
        echo "❌ Ошибка загрузки модуля $module"
        exit 1
    fi
}

# Предварительная проверка curl (нужен для загрузки модулей)
if ! command -v curl &> /dev/null; then
    echo "❌ curl не найден. Он необходим для загрузки модулей."
    echo "Установите curl и повторите попытку:"
    echo "  Ubuntu/Debian: sudo apt install curl"
    echo "  CentOS/RHEL: sudo yum install curl"
    exit 1
fi

# Загрузка всех модулей
echo "Загружаем модули..."
for module in core config system memory swap nexus node automation; do
    load_module "$module"
done

# Главный заголовок
core_header "🚀 NEXUS NODE INSTALLER ${VERSION} 🚀"

# Основная логика выполнения
core_block_header "ПРОВЕРКА УСТАНОВЛЕННОГО ПО"

# Проверка зависимостей
system_check_dependencies

core_block_header "ПОИСК И ЗАВЕРШЕНИЕ ТЕКУЩИХ СЕАНСОВ NEXUS CLI"

# Проверка и остановка запущенных сессий
system_check_tmux_sessions

core_block_header "НАСТРОЙКА ФАЙЛА ПОДКАЧКИ"

# Управление файлом подкачки (включает отображение информации о памяти)
swap_manage

echo ""
core_block_header "📦 УСТАНОВКА NEXUS CLI 📦"

# Проверка и установка/обновление Nexus CLI
nexus_check_and_install

echo ""
core_block_header "🚀 ЗАПУСК НОДЫ 🚀"

# Получение Nexus ID
config_get_nexus_id

# Запуск ноды
node_start

echo ""
core_block_header "⚙️ НАСТРОЙКА АВТОМАТИЗАЦИИ ⚙️"

# Настройка автообновления и перезапуска
automation_setup

echo ""
core_final_message "🎉 УСТАНОВКА ЗАВЕРШЕНА 🎉"
core_user_instruction "Нода запущена в фоновом режиме, можно закрыть терминал"
