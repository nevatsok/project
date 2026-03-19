#!/bin/bash

source functions.sh

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
