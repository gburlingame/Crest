import SwiftUI

/// A Space's look: a two-color sidebar gradient, from a preset or chosen by
/// hand, under a plain icon or emoji. Changes show in the Space as they're made.
struct BrowserSpaceLookEditor: View {
    // MARK: - Variables

    @Binding var branding: SpaceBranding
    @Binding var symbol: String
    /// The Space's name, where the page doesn't already let a person edit it.
    var name: Binding<String>? = nil

    var body: some View {
        BrowserSettingsPane(.spaces) {
            if let name {
                Section {
                    TextField("Name", text: name)
                }
            }
            Section("Presets") {
                BrowserSpaceLookPresetGrid(branding: $branding)
            }
            Section("Colors") {
                BrowserSpaceLookColorPickers(branding: $branding)
            }
            Section("Icon") {
                BrowserSpaceLookIconPicker(branding: $branding, symbol: $symbol)
            }
        }
        .accessibilityIdentifier("space-customization-controls")
    }
}

/// Every gradient preset, drawn as it runs down a sidebar, with the one the
/// Space wears marked.
private struct BrowserSpaceLookPresetGrid: View {
    // MARK: - Variables

    @Binding var branding: SpaceBranding

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
            ForEach(SpaceScheme.gradients, id: \.self) { scheme in
                BrowserCrestStudioChoice(
                    title: scheme.title, selected: scheme.isWorn(by: branding), tint: .accentColor
                ) {
                    branding = scheme.applying(to: branding)
                } artwork: {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: scheme.look.colors.map(\.color), startPoint: .top, endPoint: .bottom)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(.primary.opacity(0.12))
                        }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("space-look-presets")
    }
}

/// The two colors of a Space's gradient, chosen by hand.
struct BrowserSpaceLookColorPickers: View {
    // MARK: - Variables

    @Binding var branding: SpaceBranding

    private var start: Binding<Color> {
        Binding(
            get: { branding.gradientStart.color },
            set: { color in
                $branding.editorUpdate { $0.wearGradient(from: BrandColor(color: color), to: $0.gradientEnd) }
            })
    }

    private var end: Binding<Color> {
        Binding(
            get: { branding.gradientEnd.color },
            set: { color in
                $branding.editorUpdate { $0.wearGradient(from: $0.gradientStart, to: BrandColor(color: color)) }
            })
    }

    var body: some View {
        ColorPicker("Start", selection: start, supportsOpacity: false)
        ColorPicker("End", selection: end, supportsOpacity: false)
    }
}

/// A Space's plain icon: a system symbol or an emoji.
struct BrowserSpaceLookIconPicker: View {
    // MARK: - Variables

    @Binding var branding: SpaceBranding
    @Binding var symbol: String
    @State private var choosesEmoji = false

    private var emoji: String? { BrowserIconSymbol.emoji(from: symbol) }

    var body: some View {
        HStack(spacing: 12) {
            BrowserSystemSymbolPicker(
                selection: Binding(
                    get: { emoji == nil ? symbol : "" },
                    set: { wearIcon($0) }))
            BrowserArtworkPickerButton(
                title: "Emoji",
                detail: emoji == nil ? Text("Choose an emoji") : Text("Change emoji")
            ) {
                choosesEmoji = true
            } artwork: {
                if let emoji {
                    Text(emoji)
                } else {
                    Image(systemName: "face.smiling")
                }
            }
            .accessibilityLabel("Choose Emoji")
            .browserIconCustomizationPopover(
                .init(
                    isPresented: $choosesEmoji, title: "Space Icon", currentEmoji: emoji,
                    setEmoji: { wearIcon(BrowserIconSymbol.symbol(forEmoji: $0)) }))
        }
        .frame(maxWidth: 520)
    }

    // MARK: - Mutators

    /// Gives the Space `symbol`, keeping a stored look from falling back on a crest.
    private func wearIcon(_ symbol: String) {
        self.symbol = symbol
        if branding.iconStyle != .simpleSymbol {
            $branding.editorUpdate {
                $0.iconStyle = .simpleSymbol
                $0.hasCustomAppearance = true
            }
        }
    }
}
