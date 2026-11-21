using CrestCore.Contracts;
using CrestCore.Domain;

namespace CrestCore.Application;

/// Closing folders as a person closes them in Thundermist on Mac.
public sealed partial class NativeSessionAuthority {
    #region Actions - Folders

    /// Collapses `folderIds` in the Space `spaceId`, and puts away the pages
    /// of the tabs of `loadedTabIds` they hold, however deep, in one edit.
    /// Each tab keeps its place, as closing a saved or pinned tab does, which
    /// returns to its saved address when the app's preferences say so for its
    /// section; an open tab keeps what brings its page back. A window that
    /// showed one of them returns to the tab it showed before outside the
    /// folders and the splits it closed, whose other members would present a
    /// closed tab again, or to none, and the window that asked lets the pages
    /// go. Refused with `UnknownFolder` for a folder that is not there.
    internal SessionEdit ClosingFolders(SessionTurn turn, Guid windowId, Guid spaceId, IReadOnlyCollection<Guid> folderIds,
        IReadOnlyList<Guid> loadedTabIds) {
        var space = Editable(turn.Basis, spaceId);
        var edited = BrowserTabCollection.Restore(space);
        var inside = folderIds.SelectMany(edited.TabsInFolder).Distinct().ToArray();
        var insideSet = inside.ToHashSet();
        var loaded = loadedTabIds.ToHashSet();
        var tabs = space.Tabs.ToDictionary(tab => tab.Id);
        var closing = inside.Where(loaded.Contains).Select(id => tabs[id]).ToArray();
        var splits = closing.Select(tab => tab.SplitGroupId).OfType<Guid>().ToHashSet();
        var followUp = new WindowFollowUp(IssuingWindow(windowId));
        var shown = followUp.Window?.Tab(space.Id);
        var fallback = followUp.FallbackAfterDismissing(space.Id, closing.Select(tab => tab.Id).ToHashSet(), space.Tabs
            .Where(tab => !insideSet.Contains(tab.Id) && (tab.SplitGroupId is not { } split || !splits.Contains(split)))
            .Select(tab => tab.Id).ToHashSet());
        var selected = shown;
        List<SessionPagePutAway> putAways = [];
        List<SessionSavedImage> savedImages = [];
        foreach (var tab in closing) {
            var returns = ClosePolicy(turn.Basis, tab.Placement) == SavedTabClosePolicy.ReturnToSavedUrl
                && (tab.SavedUrl ?? tab.Url) is not null;
            if (returns && tab.ReturnRestoresImage)
                savedImages.Add(new(tab.Id, TabSavedImageChange.Restore, tab.SavedFaviconUrl));
            if (tab.Placement.IsDurable) selected = edited.CloseDurable(tab.Id, selected, fallback, returns);
            else if (selected == tab.Id) selected = fallback;
            putAways.Add(new(windowId, space.Id, tab.Id, KeepsState: !returns));
        }
        foreach (var folderId in folderIds) edited.CollapseFolder(folderId, true, turn.Now);
        followUp.ShowTab(space.Id, selected);
        var events = SessionTabEvents.None with { PutAways = putAways, SavedImages = savedImages };
        return new(turn.Basis.Replacing(edited.Capture(space)), SyncStaging.Creation, followUp, events);
    }

    #endregion
}
