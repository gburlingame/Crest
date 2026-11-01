import SwiftUI

/// A Space's Appearance page: the look editor beside the window's live sidebar,
/// or with a preview of its own where Settings can't show that sidebar.
struct BrowserSpaceEditorView: View {
    @Environment(\.browserSettingsUsesLiveSidebar) private var usesLiveSidebar

    let browser: BrowserStore
    let space: SpaceModel

    var body: some View {
        Group {
            if usesLiveSidebar {
                BrowserSpaceLookEditor(branding: branding, symbol: symbol)
            } else {
                HStack(alignment: .top, spacing: 0) {
                    BrowserCrestStudioPreview(
                        branding: branding.wrappedValue, symbol: symbol.wrappedValue,
                        name: space.settings.name, space: BrowserSpaceAppearance(space: space),
                        heroSize: 96, sidebarHeight: 230
                    )
                    .frame(width: 260)
                    .padding(14)
                    BrowserSpaceLookEditor(branding: branding, symbol: symbol, name: name)
                }
            }
        }
        .id(space.id)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var name: Binding<String> {
        browser.spaceNameBinding(in: space)
    }

    private var symbol: Binding<String> {
        browser.spaceSymbolBinding(in: space)
    }

    private var branding: Binding<SpaceBranding> {
        browser.spaceBrandingBinding(in: space)
    }
}
