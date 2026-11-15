import Foundation

// MARK: - New Saved Folder

extension BrowserStore {
    /// Whether the core would now make a Saved Tabs folder holding `tabIDs`
    /// inside `parentID`, or at the top of Saved Tabs without one.
    func canCreateSavedFolder(
        holding tabIDs: [UUID], inside parentID: UUID?, matching assignment: BrowserSpaceRuntimeAssignment
    ) -> Bool {
        guard spaceModel(matching: assignment) != nil, !isDeleting(assignment.spaceID) else { return false }
        return family.canSend(
            savedFolderCreation(UUID(), holding: tabIDs, inside: parentID, in: assignment.spaceID), from: self)
    }

    /// Makes a Saved Tabs folder named New Folder holding `tabIDs`, inside
    /// `parentID` or at the top of Saved Tabs, then opens Saved Tabs and every
    /// collapsed folder around it so it shows and its title can start
    /// editing. Nil when the core refused it.
    @discardableResult
    func createSavedFolder(
        holding tabIDs: [UUID], inside parentID: UUID?, matching assignment: BrowserSpaceRuntimeAssignment
    ) -> UUID? {
        let id = UUID()
        guard spaceModel(matching: assignment) != nil, !isDeleting(assignment.spaceID),
            family.send(savedFolderCreation(id, holding: tabIDs, inside: parentID, in: assignment.spaceID), from: self)
        else { return nil }
        setSavedTabsExpanded(true, matching: assignment)
        var ancestorID = parentID
        var visited: Set<UUID> = []
        while let current = ancestorID, visited.insert(current).inserted,
            let folder = spaceModel(matching: assignment)?.folders.model(current)
        {
            if folder.isCollapsed { setFolderCollapsed(current, matching: assignment, isCollapsed: false) }
            ancestorID = folder.parentID
        }
        return id
    }

    /// The folder `id` in the default folder look. A tab in a split brings
    /// its split along.
    private func savedFolderCreation(
        _ id: UUID, holding tabIDs: [UUID], inside parentID: UUID?, in spaceID: UUID
    ) -> CreateFolder {
        CreateFolder(
            workspaceID: family.workspaceID, spaceID: spaceID, folderID: id, placement: .saved, parentID: parentID,
            title: Self.newFolderTitle, color: BrandColor.folderDefault, symbol: "folder", tabIDs: tabIDs,
            leavesSplits: false, isGroup: false)
    }
}
