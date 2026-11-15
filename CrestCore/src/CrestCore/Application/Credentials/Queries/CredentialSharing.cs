using CrestCore.Application;

namespace CrestCore.Contracts;

#region Types

/// The Spaces whose saved passwords a page may fill.
public sealed record CredentialSharers(IReadOnlyList<Guid> SpaceIds);

#endregion

/// The Spaces whose saved passwords a page in Space `SpaceId` may fill: every
/// Space of its group, since a group shares one session and its passwords, or
/// the Space alone.
public sealed record CredentialSharing(Guid SpaceId) : Query<CredentialSharers> {
    #region Actions - Answering

    internal override CredentialSharers Answer(CrestApp app) => new([.. app.Device.GroupMembersOf(SpaceId)]);

    #endregion
}
