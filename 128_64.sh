#!/bin/bash

# 初始化
./oled r
./oled +2 " ^o^ Hello Kian!"
./oled s

sleep 1

function get_cpu_usage() {
  # 读取 /proc/stat 的第一行，包含整体 CPU 的统计信息
  CPU=($(head -n 1 /proc/stat))
  IDLE=${CPU[4]} # 第 5 列是 idle 时间
  TOTAL=0

  # 计算总时间
  for VALUE in "${CPU[@]:1}"; do
    TOTAL=$((TOTAL + VALUE))
  done

  # 如果之前没有记录，初始化 PREV_TOTAL 和 PREV_IDLE
  if [ -z "$PREV_TOTAL" ] || [ -z "$PREV_IDLE" ]; then
    PREV_TOTAL=$TOTAL
    PREV_IDLE=$IDLE
    # echo "CPU Usage: 0%"
    return
  fi

  # 计算差值
  DIFF_TOTAL=$((TOTAL - PREV_TOTAL))
  DIFF_IDLE=$((IDLE - PREV_IDLE))

  # 计算 CPU 使用率
  CPU_USAGE=$((100 * (DIFF_TOTAL - DIFF_IDLE) / DIFF_TOTAL))

  # 更新上一次的值
  PREV_TOTAL=$TOTAL
  PREV_IDLE=$IDLE

  # echo "CPU Usage: ${CPU_USAGE}%"
}

function get_cpu_temp() {
  # 获取 CPU 温度
  CPU_TEMP=$(vcgencmd measure_temp | cut -d '=' -f 2 | cut -d "'" -f 1)
}

function get_ram_usage() {
  # 获取内存总量, 单位 GB, 保留一位小数
  RAM_TOTAL=$(free | grep Mem | awk '{printf "%.0f", $2 / 1024}')
  # 获取内存使用量, 单位 GB, 保留一位小数
  RAM_USED=$(free | grep Mem | awk '{printf "%.0f", $3 / 1024}')

  # 获取内存使用率
  RAM_USAGE=$(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')
}

function get_disk_usage() {
  # 获取磁盘总容量
  DISK_TOTAL=$(df | grep '/dev/nvme0n1p2' | awk '{printf "%.0f", $2 / 1024 / 1024}')
  # 获取磁盘使用情况
  DISK_USED=$(df | grep '/dev/nvme0n1p2' | awk '{printf "%.0f", $3 / 1024 / 1024}')
  # 磁盘使用率
  DISK_USAGE=$(df | grep '/dev/nvme0n1p2' | awk '{printf "%.1f%%", $3/$2 * 100.0}')
}

function get_ip() {
  # 获取 IP 地址
  IP=$(hostname -I | cut -d ' ' -f 1)
}

# 循环计数
COUNTER=0

while true
do
  ./oled r

  get_cpu_usage
  get_cpu_temp
  ./oled +1 "CPU:${CPU_USAGE}%|${CPU_TEMP}℃"

  get_ram_usage
  # 如果计数偶数则打印使用率，否则打印使用量
  if [ $((COUNTER % 2)) -eq 0 ]; then
    ./oled +2 "RAM:${RAM_USAGE}"
  else
    ./oled +2 "RAM:${RAM_USED}/${RAM_TOTAL}M"
  fi

  get_disk_usage
  # 如果计数偶数则打印使用率，否则打印使用量
  if [ $((COUNTER % 2)) -eq 0 ]; then
    ./oled +3 "Disk:${DISK_USAGE}"
  else
    ./oled +3 "Disk:${DISK_USED}/${DISK_TOTAL}G"
  fi

  get_ip
  ./oled +4 "IP:${IP}"
  ./oled s

  COUNTER=$((COUNTER + 1))
  
  sleep 2.5
done
