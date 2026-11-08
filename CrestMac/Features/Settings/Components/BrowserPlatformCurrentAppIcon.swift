import SwiftUI

/// The app icon as the Dock shows it, in the system's current appearance.
struct BrowserPlatformCurrentAppIcon: View {
    @State private var appearanceRevision = 0
    @State private var appearanceObserver: BrowserMacAppIconAppearanceObserver?

    var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath))
            .resizable()
            .scaledToFit()
            .id(appearanceRevision)
            .onAppear {
                appearanceObserver = BrowserMacAppIconAppearanceObserver { appearanceRevision += 1 }
            }
            .onDisappear {
                appearanceObserver?.stop()
                appearanceObserver = nil
            }
    }
}
