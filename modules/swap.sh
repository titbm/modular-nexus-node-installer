#!/bin/bash

# swap.sh — управление файлом подкачки
# Экспортируемые функции: swap_manage, swap_create, swap_remove, swap_check_exists

# Проверка существования файла подкачки
swap_check_exists() {
    swapon --show 2>/dev/null | grep -q "/swapfile"
}

# Создание файла подкачки
swap_create() {
    local size_gb="$1"
    local swap_file="/swapfile"
    
    core_status "Создаем файл подкачки размером ${size_gb}Гб..."
    
    # Проверяем доступное дисковое пространство (как в эталоне)
    local available_space=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
    local required_space=$((size_gb + 1))  # Add 1GB buffer
    
    if [[ $available_space -lt $required_space ]]; then
        core_exit_error "Недостаточно свободного места. Доступно: ${available_space}ГБ, требуется: ${required_space}ГБ (${size_gb}ГБ + 1ГБ буфер)"
    fi
    
    # Создаем файл подкачки
    if sudo fallocate -l "${size_gb}G" "$swap_file" 2>/dev/null; then
        # Устанавливаем права доступа
        if sudo chmod 600 "$swap_file"; then
            # Создаем файловую систему подкачки
            if sudo mkswap "$swap_file" 2>/dev/null; then
                # Включаем файл подкачки
                if sudo swapon "$swap_file" 2>/dev/null; then
                    # Добавляем в fstab для автоматического подключения
                    if ! grep -q "$swap_file" /etc/fstab; then
                        echo "$swap_file none swap sw 0 0" | sudo tee -a /etc/fstab > /dev/null
                    fi
                    core_result "Файл подкачки размером ${size_gb}Гб успешно создан"
                else
                    sudo rm -f "$swap_file" 2>/dev/null || true
                    core_exit_error "Ошибка при активации файла подкачки"
                fi
            else
                sudo rm -f "$swap_file" 2>/dev/null || true
                core_exit_error "Ошибка при инициализации файла подкачки"
            fi
        else
            sudo rm -f "$swap_file" 2>/dev/null || true
            core_exit_error "Ошибка при установке прав доступа для файла подкачки"
        fi
    else
        core_exit_error "Ошибка создания файла подкачки"
    fi
}

# Удаление файла подкачки
swap_remove() {
    local swap_file="/swapfile"
    
    core_status "Удаляем существующий файл подкачки..."
    
    # Отключаем файл подкачки
    if sudo swapoff "$swap_file" 2>/dev/null; then
        core_result "Файл подкачки отключен"
    fi
    
    # Удаляем файл
    if sudo rm -f "$swap_file" 2>/dev/null; then
        core_result "Файл подкачки удален"
    fi
    
    # Удаляем из fstab
    if grep -q "$swap_file" /etc/fstab; then
        sudo sed -i "\|$swap_file|d" /etc/fstab
        core_result "Файл подкачки удален из автозагрузки"
    fi
}

# Управление файлом подкачки
swap_manage() {
    core_task "Управление файлом подкачки"
    
    # 1-2. Получаем и выводим текущее состояние памяти
    echo ""
    core_user_instruction "Текущее состояние памяти:"
    memory_display_info
    
    # 3. Спрашиваем пользователя о размере файла подкачки
    echo ""
    echo "Размер файла подкачки в ГБ (Enter = 12ГБ, 0 = не создавать): "
    local swap_size
    read swap_size </dev/tty
    swap_size=${swap_size:-12}
    
    # 4. Выводим сообщение о выборе пользователя
    echo ""
    if [[ "$swap_size" == "0" ]]; then
        core_user_instruction "Выбрано: Не использовать файл подкачки"
    else
        # Проверяем корректность ввода
        if [[ ! "$swap_size" =~ ^[0-9]+$ ]] || [[ "$swap_size" -lt 1 ]]; then
            core_exit_error "Некорректный размер файла подкачки: $swap_size"
        fi
        core_user_instruction "Выбрано: Создать файл подкачки размером ${swap_size}ГБ"
    fi
    
    # 5. Удаляем текущий файл подкачки (если существует)
    if swap_check_exists; then
        swap_remove
    fi
    
    # 6. Создаем новый файл подкачки по запросу пользователя
    if [[ "$swap_size" != "0" ]]; then
        swap_create "$swap_size"
    fi
    
    # 7. Выводим обновленное состояние памяти
    echo ""
    core_user_instruction "Обновленное состояние памяти:"
    memory_display_info
}
