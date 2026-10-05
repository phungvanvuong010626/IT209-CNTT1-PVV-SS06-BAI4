#!/bin/bash

# Kịch bản giám sát hệ thống (loop-monitor.sh)
# Ghi thời gian hiện tại vào tệp /tmp/monitor.log mỗi 5 giây

LOG_FILE="/tmp/monitor.log"

while true; do
    echo "System time: $(date)" >> "$LOG_FILE"
    sleep 5
done
