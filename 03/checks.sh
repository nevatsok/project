#!/bin/bash
clean_method=$1

if [ "$#" -ne 1 ]; then
    echo -e "\e[91mError. The script must be run with 1 parameter.\e[0m"
    exit 1
fi

if [[ ! "$clean_method" =~ ^[1-3]$ ]]; then
    echo -e "\e[91mError. Parameter must be 1, 2 or 3.\e[0m"
    exit 1
fi
