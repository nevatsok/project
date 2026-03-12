#!/bin/bash
source input.sh

log_file="$(dirname "$(realpath "$0")")/report.log"
date_suffix=$(date +"%d%m%y")

# Массив для отслеживания использованных родительских папок
used_parent_dirs=()

memcheck() {
    local avail=$(df -h / | awk 'NR==2 {print $4}')
    if [[ "$avail" == *M ]]; then
        echo "1"
    else
        echo "0"
    fi
}

gen_folder_name() {
    local idx=$1
    local base="$folders_names"
    local min_len=5
    local base_len=${#base}
    local base_repeats=0
    if [ $base_len -lt $min_len ]; then
        base_repeats=$((min_len - base_len))
    fi
    local repeats=$((base_repeats + idx))
    local last_char="${base: -1}"
    local name="$base"
    for ((i=0; i<repeats; i++)); do
        name+="$last_char"
    done
    echo "$name"
}

gen_file_name() {
    local idx=$1
    local base="$file_base"
    local min_len=5
    local base_len=${#base}
    local base_repeats=0
    if [ $base_len -lt $min_len ]; then
        base_repeats=$((min_len - base_len))
    fi
    local repeats=$((base_repeats + idx))
    local last_char="${base: -1}"
    local name="$base"
    for ((i=0; i<repeats; i++)); do
        name+="$last_char"
    done
    echo "$name"
}

# Функция получения новой случайной директории (не использованной ранее)
get_new_random_dir() {
    local max_attempts=1000
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        local random_dir=$(sudo find /home -type d | shuf -n 1)
        
        if [ -n "$random_dir" ]; then
            # Проверяем, не использовали ли мы уже эту директорию
            local dir_used=0
            for used in "${used_parent_dirs[@]}"; do
                if [ "$used" == "$random_dir" ]; then
                    dir_used=1
                    break
                fi
            done
            
            if [ $dir_used -eq 0 ]; then
                used_parent_dirs+=("$random_dir")
                echo "$random_dir"
                return 0
            fi
        fi
        
        ((attempt++))
    done
    
    echo ""
    return 1
}

create_folders_and_files() {
    local total_folders=0
    
    # Очищаем массив использованных родительских папок
    used_parent_dirs=()
    
    # Создаем папки, пока есть место
    while [ $(memcheck) -eq 0 ]; do
        # Получаем новую, еще не использованную родительскую директорию
        local parent_dir=$(get_new_random_dir)
        
        if [ -z "$parent_dir" ]; then
            echo -e "\e[91mError: No more unique directories available.\e[0m"
            echo "No more unique directories available" >> "$log_file"
            break
        fi
        
        echo "Using new parent directory: $parent_dir" >> "$log_file"
        
        # Рандомное количество вложенных папок в этой директории (до 100)
        local nested_folders=$((RANDOM % 100 + 1))
        
        for ((i=0; i<nested_folders; i++)); do
            # Проверяем место перед созданием каждой вложенной папки
            if [ $(memcheck) -eq 1 ]; then
                echo -e "\e[91mMemory is full. Stopping.\e[0m"
                echo "Memory is full. Stopping." >> "$log_file"
                exit 1
            fi
            
            local folder_name=$(gen_folder_name $i)_$date_suffix
            local folder_path="$parent_dir/$folder_name"
            
            sudo mkdir -p "$folder_path"
            echo "PATH: $folder_path, DATE: $(date +"%d:%m:%y"), NAME: $folder_name" >> "$log_file"
            
            # Рандомное количество файлов в этой папке (до 248)
            local files_num=$((RANDOM % 248 + 1))
            
            for ((j=0; j<files_num; j++)); do
                # Проверка памяти перед каждым файлом
                if [ $(memcheck) -eq 1 ]; then
                    echo -e "\e[91mMemory is full. Stopping.\e[0m"
                    echo "Memory is full. Stopping." >> "$log_file"
                    exit 1
                fi
                
                local file_name=$(gen_file_name $j)_${date_suffix}.$file_ext
                local file_path="$folder_path/$file_name"
                
                sudo touch "$file_path"
                sudo dd if=/dev/zero of="$file_path" bs=1M count=$file_size 2>/dev/null
                
                echo "PATH: $file_path, DATE: $(date +"%d:%m:%y"), NAME: $file_name, SIZE: ${file_size}Mb" >> "$log_file"
            done
            
            ((total_folders++))
        done
    done
    
    echo "Created $total_folders folders total in ${#used_parent_dirs[@]} different parent directories" >> "$log_file"
}
