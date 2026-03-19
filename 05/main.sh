#!/bin/bash

if [ $# -ne 1 ] || [[ ! "$1" =~ ^[1-4]$ ]]; then
    echo -e "\e[91mUsage: $0 [1|2|3|4]\e[0m"
    exit 1
fi

all_logs=$(cat ../04/access_logs/*.log)

if [ -z "$all_logs" ]; then
    echo -e "\e[91mError: No log files found in ../04/access_logs/\e[0m"
    exit 1
fi

case $1 in
    1)
        echo "$all_logs" | sort -n -k9
        ;;
    2)
        echo "$all_logs" | awk '{print $1}' | sort -u
        ;;
    3)
        echo "$all_logs" | awk '$9 ~ /^[45]/'
        ;;
    4)
        echo "$all_logs" | awk '$9 ~ /^[45]/ {print $1}' | sort -u
        ;;
esac
