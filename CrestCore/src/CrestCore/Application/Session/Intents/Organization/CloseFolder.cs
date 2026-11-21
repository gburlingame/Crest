using CrestCore.Application;

namespace CrestCore.Contracts;

/// Closes a folder as a person closes one in Thundermist on Mac: each tab of
/// `LoadedTabIds` the folder holds, however deep, puts its page away and
/// keeps its place, and the folder collapses, as
/// `NativeSessionAuthority.ClosingFolders` describes. Refused with
/// `UnknownFolder` for a folder that is not there.
public sealed record CloseFolder(Guid WorkspaceId, Guid WindowId, Guid SpaceId, Guid FolderId, IReadOnlyList<Guid> LoadedTabIds)
    : SessionIntent(WorkspaceId) {
    #region Actions - Session

    internal override SessionEdit? Edit(NativeSessionAuthority workspace, SessionTurn turn) =>
        workspace.ClosingFolders(turn, WindowId, SpaceId, [FolderId], LoadedTabIds);

    #endregion
}
