import SwiftUI

/// The desktop's Reset All: the shared choices, plus Space page motion and how
/// the sidebar reveals itself.
struct BrowserPlatformLookAndFeelResetSection: View {
    @AppStorage(SpacePageMotionPreference.key)
    private var animatesSpacePages = SpacePageMotionPreference.defaultValue
    @AppStorage(SidebarFullscreenRevealPreference.key, store: BrowserChromeAppearancePreference.defaults)
    private var revealsSidebarInFullscreen = SidebarFullscreenRevealPreference.defaultValue

    var body: some View {
        BrowserLookAndFeelResetFooter {
            animatesSpacePages = SpacePageMotionPreference.defaultValue
            BrowserDeviceAppearanceStore.shared.sidebarRevealWidth = SidebarRevealWidthPreference.defaultValue
            revealsSidebarInFullscreen = SidebarFullscreenRevealPreference.defaultValue
        }
    }
}
