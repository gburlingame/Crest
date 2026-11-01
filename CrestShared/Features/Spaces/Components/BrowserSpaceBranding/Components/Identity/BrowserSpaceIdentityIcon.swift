import SwiftUI

struct BrowserSpaceIdentityIcon: View {
    let identity: BrowserSpaceIdentity
    var size: CGFloat = 24

    init(space: some BrowserSpaceIdentifying, size: CGFloat = 24) {
        self.init(identity: space.identity, size: size)
    }

    init(identity: BrowserSpaceIdentity, size: CGFloat = 24) {
        self.identity = identity
        self.size = size
    }

    /// On the Mac the icon follows the tone of whatever it sits on, since a
    /// gradient's own colors would vanish into the sidebar that shows them.
    private var symbolStyle: some ShapeStyle {
        #if os(macOS)
            HierarchicalShapeStyle.primary
        #else
            identity.branding.resolvedSymbolColor.color
        #endif
    }

    var body: some View {
        Group {
            switch BrowserSpaceIdentityArtwork(identity) {
            case .crest:
                BrowserSpaceCrestIcon(
                    branding: identity.branding,
                    size: size
                )
            case .symbol(let systemImage):
                if let emoji = BrowserIconSymbol.emoji(from: systemImage) {
                    Text(emoji)
                        .font(.system(size: size * 0.68))
                        .frame(width: size, height: size)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: size * 0.56, weight: .semibold))
                        .foregroundStyle(symbolStyle)
                        .frame(width: size, height: size)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

#if DEBUG
    #Preview("Symbol and locked crest") {
        HStack(spacing: 24) {
            BrowserSpaceIdentityIcon(space: BrowserSpaceBrandingPreviewFixture.simpleSpace, size: 32)
            BrowserSpaceIdentityIcon(space: BrowserSpaceBrandingPreviewFixture.crestSpace, size: 64)
        }.padding()
    }
#endif
