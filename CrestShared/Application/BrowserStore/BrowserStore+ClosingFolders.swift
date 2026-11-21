import Foundation

/// Closing a folder in Thundermist on Mac puts away the pages of the loaded
/// tabs it holds, so it closes all the way.
extension BrowserStore {
    // MARK: - Actions - Reading

    /// The tabs closing every open folder of `space` puts away, as closing
    /// each one does: those the open folders whose kind closes its loaded
    /// tabs hold, however deep, that hold a page, as `holdsPage` says, or that
    /// the window shows. None where every folder keeps its loaded tabs, as on
    /// iPhone and iPad.
    func tabsClosingWithAllFolders(
        of space: SpaceModel, holdsPage: (BrowserTabRuntimeAssignment) -> Bool
    ) -> [UUID] {
        let shown = windowModel?.shownTabIDs
        var seen: Set<UUID> = []
        return space.folders.models
            .filter { !$0.isCollapsed && $0.kind.closesLoadedTabsWhenClosed }
            .flatMap { space.tabIDs(inFolder: $0.id) }
            .filter { tabID in
                guard seen.insert(tabID).inserted else { return false }
                return shown?.contains(tabID) == true
                    || holdsPage(
                        BrowserTabRuntimeAssignment(tabID: tabID, spaceID: space.id, profileID: space.profileID))
            }
    }

    // MARK: - Mutators

    /// Closes every open folder of the Space once the pages of
    /// `loadedTabIDs` agree to go: the core puts them away, each tab keeping
    /// its place, and collapses the folders, and a window that showed one of
    /// them returns to the tab it showed before outside them. With no loaded
    /// tabs it only collapses them. False when the Space is gone, has no open
    /// folder, or a page may not go yet.
    @discardableResult
    func closeAllFolders(
        matching assignment: BrowserSpaceRuntimeAssignment, puttingAway loadedTabIDs: [UUID]
    ) -> Bool {
        guard let space = spaceModel(matching: assignment) else { return false }
        guard !loadedTabIDs.isEmpty else { return collapseAllFolders(matching: assignment) }
        let pages = loadedTabIDs.map {
            BrowserTabRuntimeAssignment(tabID: $0, spaceID: space.id, profileID: space.profileID)
        }
        return performPageDismissal(of: pages) { [weak self] in
            guard let self, self.spaceModel(matching: assignment) != nil else { return false }
            return self.family.perform(
                CloseAllFolders(
                    workspaceID: self.family.workspaceID, windowID: self.windowID, spaceID: assignment.spaceID,
                    loadedTabIDs: loadedTabIDs),
                from: self) != nil
        }
    }

    /// Closes the folder `folderID` once the pages of `loadedTabIDs` agree to
    /// go: the core puts them away, each tab keeping its place, and collapses
    /// the folder, and a window that showed one of them returns to the tab it
    /// showed before outside the folder. With no loaded tabs it only
    /// collapses. False when the Space no longer holds the folder, or a page
    /// may not go yet.
    @discardableResult
    func closeFolder(
        _ folderID: UUID, matching assignment: BrowserSpaceRuntimeAssignment, puttingAway loadedTabIDs: [UUID]
    ) -> Bool {
        guard let space = spaceModel(matching: assignment), space.folders.contains(folderID) else { return false }
        guard !loadedTabIDs.isEmpty else {
            return setFolderCollapsed(folderID, matching: assignment, isCollapsed: true)
        }
        let pages = loadedTabIDs.map {
            BrowserTabRuntimeAssignment(tabID: $0, spaceID: space.id, profileID: space.profileID)
        }
        return performPageDismissal(of: pages) { [weak self] in
            guard let self, self.spaceModel(matching: assignment)?.folders.contains(folderID) == true
            else { return false }
            return self.family.perform(
                CloseFolder(
                    workspaceID: self.family.workspaceID, windowID: self.windowID, spaceID: assignment.spaceID,
                    folderID: folderID, loadedTabIDs: loadedTabIDs),
                from: self) != nil
        }
    }
}
