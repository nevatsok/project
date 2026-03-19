#!/bin/bash

# Генерация случайного IP
generate_ip() {
    echo "$((RANDOM % 256)).$((RANDOM % 256)).$((RANDOM % 256)).$((RANDOM % 256))"
}

# Коды ответа (с комментариями в коде, как просили)
codes=(200 201 400 401 403 404 500 501 502 503)
# 200 OK
# 201 Created
# 400 Bad Request
# 401 Unauthorized
# 403 Forbidden
# 404 Not Found
# 500 Internal Server Error
# 501 Not Implemented
# 502 Bad Gateway
# 503 Service Unavailable

methods=("GET" "POST" "PUT" "PATCH" "DELETE")
agents=("Mozilla" "Google Chrome" "Opera" "Safari" "Internet Explorer" "Microsoft Edge" "Crawler and bot" "Library and net tool")

mkdir -p ./access_logs

# Генерируем 5 файлов (дней)
for day in {1..5}; do
    log_file="./access_logs/day_$day.log"
    > "$log_file"

    records=$((RANDOM % 901 + 100))  # от 100 до 1000

    # Базовая дата: последовательные дни марта 2026
    base_date="2026-03-$(printf "%02d" $day)"
    start_ts=$(date -d "$base_date 00:00:00" +%s)
    end_ts=$(date -d "$base_date 23:59:59" +%s)

    # Генерируем случайные временные метки в пределах дня
    timestamps=()
    for ((i=0; i<records; i++)); do
        timestamps[$i]=$((RANDOM % (end_ts - start_ts + 1) + start_ts))
    done

    # Сортируем, чтобы даты шли по возрастанию
    IFS=$'\n' sorted_timestamps=($(sort -n <<<"${timestamps[*]}"))
    unset IFS

    # Создаём записи
    for ts in "${sorted_timestamps[@]}"; do
        ip=$(generate_ip)
        code=${codes[$((RANDOM % ${#codes[@]}))]}
        method=${methods[$((RANDOM % ${#methods[@]}))]}
        agent=${agents[$((RANDOM % ${#agents[@]}))]}
        url="/page$((RANDOM % 100)).html"
        size=$((RANDOM % 5000 + 100))  # случайный размер в байтах
        referer="-"  # всегда дефис, так как не требуется генерировать

        # Формат даты: [дд/мес/год:чч:мм:сс +0000]
        date_str=$(LC_TIME=en_US.UTF-8 date -d "@$ts" +"[%d/%b/%Y:%H:%M:%S +0000]")
        request="\"$method $url HTTP/1.1\""

        # Полная строка лога в combined формате
        echo "$ip - - $date_str $request $code $size \"$referer\" \"$agent\"" >> "$log_file"
    done
done

echo -e "\e[32mLogs successfully created in ./access_logs\e[0m"
