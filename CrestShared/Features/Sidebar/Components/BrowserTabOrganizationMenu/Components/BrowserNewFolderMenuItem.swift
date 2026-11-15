import SwiftUI

/// A tab menu's New Folder: makes a Saved Tabs folder holding the menu's
/// tabs and starts editing its title in the sidebar. The folder goes inside
/// the Saved Tabs folder the tabs share, and at the top of Saved Tabs
/// otherwise, so a pinned or open tab moves into Saved Tabs with it.
struct BrowserNewFolderMenuItem: View {
    // MARK: - Variables

    @Environment(BrowserSidebarInteractionState.self) private var sidebarInteraction

    private let title: LocalizedStringKey
    private let tabIDs: [UUID]
    private let parentID: UUID?
    private let browser: BrowserStore
    private let assignment: BrowserSpaceRuntimeAssignment
    /// Runs the creation, or holds it back once the menu no longer applies.
    private let perform: (() -> Void) -> Void
    /// What the menu does once the folder is made.
    private let didCreate: () -> Void

    // MARK: - Initializers

    /// New Folder for the tab a single-tab menu belongs to.
    init(
        tab: TabStateModel, browser: BrowserStore, assignment: BrowserSpaceRuntimeAssignment,
        perform: @escaping (() -> Void) -> Void
    ) {
        title = "New Folder"
        tabIDs = [tab.id]
        parentID = tab.placement == .saved ? tab.folderID : nil
        self.browser = browser
        self.assignment = assignment
        self.perform = perform
        didCreate = {}
    }

    /// New Folder for the tabs a window's selection holds, which it clears.
    init(selection request: BrowserCapturedSelection, browser: BrowserStore) {
        let count = request.ids.count
        title = count == 1 ? "New Folder" : "New Folder with \(count) Tabs"
        tabIDs = request.ids
        let folders = Set(request.members.map { $0.placement == .saved ? $0.folderID : nil })
        parentID = folders.count == 1 ? folders.first ?? nil : nil
        self.browser = browser
        assignment = request.assignment
        perform = { $0() }
        didCreate = { browser.tabMultiSelection.clear() }
    }

    var body: some View {
        Button(title, systemImage: "folder.badge.plus") {
            perform {
                guard let id = browser.createSavedFolder(holding: tabIDs, inside: parentID, matching: assignment)
                else { return }
                didCreate()
                sidebarInteraction.editingFolderRequest = BrowserFolderRuntimeAssignment(
                    folderID: id, spaceID: assignment.spaceID, profileID: assignment.profileID)
            }
        }
        .disabled(!browser.canCreateSavedFolder(holding: tabIDs, inside: parentID, matching: assignment))
    }
}
