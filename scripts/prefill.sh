#!/bin/bash
# Vision 预填：对每张白膜跑 pose + vision2joints，在图片旁边写 <图名>.预填.json，给 标关节.html 载入。
# 用法: tools/prefill.sh 白膜1.jpg 白膜2.jpg ...
D=$(cd "$(dirname "$0")" && pwd)
[ -x "$D/pose" ] || swiftc -O "$D/pose.swift" -o "$D/pose"
for f in "$@"; do
  t=$(mktemp)
  if "$D/pose" "$f" > "$t"; then python3 "$D/vision2joints.py" "$t" "${f%.*}.预填.json"
  else echo '{}' > "${f%.*}.预填.json"; echo "$f: Vision 没认出人，写了空预填，标关节时从头点"; fi
  rm -f "$t"
done
