import SwiftUI

/// Says out loud that the form the prompt is about belongs to an embedded frame
/// rather than to the site in the address field.
struct BrowserCredentialCrossOriginNotice: View {
    let message: LocalizedStringKey

    var body: some View {
        // Orange marks the warning on the icon. The words stay in the primary
        // color, because orange text isn't readable on a light surface.
        Label {
            Text(message)
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: "rectangle.inset.filled.and.person.filled")
                .foregroundStyle(.orange)
        }
        .font(.caption.weight(.medium))
    }
}

#if DEBUG
    #Preview("Component") {
        BrowserCredentialCrossOriginNotice(message: "This sign-in form belongs to a different website.").padding()
            .frame(width: 360)
    }
#endif
