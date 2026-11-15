import Foundation

/// Thundermist's two-color gradients, which the Mac's welcome page cycles
/// through in place of the templates' heraldic looks.
extension SpaceScheme {
    // MARK: - Variables

    /// The two-color gradients, without the neutral scheme.
    static var gradients: [SpaceScheme] { all.filter { $0 != .neutral } }
}
