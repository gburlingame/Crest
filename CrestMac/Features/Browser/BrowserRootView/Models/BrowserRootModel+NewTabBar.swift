import Foundation

extension BrowserRootModel {
    // MARK: - Actions - New Tab Bar

    /// Opens `text` from the New Tab bar in a new tab of the Space the window
    /// shows, as the core reads it: the address it names, else a search with
    /// the Space's engine. The bar closes once the tab opens; text that names
    /// nothing, as blank text does, leaves it open.
    func openNewTabBarText(_ text: String) {
        guard
            let destination = try? browser.core.query(NewTabAddress(windowID: browser.windowID, text: text)),
            let url = destination.address.flatMap(URL.init(string:))
        else { return }
        let opened =
            if let source = selectedTabAssignment {
                openPaletteURL(url, mode: .newTab, from: source)
            } else {
                emptySelectionPaletteActions?.openURL(url) ?? false
            }
        if opened { chrome.dismissCommandPalette() }
    }
}
