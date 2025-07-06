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
    
    # Проверяем доступное дисковое пространство
    if ! memory_check_disk_space "$size_gb"; then
        core_exit_error "Недостаточно свободного места на диске для создания файла подкачки размером ${size_gb}Гб"
    fi
    
    # Создаем файл подкачки
    if sudo fallocate -l "${size_gb}G" "$swap_file" 2>/dev/null || sudo dd if=/dev/zero of="$swap_file" bs=1G count="$size_gb" 2>/dev/null; then
        # Устанавливаем права доступа
        sudo chmod 600 "$swap_file" || core_exit_error "Ошибка установки прав доступа для файла подкачки"
        
        # Создаем файловую систему подкачки
        sudo mkswap "$swap_file" || core_exit_error "Ошибка создания файловой системы подкачки"
        
        # Включаем файл подкачки
        sudo swapon "$swap_file" || core_exit_error "Ошибка включения файла подкачки"
        
        # Добавляем в fstab для автоматического подключения
        if ! grep -q "$swap_file" /etc/fstab; then
            echo "$swap_file none swap sw 0 0" | sudo tee -a /etc/fstab > /dev/null
        fi
        
        core_result "Файл подкачки размером ${size_gb}Гб успешно создан"
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
    
    local current_swap_exists=false
    if swap_check_exists; then
        current_swap_exists=true
    fi
    
    echo ""
    if [[ "$current_swap_exists" == true ]]; then
        core_user_instruction "Обнаружен существующий файл подкачки"
    else
        core_user_instruction "Файл подкачки не настроен"
    fi
    echo ""
    
    local swap_size
    read -p "Введите размер файла подкачки в Гб (по умолчанию 12, 0 - не использовать): " swap_size
    swap_size=${swap_size:-12}
    
    if [[ "$swap_size" == "0" ]]; then
        if [[ "$current_swap_exists" == true ]]; then
            swap_remove
        fi
        core_result "Файл подкачки не будет использоваться"
    else
        # Проверяем корректность ввода
        if [[ ! "$swap_size" =~ ^[0-9]+$ ]] || [[ "$swap_size" -lt 1 ]]; then
            core_exit_error "Некорректный размер файла подкачки: $swap_size"
        fi
        
        # Удаляем существующий файл подкачки
        if [[ "$current_swap_exists" == true ]]; then
            swap_remove
        fi
        
        # Создаем новый файл подкачки
        swap_create "$swap_size"
    fi
    
    echo ""
    core_status "Получаем текущую информацию о памяти..."
    memory_display_info
}
