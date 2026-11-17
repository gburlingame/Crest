using CrestCore.Contracts;

using Xunit;

namespace CrestCore.Tests;

/// Closing a folder in Thundermist puts away the pages of the loaded tabs it
/// holds and leaves the window outside it.
public sealed partial class BrowserContractsTests {
    [Fact]
    public void ClosingAFolderPutsAwayItsLoadedTabsAndReturnsTheWindowToATabOutsideIt() {
        using var device = new TestDevice(MaximalDocument());
        var core = device.Authority;
        TestGrants.UnlockGuarded(device.Send, device.Workspace, core.Current);
        var space = core.Current.Spaces[0];
        Guid Id(string value) => Guid.Parse(value);
        Guid reading = Id("6F515CFC-FE0A-44E6-8284-B1140DD9976C"), splitWork = Id("95812E93-F38A-45CC-B9F0-4FF591FEA03B"),
            saved = Id("4615461C-BA47-4054-B5CF-3DCAF3362D8C"), article = Id("B61250D4-3D4E-4DD6-8871-0BB326669142"),
            left = Id("428CAA9C-9A7A-4386-B120-F6096032C167"), right = Id("942AC076-B0D8-454B-9EEB-3791E6113F77"),
            start = Id("056F15C0-13CE-4ED0-B9FE-DD4A9D05A56D");
        var window = device.Open(space.Id);
        foreach (var tab in new[] { start, saved, article }) device.Send(new ShowTab(window, space.Id, tab));

        // The saved folder's loaded tabs, the one in the folder inside it
        // included, put their pages away and keep their places, back at their
        // saved addresses when the app's preferences say so. A loaded tab
        // outside the folder stays. The window skips `saved`, which it showed
        // before `article` but which closed with it, for the tab before that.
        var putAway = device.Send(new CloseFolder(device.Workspace, window, space.Id, reading, [start, saved, article]))
            .OfType<TabPagePutAway>();
        var closed = core.Current.Spaces[0];
        Assert.True(closed.Folders.Single(folder => folder.Id == reading).IsCollapsed);
        Assert.Equal(start, device.Tab(window, space.Id));
        Assert.Equal([
            new TabPagePutAway(device.Workspace, window, space.Id, saved, KeepsState: true),
            new TabPagePutAway(device.Workspace, window, space.Id, article, KeepsState: false)], putAway);
        var kept = closed.Tabs.Single(tab => tab.Id == article);
        Assert.Equal((TabPlacement.Saved, "https://news.example/article"), (kept.Placement, kept.Url));

        // A folder of open tabs keeps them, split and all, and only puts their
        // pages away, keeping what brings each back.
        device.Send(new ShowTab(window, space.Id, right));
        putAway = device.Send(new CloseFolder(device.Workspace, window, space.Id, splitWork, [left, right]))
            .OfType<TabPagePutAway>();
        closed = core.Current.Spaces[0];
        Assert.True(closed.Folders.Single(folder => folder.Id == splitWork).IsCollapsed);
        Assert.Equal(start, device.Tab(window, space.Id));
        Assert.Equal([
            new TabPagePutAway(device.Workspace, window, space.Id, left, KeepsState: true),
            new TabPagePutAway(device.Workspace, window, space.Id, right, KeepsState: true)], putAway);
        Assert.All(closed.Tabs.Where(tab => tab.Id == left || tab.Id == right),
            tab => Assert.Equal((TabPlacement.Current, splitWork), (tab.Placement, tab.FolderId)));
        Assert.Single(closed.SplitGroups);
    }
}
