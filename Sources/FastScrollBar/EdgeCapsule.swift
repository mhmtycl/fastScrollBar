import SwiftUI

/// A capsule glued to the trailing screen edge: rounded on the leading side,
/// and at the top and bottom it is born from the screen edge through a concave
/// curve (like the iPhone camera-button zoom dial).
/// The frame must be `curve` taller than the capsule on both ends.
struct EdgeCapsule: Shape {
    var curve: CGFloat
    var radius: CGFloat = 15
    /// true: the vertical line on the screen edge is left open (stroke only).
    var edgeOpen = false

    func path(in r: CGRect) -> Path {
        let f = curve, w = r.width, h = r.height
        let R = min(radius, (h - 2 * f) / 2, w - f)
        // Describe the top half; the bottom half is its vertical mirror,
        // so both ends are exactly identical.
        let top: [(point: CGPoint, control: CGPoint?)] = [
            (CGPoint(x: w - f, y: f), CGPoint(x: w, y: f)),   // concave curve
            (CGPoint(x: R, y: f), nil),
            (CGPoint(x: 0, y: f + R), CGPoint(x: 0, y: f)),   // rounded corner
        ]
        let mirror = { (q: CGPoint) in CGPoint(x: q.x, y: h - q.y) }
        var p = Path()
        p.move(to: CGPoint(x: w, y: 0))
        for a in top {
            if let k = a.control { p.addQuadCurve(to: a.point, control: k) } else { p.addLine(to: a.point) }
        }
        p.addLine(to: mirror(top[2].point))
        for (i, a) in top.enumerated().reversed() {
            let target = i == 0 ? CGPoint(x: w, y: h) : mirror(top[i - 1].point)
            if let k = a.control { p.addQuadCurve(to: target, control: mirror(k)) } else { p.addLine(to: target) }
        }
        if !edgeOpen { p.closeSubpath() }
        return p.offsetBy(dx: r.minX, dy: r.minY)
    }
}
