// 照手标关节画骨架图。用法: swift draw.swift joints.json out.png 宽 高
// joints.json: {"nose":[x,y], ...} 归一化坐标，原点左上；L/R 是人物自己的左右。
// 颜色：人物左腿红、左臂橙，右腿蓝、右臂青，躯干白，头黄。
import Foundation
import AppKit

let a = CommandLine.arguments
let j = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: a[1]))) as! [String: [Double]]
let bg = a.count > 5 ? NSImage(contentsOfFile: a[5])?.cgImage(forProposedRect: nil, context: nil, hints: nil) : nil
let W = bg?.width ?? Int(a[3])!, H = bg?.height ?? Int(a[4])!
let ctx = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
if let bg { ctx.draw(bg, in: CGRect(x: 0, y: 0, width: W, height: H)) }
else { ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H)) }
func p(_ k: String) -> CGPoint? { j[k].map { CGPoint(x: $0[0] * Double(W), y: (1 - $0[1]) * Double(H)) } }
func c(_ r: Double, _ g: Double, _ b: Double) -> CGColor { CGColor(red: r, green: g, blue: b, alpha: 1) }
let bones: [(String, String, CGColor)] = [
    ("neck", "nose", c(1, 0.9, 0)),
    ("neck", "Lsh", c(1, 1, 1)), ("neck", "Rsh", c(1, 1, 1)), ("neck", "root", c(1, 1, 1)),
    ("root", "Lhip", c(1, 1, 1)), ("root", "Rhip", c(1, 1, 1)),
    ("Lsh", "Lelb", c(1, 0.6, 0)), ("Lelb", "Lwri", c(1, 0.6, 0)),
    ("Rsh", "Relb", c(0, 0.85, 1)), ("Relb", "Rwri", c(0, 0.85, 1)),
    ("Lhip", "Lknee", c(1, 0.15, 0.1)), ("Lknee", "Lank", c(1, 0.15, 0.1)), ("Lank", "Ltoe", c(1, 0.15, 0.1)),
    ("Rhip", "Rknee", c(0.1, 0.35, 1)), ("Rknee", "Rank", c(0.1, 0.35, 1)), ("Rank", "Rtoe", c(0.1, 0.35, 1)),
]
let lw = CGFloat(max(W, H)) / 70
ctx.setLineCap(.round); ctx.setLineWidth(lw)
for (x, y, col) in bones {
    guard let s = p(x), let e = p(y) else { continue }
    ctx.setStrokeColor(col); ctx.move(to: s); ctx.addLine(to: e); ctx.strokePath()
}
for k in j.keys { if let q = p(k) {
    ctx.setFillColor(c(1, 1, 1)); ctx.fillEllipse(in: CGRect(x: q.x - lw * 0.7, y: q.y - lw * 0.7, width: lw * 1.4, height: lw * 1.4))
} }
let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: a[2]))
