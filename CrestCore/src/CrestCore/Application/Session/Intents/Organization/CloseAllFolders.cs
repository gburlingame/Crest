using CrestCore.Application;

namespace CrestCore.Contracts;

/// Closes every open folder of a Space, however deep, as a person closes each
/// one in Thundermist on Mac: each tab of `LoadedTabIds` they hold puts its
/// page away and keeps its place, and the folders collapse, in one edit, as
/// `NativeSessionAuthority.ClosingFolders` describes. Groups keep their own
/// state, as `CollapseAllFolders` leaves them. A Space with no open folder is
/// left as it is.
public sealed record CloseAllFolders(Guid WorkspaceId, Guid WindowId, Guid SpaceId, IReadOnlyList<Guid> LoadedTabIds)
    : SessionIntent(WorkspaceId) {
    #region Actions - Session

    internal override SessionEdit? Edit(NativeSessionAuthority workspace, SessionTurn turn) {
        Guid[] open = [.. workspace.Editable(turn.Basis, SpaceId).Folders.Where(folder => folder.CollapsesWithAll)
            .Select(folder => folder.Id)];
        return open.Length > 0 ? workspace.ClosingFolders(turn, WindowId, SpaceId, open, LoadedTabIds) : null;
    }

    #endregion
}
