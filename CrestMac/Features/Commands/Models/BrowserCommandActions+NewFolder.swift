import Foundation

// MARK: - Actions - Folders

extension BrowserCommandActions {
    /// Whether the Space on screen can take a new folder in Saved Tabs.
    var canCreateFolder: Bool {
        guard let space = browser.shownSpace, !spaceAccess.isLocked(space) else { return false }
        return browser.canCreateSavedFolder(
            holding: [], inside: nil, matching: BrowserSpaceRuntimeAssignment(space: space))
    }

    /// Makes an empty folder in the Saved Tabs of the Space on screen and
    /// starts editing its title, showing the sidebar if it was hidden.
    func createFolder() {
        guard let space = browser.shownSpace, !spaceAccess.isLocked(space) else { return }
        let assignment = BrowserSpaceRuntimeAssignment(space: space)
        guard let id = browser.createSavedFolder(holding: [], inside: nil, matching: assignment) else { return }
        if chrome.columnVisibility == .detailOnly { chrome.showSidebar() }
        BrowserSidebarInteractionState.connected(to: browser).editingFolderRequest = BrowserFolderRuntimeAssignment(
            folderID: id, spaceID: assignment.spaceID, profileID: assignment.profileID)
    }
}
