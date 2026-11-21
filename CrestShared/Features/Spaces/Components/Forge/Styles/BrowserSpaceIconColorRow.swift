import SwiftUI

/// The color a Space's plain symbol wears, chosen with the system color
/// picker. Its reset puts back the color the Space's look gives the icon:
/// the Space's own color in Modern, and the shade of its one color in Simple.
struct BrowserSpaceIconColorRow: View {
    // MARK: - Variables

    @Binding var branding: SpaceBranding
    let look: SetupLook

    // MARK: - Actions - Drawing

    var body: some View {
        CrestSettingRow("Icon color", setting: iconColor.resettable("Icon color")) {
            CrestCustomColorSwatch(
                title: "Icon color",
                color: Binding(
                    get: { branding.resolvedSymbolColor.color },
                    set: { iconColor.binding.wrappedValue = BrandColor(color: $0) }),
                isSelected: true, tint: CrestBrandTheme.line)
        }
        .accessibilityIdentifier("space-icon-color")
    }

    // MARK: - Actions - Settings

    /// The icon's own color, which resets to the one the look gives it.
    private var iconColor: CrestSettingValue<BrandColor?> {
        CrestSettingValue(
            Binding(
                get: { branding.symbolColor },
                set: { color in
                    $branding.editorUpdate {
                        $0.symbolColor = color
                        $0.hasCustomAppearance = true
                    }
                }),
            default: lookColor)
    }

    /// The color the look gives the icon of a Space in its colors.
    private var lookColor: BrandColor? {
        var plain = branding
        plain.symbolColor = nil
        return look.applying(to: plain).symbolColor
    }
}

#if DEBUG
    #Preview("Icon color") {
        @Previewable @State var modern = BrowserCustomizationStyle.modern.look(
            for: SpaceHouse.winter.look, remembered: nil)
        @Previewable @State var simple = BrowserSimpleSpaceColor.all[6].applied(to: SpaceHouse.winter.look)
        Form {
            BrowserSpaceIconColorRow(branding: $modern, look: .modern)
            BrowserSpaceIconColorRow(branding: $simple, look: .simple)
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 160)
    }
#endif
