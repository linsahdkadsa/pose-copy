"""把 pose.swift 的 Vision 关节 JSON 转成 draw.swift 用的手标格式（缺的关节留空，之后手补）。
用法: python3 vision2joints.py vision.json out.json"""
import json, sys
M = {"nose": "nose_joint", "neck": "neck_1_joint", "Rsh": "right_shoulder_1_joint", "Lsh": "left_shoulder_1_joint",
     "Relb": "right_forearm_joint", "Rwri": "right_hand_joint", "Lelb": "left_forearm_joint", "Lwri": "left_hand_joint",
     "root": "root", "Rhip": "right_upLeg_joint", "Lhip": "left_upLeg_joint",
     "Rknee": "right_leg_joint", "Rank": "right_foot_joint", "Lknee": "left_leg_joint", "Lank": "left_foot_joint"}
j = json.load(open(sys.argv[1]))["joints"]
out = {k: [round(j[v][0], 3), round(j[v][1], 3)] for k, v in M.items() if v in j and j[v][2] > 0.2}
if "nose" not in out and "head_joint" in j:
    out["nose"] = [round(j["head_joint"][0], 3), round(j["head_joint"][1], 3)]
json.dump(out, open(sys.argv[2], "w"))
print(sys.argv[2], "缺:", [k for k in M if k not in out])
