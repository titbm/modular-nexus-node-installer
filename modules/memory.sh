#!/bin/bash

# memory.sh — управление памятью
# Экспортируемые функции: memory_display_info

# Получение информации о памяти в мегабайтах
memory_get_info() {
    local total_ram_mb=$(free -m | awk 'NR==2{print $2}')
    local used_ram_mb=$(free -m | awk 'NR==2{print $3}')
    local available_ram_mb=$(free -m | awk 'NR==2{print $7}')
    
    # Конвертируем в гигабайты для удобства
    local total_ram_gb=$((total_ram_mb / 1024))
    local used_ram_gb=$((used_ram_mb / 1024))
    local available_ram_gb=$((available_ram_mb / 1024))
    
    echo "$total_ram_mb $used_ram_mb $available_ram_mb $total_ram_gb $used_ram_gb $available_ram_gb"
}

# Получение информации о файле подкачки
memory_get_swap_info() {
    local swap_total_mb=$(free -m | awk 'NR==3{print $2}')
    local swap_used_mb=$(free -m | awk 'NR==3{print $3}')
    local swap_free_mb=$(free -m | awk 'NR==3{print $4}')
    
    local swap_total_gb=$((swap_total_mb / 1024))
    local swap_used_gb=$((swap_used_mb / 1024))
    local swap_free_gb=$((swap_free_mb / 1024))
    
    echo "$swap_total_mb $swap_used_mb $swap_free_mb $swap_total_gb $swap_used_gb $swap_free_gb"
}

# Отображение информации о памяти
memory_display_info() {
    core_task "Получить информацию об оперативной памяти сервера"
    
    core_status "Получаем информацию о памяти..."
    
    local memory_info=($(memory_get_info))
    local total_ram_mb=${memory_info[0]}
    local used_ram_mb=${memory_info[1]}
    local available_ram_mb=${memory_info[2]}
    local total_ram_gb=${memory_info[3]}
    local used_ram_gb=${memory_info[4]}
    local available_ram_gb=${memory_info[5]}
    
    local swap_info=($(memory_get_swap_info))
    local swap_total_mb=${swap_info[0]}
    local swap_used_mb=${swap_info[1]}
    local swap_free_mb=${swap_info[2]}
    local swap_total_gb=${swap_info[3]}
    local swap_used_gb=${swap_info[4]}
    local swap_free_gb=${swap_info[5]}
    
    echo ""
    core_user_instruction "Текущее состояние оперативной памяти:"
    
    # Красивая таблица для оперативной памяти
    # Получаем дополнительные данные от free -m
    local buffer_cache_mb=$(free -m | awk 'NR==2{print $6}')
    local shared_mb=$(free -m | awk 'NR==2{print $5}')
    
    # Вычисляем правильные дроби для гигабайт
    local total_ram_fraction=$(( (total_ram_mb % 1024) * 10 / 1024 ))
    local available_ram_fraction=$(( (available_ram_mb % 1024) * 10 / 1024 ))
    
    printf "┌─────────┬─────────┬───────────┬────────┬──────────┬───────────┐\n"
    printf "│ %-7s │ %-7s │ %-9s │ %-6s │ %-8s │ %-9s │\n" "Всего" "Занято" "Свободно" "Общее" "Буфер/" "Доступно"
    printf "│         │         │           │        │ Кеш      │           │\n"
    printf "├─────────┼─────────┼───────────┼────────┼──────────┼───────────┤\n"
    printf "│ %-7s │ %-7s │ %-9s │ %-6s │ %-8s │ %-9s │\n" \
        "${total_ram_gb}.${total_ram_fraction}Гб" \
        "${used_ram_mb}Мб" \
        "${available_ram_gb}.${available_ram_fraction}Гб" \
        "${shared_mb}Мб" \
        "${buffer_cache_mb}Мб" \
        "${available_ram_gb}.${available_ram_fraction}Гб"
    printf "└─────────┴─────────┴───────────┴────────┴──────────┴───────────┘\n"
    
    echo ""
    core_user_instruction "Текущее состояние файла подкачки:"
    
    # Красивая таблица для файла подкачки
    printf "┌─────────┬─────────┬───────────┐\n"
    printf "│ %-7s │ %-7s │ %-9s │\n" "Всего" "Занято" "Свободно"
    printf "├─────────┼─────────┼───────────┤\n"
    
    if [[ $swap_total_mb -gt 0 ]]; then
        printf "│ %-7s │ %-7s │ %-9s │\n" \
            "${swap_total_gb}Гб" \
            "${swap_used_mb}Мб" \
            "${swap_free_mb}Мб"
    else
        printf "│ %-7s │ %-7s │ %-9s │\n" "0Гб" "0Мб" "0Мб"
    fi
    
    printf "└─────────┴─────────┴───────────┘\n"
    echo ""
    
    core_result "Информация о памяти получена"
}

# Проверка доступного дискового пространства
memory_check_disk_space() {
    local required_space_gb="$1"
    local available_space_gb=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
    
    if [[ $available_space_gb -ge $required_space_gb ]]; then
        return 0
    else
        return 1
    fi
}
