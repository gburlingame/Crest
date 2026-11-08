import SwiftUI

/// What a first run changes on a Space: its gradient and its icon.
struct BrowserOnboardingModernSheet: View {
    @Binding var branding: SpaceBranding
    @Binding var symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            colors
            icon
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Sections

    private var colors: some View {
        BrowserOnboardingMakeSection("Color") {
            VStack(alignment: .leading, spacing: 16) {
                BrowserOnboardingMakeStrip {
                    ForEach(SpaceScheme.gradients, id: \.self) { scheme in
                        BrowserOnboardingModernPresetSwatch(
                            colors: Array(scheme.look.colors), isSelected: scheme.isWorn(by: branding)
                        ) {
                            branding = scheme.applying(to: branding)
                        }
                    }
                }
                HStack(spacing: 20) {
                    BrowserSpaceLookColorPickers(branding: $branding)
                }
                .fixedSize()
            }
        }
    }

    private var icon: some View {
        BrowserOnboardingMakeSection("Icon") {
            BrowserSpaceLookIconPicker(branding: $branding, symbol: $symbol)
        }
    }
}

/// A set of colors as one round swatch, running from the first to the last.
private struct BrowserOnboardingModernPresetSwatch: View {
    let colors: [BrandColor]
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        CrestSelectableCard(
            isSelected: isSelected,
            accessibilityLabel: Text(colors.map { String(localized: $0.title) }.joined(separator: ", ")),
            density: .swatch, tint: CrestBrandPalette.butter, action: select
        ) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: colors.map(\.color), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 44, height: 44)
                .overlay { Circle().strokeBorder(CrestBrandTheme.line, lineWidth: CrestLayout.hairline) }
        }
    }
}
