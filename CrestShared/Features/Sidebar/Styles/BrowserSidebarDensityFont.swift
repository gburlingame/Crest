import SwiftUI

struct BrowserSidebarDensityFont: ViewModifier {
    let scale: Double
    let supportsTouch: Bool
    @ScaledMetric(relativeTo: .body) private var textSizeScale = 1.0

    func body(content: Content) -> some View {
        let size =
            BrowserSidebarDensity.bodySize(touch: supportsTouch)
            * textSizeScale * BrowserSidebarDensity(scale).scale
        // A pointer sidebar's body size differs from the platform's body text, so
        // only touch can inherit that text at the default scale.
        content.font(supportsTouch && scale == 1 ? nil : .system(size: size))
    }
}
