using CrestCore.Application;
using CrestCore.Domain;

namespace CrestCore.Contracts;

/// Closes a folder as a person closes one in Thundermist on Mac: each tab of
/// `LoadedTabIds` the folder holds, however deep, puts its page away and
/// keeps its place, as closing a saved or pinned tab does, which returns to
/// its saved address when the app's preferences say so, and the folder
/// collapses. An open tab keeps what brings its page back. A window that
/// showed one of them returns to the tab it showed before outside the folder
/// and the splits it closed, whose other members would present a closed tab
/// again, or to none, and the window that asked lets the pages go. Refused
/// with `UnknownFolder` for a folder that is not there.
public sealed record CloseFolder(Guid WorkspaceId, Guid WindowId, Guid SpaceId, Guid FolderId, IReadOnlyList<Guid> LoadedTabIds)
    : SessionIntent(WorkspaceId) {
    #region Actions - Session

    internal override SessionEdit? Edit(NativeSessionAuthority workspace, SessionTurn turn) {
        var space = workspace.Editable(turn.Basis, SpaceId);
        var edited = BrowserTabCollection.Restore(space);
        var inside = edited.TabsInFolder(FolderId);
        var loaded = LoadedTabIds.ToHashSet();
        var tabs = space.Tabs.ToDictionary(tab => tab.Id);
        var closing = inside.Where(loaded.Contains).Select(id => tabs[id]).ToArray();
        var splits = closing.Select(tab => tab.SplitGroupId).OfType<Guid>().ToHashSet();
        var followUp = new WindowFollowUp(workspace.IssuingWindow(WindowId));
        var shown = followUp.Window?.Tab(space.Id);
        var fallback = followUp.FallbackAfterDismissing(space.Id, closing.Select(tab => tab.Id).ToHashSet(), space.Tabs
            .Where(tab => !inside.Contains(tab.Id) && (tab.SplitGroupId is not { } split || !splits.Contains(split)))
            .Select(tab => tab.Id).ToHashSet());
        var policy = workspace.ClosePolicy(turn.Basis);
        var selected = shown;
        List<SessionPagePutAway> putAways = [];
        List<SessionSavedImage> savedImages = [];
        foreach (var tab in closing) {
            var returns = tab.Placement.IsDurable && policy == SavedTabClosePolicy.ReturnToSavedUrl
                && (tab.SavedUrl ?? tab.Url) is not null;
            if (returns && tab.ReturnRestoresImage)
                savedImages.Add(new(tab.Id, TabSavedImageChange.Restore, tab.SavedFaviconUrl));
            if (tab.Placement.IsDurable) selected = edited.CloseDurable(tab.Id, selected, fallback, returns);
            else if (selected == tab.Id) selected = fallback;
            putAways.Add(new(WindowId, space.Id, tab.Id, KeepsState: !returns));
        }
        edited.CollapseFolder(FolderId, true, turn.Now);
        followUp.ShowTab(space.Id, selected);
        var events = SessionTabEvents.None with { PutAways = putAways, SavedImages = savedImages };
        return new(turn.Basis.Replacing(edited.Capture(space)), SyncStaging.Creation, followUp, events);
    }

    #endregion
}
