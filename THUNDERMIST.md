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

The tracked Xcode project is kept current with the fork's own files: the
update script regenerates it from `project.yml` after every merge, so building
straight from Xcode works.

- Upstream files edited: `Crest.xcodeproj/project.pbxproj` (regenerated)
- Files added: `Scripts/update-thundermist.sh`,
  `Scripts/thundermist-update-reminder.sh`

## Appearance and behavior

### Sidebar tab text at 14pt

Sidebar tabs on Mac use San Francisco Regular at 14pt, matching Arc, instead of
13pt, including at the default tab scale. The rename field uses the same font.
Touch layouts are unchanged.

- Upstream files edited:
  `CrestShared/Features/Sidebar/Styles/BrowserSidebarDensityFont.swift`,
  `CrestShared/Features/Sidebar/Support/BrowserSidebarDensity.swift`,
  `CrestShared/Features/Sidebar/Components/BrowserSidebarTabRow/Components/BrowserSidebarTabRenameField.swift`

### Simple gradient Space looks on Mac

A Space's Appearance page offers 16 two-color gradient presets, two color
pickers, and a plain icon or emoji, in place of the medieval crest editor. New
Spaces work through the presets in turn, and setup on Mac skips the choice of
look. Stored crests and banners stay as they are but draw as plain icons and
gradients of their own colors on Mac, so the change can be reversed. iPhone and
iPad keep their editor.

- Upstream files edited (core): `Device.SetupDraft.cs`, `StartSetup.cs`,
  `DevicePlatform.cs`, `SpaceScheme.cs`, `SetupLook.cs`, `SpaceTemplate.cs`
  under `CrestCore/src/CrestCore/`
- Upstream files edited (Mac): the onboarding window
  (`BrowserOnboardingModernSheet.swift`, `BrowserOnboardingWelcomePage.swift`,
  `BrowserOnboardingWindowContent.swift`, `BrowserOnboardingFlow.swift`) and
  Space settings (`BrowserSettingsSpacePage.swift`,
  `BrowserSpaceEditorView.swift`, `BrowserSpaceSettingsTab.swift`)
- Upstream files edited (shared): `BrowserGettingStartedPracticeSidebar.swift`,
  `SetupLook+Preview.swift`, `BrowserSpaceThemeField.swift`,
  `BrowserSpaceIdentityIcon.swift`, `BrowserSpaceIdentityArtwork.swift`,
  `BrowserSpaceSymbolArtworkIdentity.swift`
- Files added: `CrestMac/Features/Settings/Components/BrowserSpaceLookEditor.swift`,
  `CrestShared/Domain/BrowserSpace/Branding/SpaceBranding+Gradient.swift`

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

## No longer different

- **Readable password prompts.** The fork made password prompts opaque and
  their cross-origin warning readable. Upstream then drew every flyout on a
  solid surface with a contrast-safe warning color, so the fork took upstream's
  version. Only the fork's release note remains.
