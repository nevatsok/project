#!/bin/bash

script_dir=$(dirname "$(realpath "$0")")

source "$script_dir/clean.sh"

case $clean_method in
    1)
        clean_by_log
        ;;
    2)
        clean_by_time
        ;;
    3)
        clean_by_mask
        ;;
esac
