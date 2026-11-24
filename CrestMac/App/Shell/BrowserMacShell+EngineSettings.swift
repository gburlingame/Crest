import Foundation

/// Thundermist opens the engine's own settings for the Space in front. Each
/// Space is its own engine profile, so a choice made there, such as continuing
/// where it left off on startup, which keeps its session cookies across
/// restarts, holds for that Space alone.
extension BrowserMacShell {
    // MARK: - Static Variables

    /// The engine's settings at their On startup section, as the core holds
    /// the address.
    private static let engineStartupSettings = URL(string: "crest://settings/onStartup")

    // MARK: - Actions - Engine settings

    /// Opens the engine's settings in a new tab of the Space the browser
    /// window the person is using shows, opening a window only when none is
    /// open.
    func openEngineSettings() {
        guard let url = Self.engineStartupSettings, let context = windows?.contextBringingBrowserWindowForward(),
            context.browser.openNewTab(url: url) != nil
        else { return }
        context.pages.select()
    }
}
