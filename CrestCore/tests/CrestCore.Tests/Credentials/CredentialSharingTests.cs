using CrestCore.Contracts;

using Xunit;

namespace CrestCore.Tests;

/// A group's Spaces share one session and the passwords it keeps, so a page
/// in any of them may fill a password another of them keeps; a Space outside
/// the group shares none of them.
public sealed partial class BrowserContractsTests {
    [Fact]
    public void APageFillsPasswordsItsGroupKeepsAndNoOtherSpaces() {
        var (primary, sub, alone) = (Fixed(3_600), Fixed(3_601), Fixed(3_602));
        using var device = new TestDevice(SessionOf(
            SpaceOf(primary, Fixed(3_690), "Personal"),
            SpaceOf(sub, Fixed(3_691), "Projects"),
            SpaceOf(alone, Fixed(3_692), "Work")));
        device.Send(new JoinSpace(device.Workspace, sub, primary));

        IEnumerable<Guid> Sharers(Guid space) => device.Query(new CredentialSharing(space)).SpaceIds.Order();

        Assert.Equal(new[] { primary, sub }.Order(), Sharers(sub));
        Assert.Equal(new[] { primary, sub }.Order(), Sharers(primary));
        Assert.Equal([alone], Sharers(alone));
    }
}
