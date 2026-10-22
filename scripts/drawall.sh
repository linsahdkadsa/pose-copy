#!/bin/bash
# 把 标关节.html 导出的 <图名>.joints.json 批量画成「白膜叠骨架_<图名>.png」，底图用同文件夹里同名的图片。
# 用法: tools/drawall.sh 文件夹
D=$(cd "$(dirname "$0")" && pwd)
[ -x "$D/draw" ] || swiftc -O "$D/draw.swift" -o "$D/draw"
dir=${1:-.}
for j in "$dir"/*.joints.json; do
  [ -e "$j" ] || { echo "$dir 里没有 .joints.json"; exit 1; }
  stem=$(basename "$j" .joints.json)
  img=$(ls "$dir/$stem".{jpg,jpeg,png,webp,JPG,JPEG,PNG} 2>/dev/null | head -1)
  [ -n "$img" ] || { echo "找不到底图: $stem"; continue; }
  "$D/draw" "$j" "$dir/白膜叠骨架_$stem.png" 0 0 "$img" && echo "✓ 白膜叠骨架_$stem.png"
done
