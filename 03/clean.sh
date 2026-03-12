#!/bin/bash
source input.sh

# Очистка по лог-файлу
clean_by_log() {
    echo -e "\e[32mCleaning by log file\e[0m"
    
    echo "Enter path to log file:"
    read log_file_path
    
    if [ ! -f "$log_file_path" ]; then
        echo -e "\e[91mError: Log file not found: $log_file_path\e[0m"
        exit 1
    fi
    
    echo "Using log file: $log_file_path"
    
    # Читаем лог-файл и ищем строки с папками
    while IFS= read -r line; do
        if [[ "$line" == PATH:* ]]; then  # Строка без точки - это папка
            local path=$(echo "$line" | sed 's/^PATH: //' | sed 's/,.*//')
            
            if [ -n "$path" ] && [ -d "$path" ]; then  # Проверяем, что это папка
                sudo rm -rf "$path"
                echo "Deleted folder: $path"
            fi
        fi
    done < "$log_file_path"
    
    echo -e "\e[32mCleaning completed\e[0m"
}

# Очистка по дате и времени создания
clean_by_time() {
    echo -e "\e[32mCleaning by time range\e[0m"
    
    echo "Enter start time (YYYY-MM-DD HH:MM):"
    read start_time
    echo "Enter end time (YYYY-MM-DD HH:MM):"
    read end_time
    
    if ! date -d "$start_time" >/dev/null 2>&1; then
        echo -e "\e[91mError: Invalid start time format\e[0m"
        exit 1
    fi
    if ! date -d "$end_time" >/dev/null 2>&1; then
        echo -e "\e[91mError: Invalid end time format\e[0m"
        exit 1
    fi
    
    start_ts=$(date -d "$start_time" +%s)
    end_ts=$(date -d "$end_time" +%s)
    
    echo "Searching for folders created between $start_time and $end_time"
    
    # Ищем только папки с маской буквы_дата
    while IFS= read -r -d '' dir; do
        if [[ "$(basename "$dir")" =~ ^[a-zA-Z]+_[0-9]{6}$ ]]; then
            dir_ctime=$(stat -c %Y "$dir" 2>/dev/null)
            if [ -n "$dir_ctime" ] && [ "$dir_ctime" -ge "$start_ts" ] && [ "$dir_ctime" -le "$end_ts" ]; then
                echo "Found folder: $dir (created: $(date -d @$dir_ctime +"%Y-%m-%d %H:%M:%S"))"
                sudo rm -rf "$dir"
                echo "Deleted"
            fi
        fi
    done < <(find /home -type d -print0 2>/dev/null)
    
    echo -e "\e[32mCleaning completed\e[0m"
}

# Очистка по маске букв
clean_by_mask() {
    echo -e "\e[32mCleaning by letters mask\e[0m"
    
    echo "Enter letters mask (e.g., az):"
    read letters_mask
    
    if [[ ! "$letters_mask" =~ ^[a-zA-Z]+$ ]]; then
        echo -e "\e[91mError: Mask must contain only letters\e[0m"
        exit 1
    fi
    
    echo "Searching for folders starting with '$letters_mask' and ending with date"
    
    while IFS= read -r -d '' dir; do
        local basename=$(basename "$dir")
        # Проверяем: начинается с маски и заканчивается _дата
        if [[ "$basename" =~ ^${letters_mask}_[0-9]{6}$ ]]; then
            echo "Found folder: $dir"
            sudo rm -rf "$dir"
            echo "Deleted"
        fi
    done < <(find /home -type d -print0 2>/dev/null)
    
    echo -e "\e[32mCleaning completed\e[0m"
}
