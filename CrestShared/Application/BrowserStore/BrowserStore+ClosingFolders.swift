import Foundation

/// Closing a folder in Thundermist on Mac puts away the pages of the loaded
/// tabs it holds, so it closes all the way.
extension BrowserStore {
    // MARK: - Mutators

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
