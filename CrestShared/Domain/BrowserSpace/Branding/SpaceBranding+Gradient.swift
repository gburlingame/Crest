import Foundation

/// A Space's look as a two-color gradient down its sidebar under a plain icon,
/// as the Mac's look page and setup offer it.
extension SpaceBranding {
    // MARK: - Variables

    /// The color at the top of the sidebar.
    var gradientStart: BrandColor { colors.first ?? .indigo }

    /// The color at the foot of the sidebar.
    var gradientEnd: BrandColor { colors.last ?? gradientStart }

    // MARK: - Mutators

    /// Wears a gradient from `start` to `end` chosen by hand, at full strength
    /// with text in whichever tone reads best, and a plain icon that follows it.
    mutating func wearGradient(from start: BrandColor, to end: BrandColor) {
        colors = ColorPalette(colors: [start, end])
        themeMode = .gradient
        gradientAngle = 90
        bannerStrength = 1
        readabilityFade = 0
        showsTexture = false
        textColorMode = .automatic
        iconStyle = .simpleSymbol
        symbolColor = nil
        hasCustomAppearance = true
    }
}

extension SpaceScheme {
    // MARK: - Variables

    /// The two-color gradients a person chooses from.
    static var gradients: [SpaceScheme] { all.filter { $0 != .neutral } }
}
