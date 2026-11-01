import SwiftUI

struct BrowserSpaceThemeField: View {
    let themeMode: SpaceThemeMode
    let bannerPattern: SpaceBannerPattern
    let gradientAngle: Double
    let colors: [Color]
    let size: CGSize

    @ViewBuilder
    var body: some View {
        #if os(macOS)
            // The Mac draws a Space stored with a banner as a gradient of its
            // own colors, straight down the sidebar.
            BrowserSpaceGradientField(colors: colors, angle: themeMode.kind == .gradient ? gradientAngle : 90)
        #else
            switch themeMode.kind {
            case .banner:
                BrowserSpaceBannerField(
                    pattern: bannerPattern,
                    colors: colors,
                    size: size
                )
            case .gradient:
                BrowserSpaceGradientField(
                    colors: colors,
                    angle: gradientAngle
                )
            }
        #endif
    }
}
