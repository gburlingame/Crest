using CrestCore.Contracts;
using CrestCore.Domain;

using Xunit;

namespace CrestCore.Tests;

/// Thundermist spells the engine's own pages `thundermist://`, while the core
/// holds them as the `crest://` addresses the engine knows.
public sealed class ThundermistAddressTests {
    private static SearchProvider Kagi() =>
        CustomSearchProvider.Carried(Guid.Parse("00000000-0000-0000-0000-000000000264"), "Kagi", "https://kagi.com/search?q=%s", null).Admitted()
            .Provider;

    [Fact]
    public void AnEnginePageTypedAsThundermistsLoadsTheCrestPageItNames() {
        Assert.Equal("crest://settings/onStartup",
            AddressResolution.Loading("thundermist://settings/onStartup", Kagi(), allowsInternalPages: true));
        Assert.Equal("crest://extensions/", AddressResolution.Loading(" Thundermist://extensions/", Kagi(), allowsInternalPages: true));
        Assert.Equal("crest://flags/", AddressResolution.Held("thundermist://flags/", allowsInternalPages: true));
        // An engine that shows no internal pages searches for what was typed.
        var typed = AddressResolution.Typed("thundermist://settings", Kagi(), allowsInternalPages: false);
        Assert.Equal("thundermist://settings", typed.SearchQuery);
        Assert.Null(AddressResolution.Held("thundermist://flags/", allowsInternalPages: false));
    }

    [Fact]
    public void AnEnginePageReadsAsThundermistsAndEveryOtherAddressAsItIs() {
        Assert.Equal("thundermist://settings/onStartup", AddressResolution.Presented("crest://settings/onStartup"));
        Assert.Equal("thundermist://extensions/", AddressResolution.Presented("CREST://extensions/"));
        Assert.Equal("https://example.com/crest://", AddressResolution.Presented("https://example.com/crest://"));
        Assert.Equal("chrome-extension://abc/", AddressResolution.Presented("chrome-extension://abc/"));
    }
}
