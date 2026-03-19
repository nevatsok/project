#!/bin/bash

# Проверка параметра
if [ $# -ne 1 ] || [[ ! "$1" =~ ^[1-4]$ ]]; then
    echo "Usage: $0 [1|2|3|4]"
    exit 1
fi

# Собираем все логи в один поток
all_logs=$(cat ../04/access_logs/*.log 2>/dev/null)

if [ -z "$all_logs" ]; then
    echo "Error: No log files found in ../04/access_logs/"
    exit 1
fi

case $1 in
    1)
        # Все записи, отсортированные по коду ответа (9-е поле)
        echo "$all_logs" | sort -n -k9
        ;;
    2)
        # Все уникальные IP (1-е поле)
        echo "$all_logs" | awk '{print $1}' | sort -u
        ;;
    3)
        # Все запросы с ошибками (код 4xx или 5xx)
        echo "$all_logs" | awk '$9 ~ /^[45]/'
        ;;
    4)
        # Уникальные IP из ошибочных запросов
        echo "$all_logs" | awk '$9 ~ /^[45]/ {print $1}' | sort -u
        ;;
esac
