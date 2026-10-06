import SwiftUI

/// A fast-scroll dial for the trailing edge of long content.
///
/// A short strip of tick marks, one per item. A fixed indicator in the middle
/// shows the current item. Press and drag: the ruler slides under your finger
/// (drag down = later items), every item gives a light selection haptic and
/// `preview` shows a glass card to the left. On release, `onSelect` is called
/// with the chosen index (only if it changed). Nothing behind the dial moves
/// while you drag.
///
/// It knows nothing about what it counts: pages, sections, messages. It works
/// with indices; the caller supplies the preview and does the scrolling.
public struct FastScrollBar<Preview: View>: View {
    let count: Int
    let activeIndex: Int
    let isVisible: Bool
    let accessibilityName: Text
    let accessibilityValue: (Int) -> String
    var onPress: () -> Void
    let onSelect: (Int) -> Void
    let preview: (Int) -> Preview

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false
    @State private var startIndex = 0
    @State private var selected = 0

    // Static stored properties are not allowed in generic types: computed constants.
    private static var height: CGFloat { 170 }
    private static var width: CGFloat { 30 }
    /// Concave curve where the capsule meets the screen edge (pt).
    private static var curve: CGFloat { 12 }
    /// Spacing between tick marks (pt).
    private static var spacing: CGFloat { 9 }
    private var shown: Int { isPressed ? selected : activeIndex }

    public init(count: Int,
                activeIndex: Int,
                isVisible: Bool = true,
                accessibilityName: Text = Text("Fast scroll"),
                accessibilityValue: @escaping (Int) -> String = { "\($0 + 1)" },
                onPress: @escaping () -> Void = {},
                onSelect: @escaping (Int) -> Void,
                @ViewBuilder preview: @escaping (Int) -> Preview) {
        self.count = count
        self.activeIndex = activeIndex
        self.isVisible = isVisible
        self.accessibilityName = accessibilityName
        self.accessibilityValue = accessibilityValue
        self.onPress = onPress
        self.onSelect = onSelect
        self.preview = preview
    }

    public var body: some View {
        HStack(spacing: 8) {
            if isPressed, (0..<count).contains(selected) {
                preview(selected)
                    .transition(.scale(scale: 0.9, anchor: .trailing).combined(with: .opacity))
            }
            strip
        }
        .opacity(isVisible || isPressed ? 1 : 0)
        .allowsHitTesting(isVisible || isPressed)
        .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: isPressed)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: isVisible)
    }

    private var strip: some View {
        Canvas { ctx, size in
            let mid = size.height / 2
            for i in 0..<count {
                let y = mid + CGFloat(i - shown) * Self.spacing
                guard y > -2, y < size.height + 2 else { continue }
                let major = i == 0 || (i + 1) % 5 == 0
                let length: CGFloat = isPressed ? (major ? 15 : 9) : (major ? 12 : 7)
                let opacity: Double = isPressed ? (major ? 0.85 : 0.55) : (major ? 0.3 : 0.22)
                let r = CGRect(x: size.width - 5 - length, y: y - 0.75, width: length, height: 1.5)
                ctx.fill(Path(roundedRect: r, cornerRadius: 0.75), with: .color(.white.opacity(opacity)))
            }
            // Fixed indicator: the current (or selected) item.
            let g: CGFloat = isPressed ? 22 : 16
            let k: CGFloat = isPressed ? 2.5 : 2
            let r = CGRect(x: size.width - 3 - g, y: mid - k / 2, width: g, height: k)
            ctx.fill(Path(roundedRect: r, cornerRadius: k / 2), with: .color(.white.opacity(isPressed ? 1 : 0.55)))
        }
        // The ruler fades out softly at both ends.
        .mask {
            LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.2),
                                   .init(color: .black, location: 0.8), .init(color: .clear, location: 1)],
                           startPoint: .top, endPoint: .bottom)
        }
        .frame(width: Self.width, height: Self.height)
        .background {
            if isPressed {
                // Like the camera-button UI: the capsule comes out of the screen
                // edge. Glass is drawn on a plain rect and masked to the shape,
                // because system glass renders custom concave shapes unevenly
                // at the two ends.
                Color.clear
                    .glassEffect(.regular, in: .rect)
                    .mask(EdgeCapsule(curve: Self.curve))
                    .overlay(EdgeCapsule(curve: Self.curve, edgeOpen: true)
                        .stroke(LinearGradient(colors: [.white.opacity(0.45), .white.opacity(0.1), .white.opacity(0.3)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 0.5))
                    .frame(width: Self.width, height: Self.height + 2 * Self.curve)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .contentShape(.rect)
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { g in
                    if !isPressed {
                        startIndex = activeIndex
                        selected = activeIndex
                        isPressed = true
                        onPress()
                    }
                    let n = startIndex + Int((g.translation.height / Self.spacing).rounded())
                    let clamped = min(max(n, 0), count - 1)
                    if clamped != selected { selected = clamped }
                }
                .onEnded { _ in
                    let target = selected
                    isPressed = false
                    if target != activeIndex, (0..<count).contains(target) { onSelect(target) }
                }
        )
        .sensoryFeedback(.selection, trigger: selected)
        .accessibilityElement()
        .accessibilityLabel(accessibilityName)
        .accessibilityValue(accessibilityValue(activeIndex))
        .accessibilityAdjustableAction { direction in
            let i = activeIndex
            switch direction {
            case .increment: if i + 1 < count { onSelect(i + 1) }
            case .decrement: if i > 0 { onSelect(i - 1) }
            @unknown default: break
            }
        }
    }
}
