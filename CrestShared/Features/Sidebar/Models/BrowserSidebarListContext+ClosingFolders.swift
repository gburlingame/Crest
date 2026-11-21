import Foundation

extension BrowserSidebarListContext {
    // MARK: - Actions - Folders

    /// Closes the folder `folderID` as the person asked. A kind that closes
    /// its loaded tabs puts away the pages of the tabs it holds, however deep,
    /// that are loaded or that the window shows, then brings the tab the
    /// window moves to on screen when it showed one; any other only
    /// collapses.
    @MainActor @discardableResult
    func closeFolder(_ folderID: UUID) -> Bool {
        guard let folder = space.folders.model(folderID) else { return false }
        guard folder.kind.closesLoadedTabsWhenClosed else {
            return browser.setFolderCollapsed(folderID, matching: assignment, isCollapsed: true)
        }
        let tabIDs = space.tabIDs(inFolder: folderID)
        let showsOne = tabIDs.contains { window.shownTabIDs.contains($0) }
        let loaded = tabIDs.filter { tabID in
            window.shownTabIDs.contains(tabID)
                || pageAccess.containsResidentPageMatching(
                    BrowserTabRuntimeAssignment(tabID: tabID, spaceID: space.id, profileID: space.profileID))
        }
        guard browser.closeFolder(folderID, matching: assignment, puttingAway: loaded) else { return false }
        if showsOne { pageAccess.selectPages() }
        return true
    }

    /// Closes every open folder of the Space as the person asked, as closing
    /// each one does, while the window shows the Space unlocked, then brings
    /// the tab the window moves to on screen when it showed one of theirs.
    @MainActor @discardableResult
    func closeAllFolders() -> Bool {
        guard tabActions.canCollapseAllFolders else { return false }
        let loaded = browser.tabsClosingWithAllFolders(of: space) { pageAccess.containsResidentPageMatching($0) }
        let showsOne = loaded.contains { window.shownTabIDs.contains($0) }
        guard browser.closeAllFolders(matching: assignment, puttingAway: loaded) else { return false }
        if showsOne { pageAccess.selectPages() }
        return true
    }
}
