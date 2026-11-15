# Thundermist

Thundermist is a private build of [Crest](https://github.com/pauljoda/Crest),
kept on the `thundermist` branch of this fork. This file lists every way it
differs from upstream Crest. A change that lands on this branch adds or updates
its entry here in the same commit.

Each entry names the upstream files it edits, because those are the files a
merge from upstream can conflict on. Files the fork adds are listed separately;
upstream never touches them.

## Build and updates

### Its own app identity

Thundermist has its own name, bundle identifier (`com.theburl.thundermist`),
iCloud container and data folder, so it runs beside an installed official
Crest without sharing anything. It is signed with this Mac's Apple Development
identity. Software updates are off, so an official update can never replace
it; it updates by rebuilding from source. Passkeys and iCloud Passwords stay
off until Apple grants the managed capability to this team.

- Upstream files edited: `CrestMac/App/BrowserMacApplication.swift`,
  `CrestMac/Configuration/Crest-Info.plist`,
  `CrestShared/Application/ProductIdentity.swift`,
  `Scripts/control-plane/package-chromium-host.py` (replaces the prebuilt
  engine's fixed profile path), `CrestTests/BrowserSoftwareUpdateTests.swift`
  (confirms official updates can't replace this build)
- Files added: `CrestMac/Configuration/Thundermist.entitlements`,
  `Scripts/install-thundermist.sh`

### The Thundermist name

The app shows the name Thundermist. The name is applied to a copy of the source
just before it is built, so upstream's text stays as it is and new upstream
text is renamed automatically. Only standalone uses of the word in string
literals, the translation catalog and the release notes change. Text compiled
into the prebuilt Chromium engine keeps the Crest name.

- Upstream files edited: none
- Files added: `Scripts/thundermist-rebrand.py`

### Updating from Crest

`Scripts/update-thundermist.sh` merges upstream Crest, resolves the conflicts
every merge of this fork can hit (the version, the release notes, the generated
contract files and the Xcode project), checks that Crest has published the
Chromium engine the merged code needs, runs the core tests, commits the merge
and reinstalls. Any other conflict cancels the merge. A weekly reminder checks
for upstream changes on Sundays and only notifies.

A merge can stop short of upstream's latest commit, to take the part that
doesn't conflict first, but only at a commit whose engine Crest still
publishes. Crest keeps just its last few engines, and a commit that changes
the engine's inputs can have none at all, so check
`python3 Scripts/control-plane/chromium_engine.py tag` at the chosen commit
against `gh release view <tag> --repo pauljoda/Crest` before merging it.

The tracked Xcode project is kept current with the fork's own files: the
update script regenerates it from `project.yml` after every merge, so building
straight from Xcode works.

- Upstream files edited: `Crest.xcodeproj/project.pbxproj` (regenerated)
- Files added: `Scripts/update-thundermist.sh`,
  `Scripts/thundermist-update-reminder.sh`

## Appearance and behavior

### Sidebar tab text at 14pt

Sidebar tabs on Mac use San Francisco Regular at 14pt, matching Arc, instead of
13pt, including at the default tab size. Upstream's tab size slider scales that
14pt as it scales 13pt: text moves half as far as the rows. The rename field
uses the same font. Touch layouts are unchanged.

- Upstream files edited:
  `CrestShared/Features/Sidebar/Styles/BrowserSidebarDensityFont.swift`,
  `CrestShared/Features/Sidebar/Support/BrowserSidebarDensity.swift`,
  `CrestShared/Features/Sidebar/Components/BrowserSidebarTabRow/Components/BrowserSidebarTabRenameField.swift`

### Thundermist gradients

Sixteen two-color gradients (Thundermist, Midnight, Ocean, Aurora, Forest,
Dusk, Plum, Ember, Graphite, Sunrise, Peach, Rose, Lavender, Sky, Seafoam and
Sand) are Space color schemes. Upstream's Modern editor lists every scheme
among its color presets, so they appear there with no editor change. New
Spaces take them in turn, and the first Space, Personal, and the Getting
Started practice Space wear the Thundermist gradient. Setup's look previews
start from it too.

The schemes are a list in `SpaceScheme.cs` that upstream may add to; a merge
that does conflicts there, and keeps both.

- Upstream files edited:
  `CrestCore/src/CrestCore/Contracts/Session/Branding/Terms/SpaceScheme.cs`
  (the gradients), `CrestCore/src/CrestCore/Domain/Spaces/SpaceTemplate.cs`
  and `CrestCore/src/CrestCore/Contracts/Setup/SetupLook.cs` (new Spaces take
  them in turn), `CrestShared/Features/Onboarding/Support/SetupLook+Preview.swift`

### Only Modern and Simple on Mac

Thundermist shows none of Crest's heraldic theming on Mac. Settings →
Appearance offers only the Modern and Simple styles, Modern is the default,
and a Space's own style can only be one of the two. A Space's editor leaves
out the full Crest Studio that upstream folds under Advanced, with its
banners, crests and heraldic emblems. Setup skips the choice of look and makes
Modern Spaces. Its welcome page shows a plain icon in the Thundermist
gradient, cycling through the gradients where Crest cycles through its
templates' banners. A Space's settings read Edit Look… instead of Edit Crest…
and leave out Artwork Credits, and the Getting Started practice sidebar shows
plain icons. iPhone and iPad keep upstream's choices.

A device that stored no style, as every release before the styles did, or
stored Heraldic, moves its Spaces to their look in the style they show now on
the first launch, then stores the styles so that happens only once. A stored
Heraldic style, shared or a Space's own, reads as none, so the Space follows
the default. Upstream's test that the default style is Heraldic now expects
Modern.

- Upstream files edited (core): `Device.SetupDraft.cs`, `StartSetup.cs` and
  `DevicePlatform.cs` under `CrestCore/src/CrestCore/` (setup skips the look)
- Upstream files edited (styles):
  `CrestShared/Features/Settings/Models/BrowserCustomizationStyle.swift`
  (the offered styles and the default),
  `CrestShared/Features/Settings/Components/BrowserLookAndFeelGroups/BrowserCustomizationStyleGroup.swift`
  (the style buttons),
  `CrestShared/Features/Spaces/Components/Forge/BrowserCrestForge.swift` (no
  Advanced studio), `CrestMac/App/BrowserMacApplication.swift` (the one-time
  move at launch), `CrestTests/BrowserSpaceBrandingTests.swift` (the default)
- Upstream files edited (Mac):
  `CrestMac/Features/Onboarding/BrowserOnboardingWindow/Components/BrowserOnboardingWelcomePage/BrowserOnboardingWelcomePage.swift`,
  `CrestMac/Features/Onboarding/BrowserOnboardingWindow/Components/BrowserOnboardingWindowContent.swift`,
  `CrestMac/Features/Onboarding/BrowserOnboardingWindow/Models/BrowserOnboardingFlow.swift`,
  `CrestMac/Features/Settings/Components/BrowserSettingsSpacePage.swift`,
  `CrestMac/Features/Settings/Models/BrowserSpaceSettingsTab.swift` (search
  terms)
- Upstream files edited (shared):
  `CrestShared/Features/GettingStarted/BrowserGettingStartedPracticeSidebar.swift`
- Files added: `CrestShared/Domain/BrowserSpace/Branding/SpaceScheme+Gradients.swift`,
  `CrestShared/Application/BrowserStore/BrowserStore+LeavingHeraldic.swift`,
  `CrestTests/ThundermistStyleTests.swift`

### Opaque command palette

The command palette, which ⌘L and the Start Page open, draws on the solid
window background instead of Liquid Glass, so the page behind it never shows
through. The Ctrl-Tab recent-tabs switcher keeps its glass.

- Upstream files edited:
  `CrestShared/Features/Chrome/Components/BrowserCommandPalette/Components/BrowserCommandPaletteCard.swift`,
  `CrestShared/Features/Chrome/Components/BrowserCommandPalette/Support/BrowserCommandPaletteOverlayTransition.swift`
  (a comment)

### New Tab is one field

New Tab (⌘T, and the sidebar's New Tab button) shows a single field instead of
the command palette, with no recent tabs, actions, history or suggestions.
Return opens what was typed in a new tab: the address it names, or a search
with the Space's default engine. Escape or a click beside the field closes it
without opening a tab. Editing an address with ⌘L, the Start Page's own field
and a Quick Window's palette keep the full command palette.

What counts as an address is stricter than in the rest of Crest. Text with a
scheme opens as typed; a full IP address, `localhost` or a local name such as
`nas.local` opens over http; and a name with a dot opens over https only when
it ends in a real domain ending, so `github.com` opens while `192.16`, `3.14`
and `node.js` search. The endings come from IANA's list, copied into
`DomainEnding.cs` with its version; refresh it from
https://data.iana.org/TLD/tlds-alpha-by-domain.txt when a new ending matters.
`CrestCore.Tests/Palette/NewTabAddressTests.cs` covers the rule, so a merge that
breaks it fails the update script's core tests.

- Upstream files edited:
  `CrestMac/Features/Browser/BrowserRootView/Components/CommandPalette/BrowserRootCommandPaletteLayer.swift`
  (shows the field for New Tab),
  `CrestMac/Features/Browser/BrowserRootView/Models/BrowserRootModel.swift`
  (keeps the sidebar's address field in place while it shows), and the
  generated contract files, which the update script regenerates
- Files added: `CrestCore/src/CrestCore/Application/App/Queries/NewTabAddress.cs`,
  `CrestCore/src/CrestCore/Domain/Palette/Palette.NewTab.cs`,
  `CrestCore/src/CrestCore/Domain/Navigation/DomainEnding.cs`,
  `CrestCore/tests/CrestCore.Tests/Palette/NewTabAddressTests.cs`,
  `CrestMac/Features/Browser/BrowserRootView/Components/CommandPalette/BrowserNewTabBar.swift`,
  `CrestMac/Features/Browser/BrowserRootView/Models/BrowserRootModel+NewTabBar.swift`

### A waterfall app icon

Thundermist's icon is a waterfall seen close up: land and trees along a river
above the lip, a wide curtain of water over the cliffs, and mist rising where
it lands. It shows golden hour in light mode and the afterglow just after
sunset in dark mode; macOS draws its Clear and Tinted styles from the same
layers. `Scripts/thundermist-icon.py` writes `Thundermist/Thundermist.icon`
from the colors and positions at its top, so a change to the icon is a change
there followed by running the script. The install script puts the icon in
place of Crest's in its build copy, under Crest's name, so builds straight
from the repository still show Crest's icon.

- Upstream files edited: none
- Files added: `Scripts/thundermist-icon.py`, `Thundermist/Thundermist.icon`

### No alternate app icons on Mac

Settings no longer offers Crest's nine palette icons, so Thundermist always
shows its own. The Dock tile plug-in, which drew a chosen palette icon while
the app wasn't running, is gone; the Dock tile still shows the count and
progress of downloads. iPhone and iPad keep Crest's palette icons.

- Upstream files edited: `project.yml` (the Mac targets leave out the palette
  icons, their previews and the plug-in), `CrestMac/Configuration/Crest-Info.plist`,
  `Scripts/control-plane/package-chromium-host.py`,
  `CrestMac/App/Shell/BrowserMacDockTile.swift`,
  `CrestMac/Features/AppIcon/BrowserMacAppIconAssets.swift`,
  `CrestMac/Features/AppIcon/BrowserMacDockTileView.swift` (a comment),
  `CrestMac/Features/Settings/BrowserPlatformLookAndFeelResetSection.swift`,
  `CrestMac/Features/Settings/Components/BrowserPlatformCurrentAppIcon.swift`,
  `CrestShared/Features/Settings/BrowserLookAndFeelSettingsPane.swift`,
  `CrestEngines/Chromium/Apple/ChromiumComposition.swift` (not an engine
  input; the engine key is unchanged)
- Files deleted: `CrestDockTilePlugin/CrestDockTilePlugin.swift`,
  `CrestMac/Features/Settings/BrowserPlatformAppIconSettingsSection.swift`

### New Folder from a tab and the File menu

Right-clicking a tab offers New Folder, which makes a folder in Saved Tabs and
moves the tab into it; with several tabs selected it reads New Folder with N
Tabs and moves them all. A selection that holds folders leaves it out, as it
does upstream's Move to Group, since New Folder files only tabs. The folder
goes inside the Saved Tabs folder the tabs
already share, and at the top of Saved Tabs otherwise, so a pinned or open tab
moves into Saved Tabs with it. File → New Folder makes an empty folder in
Saved Tabs, as the Space's ⋯ menu does, and shows the sidebar if it was
hidden. Either way Saved Tabs and the folders around the new one open, and its
name is ready to type. File → New Folder has no keys by default, since every
⌘N chord opens a window; Settings → Shortcuts can give it some. The item in
Add to Current Tabs Folder that makes a Current Tabs folder now reads New
Current Tabs Folder. iPhone and iPad are unchanged.

The command is the last in the core's command list, and its stored name is
`newFolder`. A merge that adds an upstream command conflicts in that list and
in `ShortcutCatalogTests.cs`; keep both commands.

- Upstream files edited:
  `CrestCore/src/CrestCore/Contracts/Shortcuts/ShortcutCommand.cs`,
  `CrestCore/src/CrestCore/Contracts/Shortcuts/ShortcutMenu.cs` (File menu),
  `CrestCore/tests/CrestCore.Tests/Shortcuts/ShortcutCatalogTests.cs`,
  `CrestMac/Features/Commands/Models/BrowserMacCommand.swift`,
  `CrestShared/Features/Sidebar/Components/BrowserTabBatchMenu.swift`,
  `CrestShared/Features/Sidebar/Components/BrowserTabOrganizationMenu/Components/BrowserTabOrganizationMenuContent.swift`,
  and the generated contract files, which the update script regenerates
- Files added: `CrestShared/Application/BrowserStore/BrowserStore+NewSavedFolder.swift`,
  `CrestShared/Features/Sidebar/Components/BrowserTabOrganizationMenu/Components/BrowserNewFolderMenuItem.swift`,
  `CrestMac/Features/Commands/Models/BrowserCommandActions+NewFolder.swift`

### Passwords fill in Sub-Spaces

A Sub-Space shares its group's session, and the group's primary keeps the
passwords. Crest offers those passwords on a Sub-Space's sign-in pages, but its
last check before filling accepted only a password the page's own Space keeps,
so choosing one failed with "The form changed before Crest could fill it." The
check now accepts a password any Space of the page's group keeps, which the core
answers with `CredentialSharing`. A Space outside the group still fills only its
own. Drop this entry and the fork's change if upstream fixes the check.

- Upstream files edited:
  `CrestShared/Application/Credentials/Models/BrowserCredentialPageState.swift`
  (the fill check), and the generated contract files, which the update script
  regenerates
- Files added: `CrestCore/src/CrestCore/Application/Credentials/Queries/CredentialSharing.cs`,
  `CrestCore/tests/CrestCore.Tests/Credentials/CredentialSharingTests.cs`

## No longer different

- **Readable password prompts.** The fork made password prompts opaque and
  their cross-origin warning readable. Upstream then drew every flyout on a
  solid surface with a contrast-safe warning color, so the fork took upstream's
  version. Only the fork's release note remains.
- **A gradient Space editor on Mac.** The fork replaced the crest editor with
  16 gradient presets, two color pickers and a plain icon or emoji, and drew
  every stored crest and banner as a plain icon and gradient on Mac. Upstream
  then added Modern and Simple styles whose editors cover the same ground, so
  the fork took upstream's editors and drawing and kept only its gradients
  (see Thundermist gradients).
