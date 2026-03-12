#!/bin/bash
source input.sh

# Очистка по лог-файлу
clean_by_log() {
    echo -e "\e[32mCleaning by log file\e[0m"
    
    # Запрашиваем путь к лог-файлу
    echo "Enter path to log file:"
    read log_file_path
    
    # Проверяем, существует ли файл
    if [ ! -f "$log_file_path" ]; then
        echo -e "\e[91mError: Log file not found: $log_file_path\e[0m"
        exit 1
    fi
    
    echo "Using log file: $log_file_path"
    
    # Счетчик удаленных объектов
    local count=0
    
    # Читаем лог-файл и удаляем все созданные папки и файлы
    # Ищем строки с PATH и извлекаем пути
    while IFS= read -r line; do
        if [[ "$line" == PATH:* ]]; then
            # Извлекаем путь (между PATH: и первой запятой)
            local path=$(echo "$line" | sed 's/^PATH: //' | sed 's/,.*//')
            
            if [ -n "$path" ] && [ -e "$path" ]; then
                if [ -f "$path" ]; then
                    # Это файл - удаляем
                    sudo rm -f "$path"
                    echo "Deleted file: $path"
                elif [ -d "$path" ]; then
                    # Это папка - удаляем рекурсивно
                    sudo rm -rf "$path"
                    echo "Deleted folder: $path"
                fi
                ((count++))
            fi
        fi
    done < "$log_file_path"
    
    echo -e "\e[32mCleaning completed. Deleted $count items.\e[0m"
}

# Очистка по дате и времени создания
clean_by_time() {
    echo -e "\e[32mCleaning by time range\e[0m"
    
    # Ввод времени начала и конца
    echo "Enter start time (YYYY-MM-DD HH:MM):"
    read start_time
    
    echo "Enter end time (YYYY-MM-DD HH:MM):"
    read end_time
    
    # Проверка формата ввода
    if ! date -d "$start_time" >/dev/null 2>&1; then
        echo -e "\e[91mError: Invalid start time format\e[0m"
        exit 1
    fi
    
    if ! date -d "$end_time" >/dev/null 2>&1; then
        echo -e "\e[91mError: Invalid end time format\e[0m"
        exit 1
    fi
    
    # Конвертируем в timestamp для сравнения
    start_ts=$(date -d "$start_time" +%s)
    end_ts=$(date -d "$end_time" +%s)
    
    echo "Searching for files and folders created between $start_time and $end_time"
    
    local count=0
    
    # Ищем папки с маской Part 2 (буквы_дата)
    while IFS= read -r -d '' dir; do
        if [[ "$(basename "$dir")" =~ ^[a-zA-Z]+_[0-9]{6}$ ]]; then
            dir_ctime=$(stat -c %Y "$dir" 2>/dev/null)
            if [ -n "$dir_ctime" ] && [ "$dir_ctime" -ge "$start_ts" ] && [ "$dir_ctime" -le "$end_ts" ]; then
                echo "Found folder: $dir (created: $(date -d @$dir_ctime +"%Y-%m-%d %H:%M:%S"))"
                sudo rm -rf "$dir"
                echo "Deleted"
                ((count++))
            fi
        fi
    done < <(find / -type d -print0 2>/dev/null)
    
    # Ищем файлы с маской Part 2 (буквы_дата.расширение)
    while IFS= read -r -d '' file; do
        filename=$(basename "$file")
        if [[ "$filename" =~ ^[a-zA-Z]+_[0-9]{6}\.[a-zA-Z]{1,3}$ ]]; then
            file_ctime=$(stat -c %Y "$file" 2>/dev/null)
            if [ -n "$file_ctime" ] && [ "$file_ctime" -ge "$start_ts" ] && [ "$file_ctime" -le "$end_ts" ]; then
                echo "Found file: $file (created: $(date -d @$file_ctime +"%Y-%m-%d %H:%M:%S"))"
                sudo rm -f "$file"
                echo "Deleted"
                ((count++))
            fi
        fi
    done < <(find / -type f -print0 2>/dev/null)
    
    echo -e "\e[32mCleaning completed. Deleted $count items.\e[0m"
}

# Очистка по маске имени
clean_by_mask() {
    echo -e "\e[32mCleaning by name mask\e[0m"
    
    # Ввод маски
    echo "Enter name mask (e.g., az_090326 or az.az_090326):"
    read mask
    
    # Проверяем формат маски
    if [[ ! "$mask" =~ ^[a-zA-Z]+_[0-9]{6}$ ]] && [[ ! "$mask" =~ ^[a-zA-Z]+\.[a-zA-Z]+_[0-9]{6}$ ]]; then
        echo -e "\e[91mError: Invalid mask format. Use: name_DDMMYY or name.ext_DDMMYY\e[0m"
        exit 1
    fi
    
    echo "Searching for items matching mask: $mask"
    
    local count=0
    
    # Если маска содержит точку - ищем файлы
    if [[ "$mask" == *.* ]]; then
        while IFS= read -r -d '' file; do
            if [[ "$(basename "$file")" == "$mask" ]]; then
                echo "Found file: $file"
                sudo rm -f "$file"
                echo "Deleted"
                ((count++))
            fi
        done < <(find / -type f -print0 2>/dev/null)
    else
        # Маска для папки
        while IFS= read -r -d '' dir; do
            if [[ "$(basename "$dir")" == "$mask" ]]; then
                echo "Found folder: $dir"
                sudo rm -rf "$dir"
                echo "Deleted"
                ((count++))
            fi
        done < <(find / -type d -print0 2>/dev/null)
    fi
    
    echo -e "\e[32mCleaning completed. Deleted $count items.\e[0m"
}
