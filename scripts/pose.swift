// 用 macOS Vision 提取人体骨架。
// 用法: swift pose.swift <图片> [骨架输出.png] [宽 高]
// 打印关节 JSON（归一化坐标，原点左上；left/right 是人物自己的左右）。
// 给了输出路径就画一张骨架图：黑底，人物左侧肢体红/橙，右侧蓝/青，躯干白，头黄。
import Foundation
import Vision
import AppKit

let args = CommandLine.arguments
guard args.count >= 2, let img = NSImage(contentsOfFile: args[1]),
      let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("{\"error\":\"cannot load\"}"); exit(1)
}
let req = VNDetectHumanBodyPoseRequest()
try VNImageRequestHandler(cgImage: cg).perform([req])
guard let obs = req.results?.first else { print("{\"error\":\"no person\"}"); exit(2) }
let pts = try obs.recognizedPoints(.all)

var joints: [String: [Double]] = [:]
for (k, p) in pts where p.confidence > 0.1 {
    joints[k.rawValue.rawValue] = [Double(p.location.x), Double(1 - p.location.y), Double(p.confidence)]
}
let data = try JSONSerialization.data(withJSONObject: ["w": cg.width, "h": cg.height, "joints": joints], options: [.sortedKeys])
print(String(data: data, encoding: .utf8)!)

guard args.count >= 3 else { exit(0) }
let W = args.count >= 5 ? Int(args[3])! : cg.width
let H = args.count >= 5 ? Int(args[4])! : cg.height
let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
func pt(_ n: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
    guard let p = pts[n], p.confidence > 0.1 else { return nil }
    return CGPoint(x: p.location.x * CGFloat(W), y: p.location.y * CGFloat(H))
}
typealias J = VNHumanBodyPoseObservation.JointName
let red = CGColor(red: 1, green: 0.15, blue: 0.1, alpha: 1), orange = CGColor(red: 1, green: 0.6, blue: 0, alpha: 1)
let blue = CGColor(red: 0.1, green: 0.35, blue: 1, alpha: 1), cyan = CGColor(red: 0, green: 0.85, blue: 1, alpha: 1)
let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1), yellow = CGColor(red: 1, green: 0.9, blue: 0, alpha: 1)
let bones: [(J, J, CGColor)] = [
    (.leftShoulder, .leftElbow, orange), (.leftElbow, .leftWrist, orange),
    (.leftHip, .leftKnee, red), (.leftKnee, .leftAnkle, red),
    (.rightShoulder, .rightElbow, cyan), (.rightElbow, .rightWrist, cyan),
    (.rightHip, .rightKnee, blue), (.rightKnee, .rightAnkle, blue),
    (.leftShoulder, .rightShoulder, white), (.leftHip, .rightHip, white),
    (.neck, .root, white), (.neck, .nose, yellow),
]
let lw = CGFloat(max(W, H)) / 90
ctx.setLineCap(.round); ctx.setLineWidth(lw)
for (a, b, c) in bones {
    guard let p = pt(a), let q = pt(b) else { continue }
    ctx.setStrokeColor(c); ctx.move(to: p); ctx.addLine(to: q); ctx.strokePath()
}
for n in [J.leftWrist, .rightWrist, .leftAnkle, .rightAnkle, .nose] {
    guard let p = pt(n) else { continue }
    ctx.setFillColor(n == .nose ? yellow : white)
    ctx.fillEllipse(in: CGRect(x: p.x - lw, y: p.y - lw, width: lw * 2, height: lw * 2))
}
let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2]))
