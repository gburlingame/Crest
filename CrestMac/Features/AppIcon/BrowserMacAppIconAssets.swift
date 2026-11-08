import AppKit

/// How the system draws the app icon: in its own colors for light or dark, or
/// as the Clear and Tinted icons the person may choose, which only Icon
/// Services renders.
enum BrowserMacAppIconAssets {
    static let systemAppearanceKey = "AppleIconAppearanceTheme"

    static var usesSystemAppearance: Bool {
        let theme = UserDefaults.standard.string(forKey: systemAppearanceKey)?.lowercased() ?? ""
        return theme.contains("clear") || theme.contains("tinted") || theme.contains("mono")
    }
}

/// UserDefaults observes the system's icon appearance; the theme notification
/// also covers automatic light/dark transitions. Each owner explicitly stops observing.
@MainActor
final class BrowserMacAppIconAppearanceObserver: NSObject {
    private let changed: () -> Void
    private var isObserving = true

    init(changed: @escaping () -> Void) {
        self.changed = changed
        super.init()
        UserDefaults.standard.addObserver(
            self, forKeyPath: BrowserMacAppIconAssets.systemAppearanceKey,
            options: [], context: nil)
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(themeChanged),
            name: Notification.Name("AppleInterfaceThemeChangedNotification"), object: nil,
            suspensionBehavior: .deliverImmediately)
    }

    func stop() {
        guard isObserving else { return }
        isObserving = false
        UserDefaults.standard.removeObserver(self, forKeyPath: BrowserMacAppIconAssets.systemAppearanceKey)
        DistributedNotificationCenter.default().removeObserver(self)
    }

    override nonisolated func observeValue(
        forKeyPath keyPath: String?, of object: Any?,
        change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?
    ) {
        Task { @MainActor [weak self] in self?.changed() }
    }

    @objc nonisolated private func themeChanged() {
        Task { @MainActor [weak self] in self?.changed() }
    }
}
