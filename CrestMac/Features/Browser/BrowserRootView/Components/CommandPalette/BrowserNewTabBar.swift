import SwiftUI

/// The window's New Tab bar: one field whose text opens in a new tab, as the
/// address it names or as a search with the Space's engine. Return opens it;
/// Escape or a click beside the bar puts it away without opening anything.
/// It rests where the command palette's field rests.
struct BrowserNewTabBar: View {
    // MARK: - Variables

    let model: BrowserRootModel
    var contentInsets = EdgeInsets()

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            let availableHeight = proxy.size.height - contentInsets.top - contentInsets.bottom
            ZStack {
                BrowserCommandPaletteScrim(dismiss: model.chrome.dismissCommandPalette)
                field
                    .frame(
                        width: BrowserCommandPaletteLayout.overlayCardWidth(
                            availableWidth: proxy.size.width - contentInsets.leading - contentInsets.trailing)
                    )
                    .background(CrestColor.windowBackground, in: shape)
                    .padding(.top, BrowserCommandPaletteLayout.overlayTopInset(availableHeight: availableHeight))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(contentInsets)
            }
        }
        .onAppear { isFocused = true }
    }

    // MARK: - Field

    private var field: some View {
        HStack(spacing: BrowserCommandPaletteMetrics.searchFieldSpacing) {
            Image(systemName: "magnifyingglass")
                .font(.system(.title2, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField("Search or Enter URL…", text: $text)
                .textFieldStyle(.plain)
                .font(.title2)
                .focused($isFocused)
                .onSubmit { model.openNewTabBarText(text) }
                .onExitCommand(perform: model.chrome.dismissCommandPalette)
                .accessibilityIdentifier("new-tab-field")
        }
        .padding(.horizontal, BrowserCommandPaletteMetrics.searchFieldHorizontalPadding)
        .frame(minHeight: BrowserCommandPaletteMetrics.searchFieldMinimumHeight)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: BrowserCommandPaletteMetrics.cardCornerRadius, style: .continuous)
    }
}
