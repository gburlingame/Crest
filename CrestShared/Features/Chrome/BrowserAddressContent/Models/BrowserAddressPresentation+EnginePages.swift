import Foundation

/// Thundermist spells the engine's own pages `thundermist://`, as Chrome
/// spells them `chrome://`. The core holds them as the `crest://` addresses
/// the engine knows and reads `thundermist://` back when it is typed.
extension BrowserAddressPresentation {
    // MARK: - Static Variables

    private static let heldPrefix = "crest://"
    private static let shownPrefix = "thundermist://"

    // MARK: - Actions - Reading

    /// The text an address field holds for `address`: an engine page in
    /// Thundermist's spelling, and any other address as it is.
    static func fieldText(_ address: String) -> String {
        guard address.prefix(heldPrefix.count).lowercased() == heldPrefix else { return address }
        return shownPrefix + address.dropFirst(heldPrefix.count)
    }
}
