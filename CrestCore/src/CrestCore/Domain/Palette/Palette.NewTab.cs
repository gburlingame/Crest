using CrestCore.Contracts;

namespace CrestCore.Domain;

/// What a New Tab bar opens for the text typed into it.
public sealed partial class Palette {
    #region Actions - New Tab

    /// The address a New Tab bar opens for `text`: what the address rules of
    /// every typed address load, except that a name typed without a scheme,
    /// which they open over https for its dot alone, opens only when it ends
    /// in a public domain ending, and otherwise searches with the Space's
    /// engine. Null when the text names nothing a page can load.
    public string? NewTabAddress(string text) {
        AddressResolution? resolution;
        try {
            resolution = AddressResolution.Resolve(text, context.Search, context.AllowsInternalPages);
        } catch (Rejected refused) when (refused.Rejection is UnsupportedAddress) {
            return null;
        }
        if (resolution is null) return null;
        string typed = text.Trim();
        bool readAsBareName = resolution.SearchQuery is null && resolution.Url == "https://" + typed;
        if (readAsBareName && Uri.TryCreate(resolution.Url, UriKind.Absolute, out var site) && !DomainEnding.Ends(site))
            return context.Search.Search(typed);
        return resolution.Url;
    }

    #endregion
}
