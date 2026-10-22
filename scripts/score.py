"""姿势打分：比较骨骼方向角（不受取景大小、位置影响）。
用法: python3 score.py ref.json a.json b.json ...
每条骨头算画面里的方向角，和参考差多少度；再算一遍左右互换（镜像）后的差，镜像分更低就标出来。
"""
import json, math, sys

BONES = {
    "左大臂": ("left_shoulder_1_joint", "left_forearm_joint"),
    "左小臂": ("left_forearm_joint", "left_hand_joint"),
    "右大臂": ("right_shoulder_1_joint", "right_forearm_joint"),
    "右小臂": ("right_forearm_joint", "right_hand_joint"),
    "左大腿": ("left_upLeg_joint", "left_leg_joint"),
    "左小腿": ("left_leg_joint", "left_foot_joint"),
    "右大腿": ("right_upLeg_joint", "right_leg_joint"),
    "右小腿": ("right_leg_joint", "right_foot_joint"),
    "躯干": ("root", "neck_1_joint"),
}


def load(p):
    d = json.load(open(p))
    w, h = d["w"], d["h"]
    return {k: (v[0] * w, v[1] * h) for k, v in d["joints"].items()}


def angle(j, a, b):
    if a not in j or b not in j:
        return None
    (x1, y1), (x2, y2) = j[a], j[b]
    return math.degrees(math.atan2(y2 - y1, x2 - x1))


def swap(name):
    return name.replace("left", "@").replace("right", "left").replace("@", "right")


def diff(a, b):
    d = abs(a - b) % 360
    return min(d, 360 - d)


def score(ref, j, mirror=False):
    per, ds = {}, []
    for name, (a, b) in BONES.items():
        ra = angle(ref, a, b)
        ja = angle(j, swap(a), swap(b)) if mirror else angle(j, a, b)
        if ra is None or ja is None:
            per[name] = None
            continue
        per[name] = diff(ra, ja)
        ds.append(per[name])
    return (sum(ds) / len(ds) if ds else 999), per


ref = load(sys.argv[1])
for p in sys.argv[2:]:
    j = load(p)
    s, per = score(ref, j)
    m, _ = score(ref, j, mirror=True)
    worst = sorted(((v, k) for k, v in per.items() if v is not None), reverse=True)[:3]
    flag = "  ⚠️ 疑似镜像" if m + 10 < s else ""
    miss = [k for k, v in per.items() if v is None]
    print(f"{p.split('/')[-1]:14s} 平均偏差 {s:5.1f}°  最差: " + "、".join(f"{k}{v:.0f}°" for v, k in worst)
          + (f"  缺: {'、'.join(miss)}" if miss else "") + flag)
