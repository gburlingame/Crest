import Foundation

#if os(macOS)
    /// Thundermist on Mac offers no heraldic theming. A device that stored no
    /// style, as every release before the styles did, or stored Heraldic,
    /// shows its Spaces in Heraldic's look, so they move to the style they
    /// show now, once.
    extension BrowserStore {
        // MARK: - Mutators

        /// Gives every Space whose stored style was Heraldic, its own or the
        /// shared one, its look in the style it shows now, then stores the
        /// styles, so the move happens only once.
        func leaveHeraldicStyle(
            appearance: BrowserDeviceAppearanceStore = .shared,
            defaults: UserDefaults = BrowserFolderAppearancePreference.defaults
        ) {
            let heraldic = BrowserCustomizationStyle.heraldic.name
            let shared = defaults.string(forKey: BrowserDeviceAppearanceStore.customizationStyleKey)
            let own =
                defaults.dictionary(forKey: BrowserDeviceAppearanceStore.spaceCustomizationStylesKey)
                as? [String: String] ?? [:]
            let sharedWasHeraldic = shared == nil || shared == heraldic
            guard sharedWasHeraldic || own.values.contains(heraldic) else { return }
            let browser = profileSettingsBrowser
            for space in browser.availableSpaces
            where (own[space.id.uuidString].map { $0 == heraldic } ?? sharedWasHeraldic) {
                browser.restyle(
                    space, from: .heraldic, to: appearance.customizationStyle(for: space.id), appearance: appearance)
            }
            appearance.saveNow()
        }
    }
#endif
