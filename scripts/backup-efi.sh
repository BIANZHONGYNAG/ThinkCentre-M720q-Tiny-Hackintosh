#!/bin/bash
# 完整备份当前 ESP 上的 EFI 到 ~/efi-backups/EFI-<时间戳>
set -eu

SRC="${1:-/Volumes/EFI}"
STAMP=$(date +%Y%m%d-%H%M%S)
DEST="$HOME/efi-backups/EFI-$STAMP"

if [ ! -d "$SRC/EFI" ]; then
  echo "找不到 $SRC/EFI"
  echo "先挂载 ESP：sudo diskutil mount disk0s1"
  exit 1
fi

mkdir -p "$DEST"
ditto "$SRC/EFI" "$DEST/EFI"

FILES=$(find "$DEST/EFI" -type f | wc -l | tr -d ' ')
BYTES=$(find "$DEST/EFI" -type f -exec stat -f '%z' {} \; | awk '{s+=$1} END {print s}')
SHA=$(shasum -a 256 "$DEST/EFI/OC/config.plist" | awk '{print $1}')

printf '%s\n' "备份完成：$DEST" "" \
  "文件数   $FILES" "总字节   $BYTES" "config   sha256 $SHA" \
  "" "回滚：" \
  "  sudo diskutil mount disk0s1" \
  "  cp -R \"$DEST/EFI\"/* /Volumes/EFI/EFI/" \
  "  sudo diskutil unmount /Volumes/EFI"
