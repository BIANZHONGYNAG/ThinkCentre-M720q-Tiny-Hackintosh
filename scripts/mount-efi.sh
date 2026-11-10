#!/bin/bash
# 挂载内置盘的 ESP（需要管理员密码，脚本会让你自己输）
set -eu

echo "当前磁盘："
diskutil list | grep -E '^/dev/disk|EFI' || true
echo
printf '要挂载的 ESP 设备（例如 disk0s1）: '
read -r DEV
[ -n "$DEV" ] || { echo "未输入，退出"; exit 1; }

sudo diskutil mount "$DEV"
echo
mount | grep -i '/Volumes/EFI' || echo "未挂载成功"
echo
echo "卸载：sudo diskutil unmount /Volumes/EFI"
