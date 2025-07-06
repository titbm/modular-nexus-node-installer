#!/bin/bash

# nexus.sh — управление установкой и обновлением Nexus CLI
# Экспортируемые функции: nexus_check_and_install, nexus_get_installed_version, nexus_get_latest_version, nexus_install, nexus_update

# Получение установленной версии Nexus CLI
nexus_get_installed_version() {
    if command -v nexus &> /dev/null; then
        nexus version 2>/dev/null | head -n1 | cut -d' ' -f2 || echo ""
    else
        echo ""
    fi
}

# Получение последней версии Nexus CLI с GitHub
nexus_get_latest_version() {
    curl -s https://api.github.com/repos/nexus-xyz/nexus-cli/releases/latest | jq -r .tag_name 2>/dev/null || echo ""
}

# Установка Nexus CLI
nexus_install() {
    core_status "Устанавливаем Nexus CLI..."
    
    # Скачиваем и устанавливаем Nexus CLI
    if curl -sSL https://raw.githubusercontent.com/nexus-xyz/nexus-cli/main/install.sh | bash; then
        core_result "Nexus CLI успешно установлен"
        
        # Добавляем в PATH если необходимо
        if ! command -v nexus &> /dev/null; then
            export PATH="$HOME/.nexus/bin:$PATH"
            echo 'export PATH="$HOME/.nexus/bin:$PATH"' >> ~/.bashrc
        fi
    else
        core_exit_error "Ошибка установки Nexus CLI"
    fi
}

# Обновление Nexus CLI
nexus_update() {
    core_status "Обновляем Nexus CLI..."
    
    # Неинтерактивный режим обновления
    if NEXUS_NON_INTERACTIVE=1 curl -sSL https://raw.githubusercontent.com/nexus-xyz/nexus-cli/main/install.sh | bash; then
        core_result "Nexus CLI успешно обновлен"
    else
        core_exit_error "Ошибка обновления Nexus CLI"
    fi
}

# Проверка и установка/обновление Nexus CLI
nexus_check_and_install() {
    core_task "Проверить наличие установленного Nexus CLI"
    
    core_status "Проверяем наличие установленного Nexus CLI..."
    
    local installed_version=$(nexus_get_installed_version)
    
    if [[ -z "$installed_version" ]]; then
        core_result "Nexus CLI не установлен, начинаем установку"
        nexus_install
        installed_version=$(nexus_get_installed_version)
    else
        core_result "Nexus CLI уже установлен, версия: $installed_version"
    fi
    
    # Проверяем наличие новой версии
    core_status "Проверяем наличие новой версии в репозитории..."
    
    local latest_version=$(nexus_get_latest_version)
    
    if [[ -z "$latest_version" ]]; then
        core_error "Не удалось получить информацию о последней версии"
        return 0
    fi
    
    echo ""
    core_user_instruction "Установленная версия: $installed_version"
    
    if [[ "$installed_version" != "$latest_version" ]]; then
        echo ""
        core_user_instruction "Последняя версия: $latest_version (доступно обновление)"
        echo ""
        
        read -p "Обновить до последней версии? (y/n, по умолчанию n): " update_choice
        update_choice=${update_choice:-n}
        
        if [[ "$update_choice" =~ ^[Yy]$ ]]; then
            nexus_update
        else
            core_result "Обновление пропущено"
        fi
    else
        core_user_instruction "Последняя версия: $latest_version (актуальная версия)"
        core_result "Установлена актуальная версия Nexus CLI"
    fi
    echo ""
}
