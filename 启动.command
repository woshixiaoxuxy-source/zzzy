#!/bin/bash
# 历史粘贴板 - 启动器
# 双击此文件即可运行

cd "$(dirname "$0")"
nohup ./历史粘贴板.app/Contents/MacOS/历史粘贴板 > /dev/null 2>&1 &
echo "历史粘贴板 已启动！请在 Dock 栏和菜单栏查看。"
