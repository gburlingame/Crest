using CrestCore.Application;
using CrestCore.Domain;

namespace CrestCore.Contracts;

#region Types

/// The address a New Tab bar opens: a page, or a search with the Space's
/// engine. Null when the text names nothing a page can load, as blank text
/// does.
public sealed record NewTabDestination(string? Address);

#endregion

/// What the New Tab bar of window `WindowId` opens for `Text` in the Space the
/// window shows. Only reading what the window shows holds the lock.
public sealed record NewTabAddress(Guid WindowId, string Text) : Query<NewTabDestination> {
    #region Variables

    internal override bool AnsweredUnderLock => false;

    #endregion

    #region Actions - Answering

    internal override NewTabDestination Answer(CrestApp app) {
        Palette palette;
        lock (app.Gate) palette = app.Device.Palette(WindowId, null, app.Pages.OpensInternalPages, app.Clock.Now);
        return new(palette.NewTabAddress(Text));
    }

    #endregion
}
