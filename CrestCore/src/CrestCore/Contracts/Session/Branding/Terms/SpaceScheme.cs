namespace CrestCore.Contracts;

/// A modern look a Space can start from: a plain sidebar, light or dark with
/// the device, under the Space's own icon, with no arms.
/// Choosing one copies its look into the Space, so a Space keeps the look it
/// was given when a scheme changes.
public sealed class SpaceScheme {
    #region Static Variables

    /// A neutral gray laid thinly over the window's own background, which
    /// settles it near #333 by night and #E5E5E5 by day, under a fine grain,
    /// with its icon in a mid gray. The values follow Arc's sidebar.
    public static readonly SpaceScheme Neutral = new("neutral", "Neutral", SchemeLook(
        [Tincture.NeutralSmoke], Tincture.NeutralGray, strength: 0.15, showsTexture: true));

    public static readonly SpaceScheme Thundermist = Gradient("thundermist", "Thundermist", new(0.169, 0.227, 0.333), new(0.402, 0.466, 0.536));
    public static readonly SpaceScheme Midnight = Gradient("midnight", "Midnight", new(0.078, 0.118, 0.188), new(0.208, 0.341, 0.490));
    public static readonly SpaceScheme Ocean = Gradient("ocean", "Ocean", new(0.059, 0.204, 0.376), new(0.126, 0.499, 0.589));
    public static readonly SpaceScheme Aurora = Gradient("aurora", "Aurora", new(0.043, 0.239, 0.298), new(0.170, 0.514, 0.403));
    public static readonly SpaceScheme Forest = Gradient("forest", "Forest", new(0.075, 0.306, 0.290), new(0.287, 0.504, 0.359));
    public static readonly SpaceScheme Dusk = Gradient("dusk", "Dusk", new(0.227, 0.110, 0.443), new(0.700, 0.355, 0.387));
    public static readonly SpaceScheme Plum = Gradient("plum", "Plum", new(0.176, 0.106, 0.306), new(0.557, 0.271, 0.522));
    public static readonly SpaceScheme Ember = Gradient("ember", "Ember", new(0.478, 0.122, 0.169), new(0.677, 0.385, 0.175));
    public static readonly SpaceScheme Graphite = Gradient("graphite", "Graphite", new(0.169, 0.180, 0.200), new(0.353, 0.376, 0.408));
    public static readonly SpaceScheme Sunrise = Gradient("sunrise", "Sunrise", new(0.965, 0.651, 0.486), new(0.969, 0.851, 0.659));
    public static readonly SpaceScheme Peach = Gradient("peach", "Peach", new(1.000, 0.604, 0.545), new(1.000, 0.827, 0.647));
    public static readonly SpaceScheme Rose = Gradient("rose", "Rose", new(0.949, 0.651, 0.702), new(0.973, 0.851, 0.769));
    public static readonly SpaceScheme Lavender = Gradient("lavender", "Lavender", new(0.722, 0.663, 0.910), new(0.902, 0.843, 0.961));
    public static readonly SpaceScheme Sky = Gradient("sky", "Sky", new(0.557, 0.773, 0.988), new(0.878, 0.765, 0.988));
    public static readonly SpaceScheme Seafoam = Gradient("seafoam", "Seafoam", new(0.659, 0.902, 0.812), new(0.863, 0.929, 0.757));
    public static readonly SpaceScheme Sand = Gradient("sand", "Sand", new(0.851, 0.769, 0.627), new(0.937, 0.890, 0.808));

    /// The two-color gradients, in the order new Spaces take them.
    private static readonly IReadOnlyList<SpaceScheme> Gradients =
        [Thundermist, Midnight, Ocean, Aurora, Forest, Dusk, Plum, Ember, Graphite, Sunrise, Peach, Rose, Lavender, Sky, Seafoam, Sand];

    public static IReadOnlyList<SpaceScheme> All { get; } = [Neutral, .. Gradients];

    #endregion

    #region Variables

    public string Name { get; }

    /// The scheme's name in the template gallery.
    [Localized]
    public string Title { get; }

    /// The look a Space starting from the scheme wears.
    public SpaceBranding Look { get; }

    #endregion

    #region Constructors

    private SpaceScheme(string name, string title, SpaceBranding look) {
        Name = name;
        Title = title;
        Look = look;
    }

    #endregion

    #region Actions - Lookup

    public static SpaceScheme? Named(string? name) => All.FirstOrDefault(scheme => scheme.Name == name);

    /// The gradient the `number`th new Space takes, counting from one, going
    /// back to the first after the last.
    public static SpaceScheme InTurn(int number) {
        ArgumentOutOfRangeException.ThrowIfLessThan(number, 1);
        return Gradients[(number - 1) % Gradients.Count];
    }

    #endregion

    #region Actions - Looks

    /// A scheme running from `start` at the top of the sidebar to `end` at its
    /// foot, at full strength with no fade, its text in whichever tone reads
    /// best, under the Space's own icon, which follows that tone.
    private static SpaceScheme Gradient(string name, string title, BrandColor start, BrandColor end) =>
        new(name, title, new(new([start, end]), SpaceBannerPattern.Diagonal, BannerStrength: 1, ReadabilityFade: 0,
            KeepsControlsReadable: false, SpaceThemeMode.Gradient, GradientAngle: 90, ShowsTexture: false,
            SpaceIconStyle.SimpleSymbol, SymbolColor: null, SpaceBranding.Neutral.Crest,
            SpaceBranding.BaselineRenderingVersion, FolderColorIntensity: 0, SpaceTextColorMode.Automatic,
            HasCustomAppearance: false));

    /// A scheme's look: its colors as a gradient at `strength` over the
    /// window's own background, with no readability fade, its text and
    /// controls following the device's appearance, and the Space's icon in
    /// place of a crest, drawn in `symbol`.
    private static SpaceBranding SchemeLook(Tincture[] colors, Tincture symbol, double strength, bool showsTexture) =>
        new(new([.. colors.Select(tincture => tincture.Color)]), SpaceBannerPattern.Diagonal, strength, ReadabilityFade: 0,
            KeepsControlsReadable: false, SpaceThemeMode.Gradient, GradientAngle: 0, showsTexture, SpaceIconStyle.SimpleSymbol,
            symbol.Color, SpaceBranding.Neutral.Crest, SpaceBranding.BaselineRenderingVersion, FolderColorIntensity: 0,
            SpaceTextColorMode.System, HasCustomAppearance: false);

    #endregion
}
