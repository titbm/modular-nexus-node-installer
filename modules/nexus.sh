#!/bin/bash

# nexus.sh — управление установкой и обновлением Nexus CLI
# Экспортируемые функции: nexus_check_and_install, nexus_get_installed_version, nexus_get_latest_version, nexus_install, nexus_update

# Получение установленной версии Nexus CLI
nexus_get_installed_version() {
    if [ -f "$HOME/.nexus/bin/nexus-network" ]; then
        $HOME/.nexus/bin/nexus-network --version 2>/dev/null | sed 's/nexus-network //' | sed 's/^v//' || echo ""
    else
        echo ""
    fi
}

# Получение последней версии Nexus CLI с GitHub
nexus_get_latest_version() {
    curl -s https://api.github.com/repos/nexus-xyz/nexus-cli/releases/latest 2>/dev/null | grep '"tag_name":' | sed 's/.*"tag_name": "v\?\(.*\)".*/\1/' || echo ""
}

# Установка Nexus CLI (интерактивная)
nexus_install() {
    core_status "Устанавливаем Nexus CLI..."
    
    # Интерактивная установка для первого раза
    if curl -sSL https://cli.nexus.xyz/ | sh; then
        # Проверяем успешность установки
        if [ -f "$HOME/.nexus/bin/nexus-network" ]; then
            local new_version=$($HOME/.nexus/bin/nexus-network --version 2>/dev/null | sed 's/nexus-network //' | sed 's/^v//')
            core_result "Nexus CLI успешно установлен (версия $new_version)"
        else
            core_exit_error "Ошибка: исполняемый файл не найден после установки"
        fi
    else
        core_exit_error "Ошибка установки Nexus CLI"
    fi
}

# Обновление Nexus CLI (неинтерактивное)
nexus_update() {
    core_status "Обновляем Nexus CLI..."
    
    # Скачиваем установочный скрипт и запускаем в неинтерактивном режиме
    if curl -sSf https://cli.nexus.xyz/ -o /tmp/nexus_install.sh && \
       chmod +x /tmp/nexus_install.sh && \
       NONINTERACTIVE=1 /tmp/nexus_install.sh; then
        # Очищаем временный файл
        rm -f /tmp/nexus_install.sh
        
        # Проверяем успешность обновления
        if [ -f "$HOME/.nexus/bin/nexus-network" ]; then
            local new_version=$($HOME/.nexus/bin/nexus-network --version 2>/dev/null | sed 's/nexus-network //' | sed 's/^v//')
            core_result "Nexus CLI успешно обновлен (версия $new_version)"
        else
            core_exit_error "Ошибка: исполняемый файл не найден после обновления"
        fi
    else
        rm -f /tmp/nexus_install.sh
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
        
        echo "Обновить до последней версии? (y/n, по умолчанию n): "
        read update_choice </dev/tty
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
