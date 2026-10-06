import SwiftUI
import FastScrollBar

/// A long vertical list of "pages". Shows the dial on the trailing edge while
/// scrolling; press and drag it to jump back and forth.
public struct DemoView: View {
    private let pages = Array(0..<60)
    @State private var current: Int? = 0
    @State private var dialVisible = false
    @State private var hideTask: Task<Void, Never>?

    public init() {}

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(pages, id: \.self) { i in
                    PageCard(number: i + 1)
                        .containerRelativeFrame(.vertical)
                        .id(i)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $current)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .ignoresSafeArea()
        .onChange(of: current) { _, _ in showDialBriefly() }
        .overlay(alignment: .trailing) {
            FastScrollBar(count: pages.count,
                          activeIndex: current ?? 0,
                          isVisible: dialVisible,
                          accessibilityName: Text("Page dial"),
                          accessibilityValue: { "Page \($0 + 1) of \(pages.count)" },
                          onSelect: { current = $0 }) { i in
                PreviewCard(number: i + 1)
            }
            .frame(maxHeight: .infinity)
            .ignoresSafeArea(edges: .vertical)
        }
    }

    /// Show the dial while scrolling, hide it shortly after it stops.
    private func showDialBriefly() {
        dialVisible = true
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            if !Task.isCancelled { dialVisible = false }
        }
    }
}

private struct PageCard: View {
    let number: Int
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hue: Double(number % 12) / 12, saturation: 0.55, brightness: 0.55),
                                    Color(hue: Double((number + 3) % 12) / 12, saturation: 0.7, brightness: 0.25)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Text("\(number)")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

private struct PreviewCard: View {
    let number: Int
    var body: some View {
        HStack(spacing: 12) {
            PageCard(number: number)
                .frame(width: 393, height: 852)
                .scaleEffect(84.0 / 393.0, anchor: .topLeading)
                .frame(width: 84, height: 852 * 84.0 / 393.0, alignment: .topLeading)
                .clipShape(.rect(cornerRadius: 12))
            Text("Page \(number)")
                .font(.system(size: 20, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .fixedSize()
        }
        .padding(.leading, 8)
        .padding(.trailing, 16)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .accessibilityHidden(true)
    }
}

#Preview { DemoView() }
