#!/bin/bash

echo "====================================="
echo "+++ System Performance Statistics +++"
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo

echo "--- CPU Usage ---"
mpstat 1 1 | awk '/Average/ && $12 ~ /[0-9.]+/ {print 100 - $12 "% CPU used"}'
echo "-----------------"
echo

echo "--- Memory Usage ---"
free -m | awk 'NR==2{printf "Memory Usage: %.2f%% (%s/%s MB)\n", $3*100/$2, $3, $2}'
echo "--------------------"
echo

echo "--- Load Average ---"
cat /proc/loadavg | awk '{print "Load Average (1m, 5m, 15m): " $1, $2, $3}'
echo "--------------------"
echo 

echo "--- Disk Usage ---"
df -h --total | awk '/total/ {print "Disk Usage: "$5" used ("$3" of "$2")"}'
echo "------------------"
echo 

echo "--- Disk I/O ---"
iostat -dx 1 1 | awk '/sda/ {print "Device: "$1", Read/s: "$3", Write/s: "$4}'
echo "----------------"
echo 

echo "--- Network Usage ---"
sar -n DEV 1 1 | grep Average | grep -v lo | awk '{printf "Interface: %-10s RX/s: %5s KB  TX/s: %5s KB\n", $2, $3, $4}'
echo "---------------------"
echo 

echo "--- Top 5 CPU Consuming Processes ---"
ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6
echo "-------------------------------------"
echo

echo "--- System Uptime ---"
uptime -p
echo "---------------------"
echo
echo "====================================="
