# FastScrollBar

A fast-scroll dial for the trailing edge of long SwiftUI content, in the style of the
iPhone camera-button zoom dial. It was built for the long tafsir pages in the
Hel Min Mezid app, where going back to something near the top otherwise means dozens of swipes.

- A short strip of tick marks, one per item, faint at rest. A fixed indicator in the
  middle marks the current item.
- **Press and drag**: a Liquid Glass capsule comes out of the screen edge, the ruler
  slides under your finger (drag down = later items), a glass preview card appears to
  the left, and each step gives a light selection haptic. The content behind stays put.
- **Release**: `onSelect` is called with the chosen index.
- VoiceOver: adjustable element (swipe up/down to step). Reduce Motion is respected.

## Requirements

- iOS 26 or later (uses `glassEffect`)
- Xcode 26 or later, Swift 6.2

## Installation

### Swift Package Manager (Xcode)

1. In Xcode choose **File > Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/mhmtycl/fastScrollBar`
3. Pick the `main` branch (or a tagged version once one exists) and add the
   **FastScrollBar** library to your app target.
4. `import FastScrollBar` in the file where you use it.

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/mhmtycl/fastScrollBar", branch: "main"),
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "FastScrollBar", package: "fastScrollBar"),
    ]),
]
```

### Copy the files

The component is two files with no dependencies. You can also copy
`Sources/FastScrollBar/FastScrollBar.swift` and `EdgeCapsule.swift` straight into your
project (make the types `public` only if you put them in a separate module).

## Usage

Put the dial in an overlay on the trailing edge, above your scrolling content.

```swift
import SwiftUI
import FastScrollBar

struct PagesView: View {
    let pages: [Page]
    @State private var current: Int? = 0
    @State private var dialVisible = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(pages.indices, id: \.self) { i in
                    PageView(page: pages[i])
                        .containerRelativeFrame(.vertical)
                        .id(i)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $current)
        .scrollIndicators(.hidden)               // hide the system scroll indicator
        .overlay(alignment: .trailing) {
            FastScrollBar(count: pages.count,
                          activeIndex: current ?? 0,
                          isVisible: dialVisible,
                          onSelect: { current = $0 }) { i in
                PreviewCard(page: pages[i])      // shown to the left while dragging
            }
            .frame(maxHeight: .infinity)
            .ignoresSafeArea(edges: .vertical)   // center on the full screen
        }
    }
}
```

Things to know:

1. **Track the current item yourself.** The dial does not read your scroll view. Give it
   the index of the item being read (`activeIndex`), here via `scrollPosition(id:)`.
2. **Jump in `onSelect`.** When the finger lifts, you get the chosen index; set your scroll
   position to it. Nothing scrolls while the finger is down; only the preview changes.
3. **Control visibility.** `isVisible` is yours: always `true`, tied to a toolbar, or
   shown while scrolling and hidden after a delay (see the demo). While pressed, the dial
   stays visible regardless.
4. **Hide the system scroll indicator** (`.scrollIndicators(.hidden)`), or you will have
   two scroll bars.
5. **Safe area.** `.frame(maxHeight: .infinity)` plus `.ignoresSafeArea(edges: .vertical)`
   centers the dial on the whole screen, so it does not shift when bars appear or hide.
6. **Preview is any view.** Show a thumbnail, a title, a page number, a date. Keep it
   light, it is rebuilt on every step. Use `onPress` to warm up anything slow (e.g.
   pre-decode images) when the finger lands.

### Parameters

| Parameter | Meaning |
| --- | --- |
| `count` | number of ticks (items) |
| `activeIndex` | index of the item currently being read |
| `isVisible` | show/hide the dial (default `true`) |
| `accessibilityName` | VoiceOver label (default "Fast scroll") |
| `accessibilityValue` | VoiceOver value for an index (default `"\(i + 1)"`) |
| `onPress` | called once when the finger lands |
| `onSelect` | called on release with the chosen index, only if it changed |
| `preview` | view for the card left of the dial, built for the selected index |

### Tuning

Dimensions are constants at the top of `FastScrollBar` (`height` 170 pt, `width` 30 pt,
tick `spacing` 9 pt, edge `curve` 12 pt). Change them there. For hundreds of items you
may want to draw one tick per several items and map the drag distance accordingly.

## Try the demo

`Sources/FastScrollBarDemo/DemoView.swift` is a 60-page paging example. To run it,
create a new iOS app in Xcode, add this package, add the **FastScrollBarDemo** library to
the app target, and show it:

```swift
import SwiftUI
import FastScrollBarDemo

@main struct DemoApp: App {
    var body: some Scene { WindowGroup { DemoView() } }
}
```

Or open `DemoView.swift` in Xcode and use the `#Preview` canvas.

## How it works

- `Canvas` draws the ticks. Tick `i` is drawn at `mid + (i - shown) * spacing`, so the
  ruler "moves" while the indicator stays still. Every 5th tick (and the first) is longer.
- A `DragGesture(minimumDistance: 0)` with `highPriorityGesture` starts on touch-down.
  The selected index is `startIndex + round(translation.height / spacing)`, clamped.
- The capsule is `EdgeCapsule`, a custom `Shape`: the top half is described once and the
  bottom half is its mirror, so both ends match. System glass draws custom concave shapes
  unevenly, so glass is applied to a plain rect and then masked with the shape.
- `.sensoryFeedback(.selection, trigger: selected)` gives the haptic.
- The type is generic over the preview view and knows nothing about what it counts, so
  it works for pages, sections, messages or anything with an index.

## License

MIT
