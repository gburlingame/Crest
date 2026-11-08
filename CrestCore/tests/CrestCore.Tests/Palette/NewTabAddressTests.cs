using CrestCore.Contracts;

using Xunit;

namespace CrestCore.Tests;

/// What a window's New Tab bar opens for what was typed: an address spelled in
/// full, a site whose name ends in a real domain ending, or a device on this
/// network, and a search with the Space's engine for anything else.
public sealed partial class BrowserContractsTests {
    [Theory]
    [InlineData("https://example.com/path", "https://example.com/path")]
    [InlineData("github.com", "https://github.com")]
    [InlineData("news.bbc.co.uk/sport", "https://news.bbc.co.uk/sport")]
    [InlineData("192.168.1.1", "http://192.168.1.1")]
    [InlineData("localhost:3000", "http://localhost:3000")]
    [InlineData("nas.local", "http://nas.local")]
    [InlineData("192.16", "https://duckduckgo.com/?q=192.16")]
    [InlineData("3.14", "https://duckduckgo.com/?q=3.14")]
    [InlineData("node.js", "https://duckduckgo.com/?q=node.js")]
    [InlineData("swift actors", "https://duckduckgo.com/?q=swift%20actors")]
    [InlineData("   ", null)]
    public void ANewTabOpensAnAddressThatCanBeReachedAndSearchesEverythingElse(string typed, string? opens) {
        var (document, space, _) = SavedSession();
        using var device = new TestDevice(document["session"]!);
        var window = device.Open(space);

        Assert.Equal(opens, device.Query(new NewTabAddress(window, typed)).Address);
    }
}
