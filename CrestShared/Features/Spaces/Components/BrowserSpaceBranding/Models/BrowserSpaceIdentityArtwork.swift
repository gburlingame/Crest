enum BrowserSpaceIdentityArtwork: Equatable {
    case crest
    case symbol(String)

    init(_ identity: BrowserSpaceIdentity) {
        #if os(macOS)
            // The Mac shows every Space's plain icon. A stored crest stays
            // unused, so the choice can be reversed.
            self = .symbol(identity.symbol)
        #else
            self =
                identity.branding.iconStyle == .layeredCrest
                ? .crest
                : .symbol(identity.symbol)
        #endif
    }
}
