import Foundation
import XCTest

@testable import Crest

/// Thundermist on Mac offers no Heraldic style, so a device that showed its
/// Spaces in Heraldic moves them to the style they show now, once.
@MainActor
final class ThundermistStyleTests: XCTestCase {
    func testSpacesLeaveHeraldicOnceAndKeepTheLookChosenAfter() throws {
        let name = "crest-test-appearance-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        // A device whose appearance a release before the styles stored has no
        // style, so its Spaces still wear their templates' banners and crests.
        let appearance = BrowserDeviceAppearanceStore(defaults: defaults)
        let seed = SpaceState.Seed.blank(number: 1).wearing(SpaceHouse.winter.look, symbol: "globe", name: "Winter")
        let browser = BrowserStore(
            seed: SessionState.Seed(spaces: [seed]), showing: seed.id, tabs: [seed.id: seed.tabs[0].id])

        browser.leaveHeraldicStyle(appearance: appearance, defaults: defaults)
        let moved = try XCTUnwrap(browser.spaceModel(seed.id)).settings.look
        XCTAssertEqual(appearance.customizationStyle, .modern)
        XCTAssertEqual(moved.themeMode, .gradient)
        XCTAssertEqual(moved.iconStyle, .simpleSymbol)
        XCTAssertEqual(moved.colors, SpaceHouse.winter.look.colors)
        XCTAssertEqual(defaults.string(forKey: BrowserDeviceAppearanceStore.customizationStyleKey), "modern")

        // A solid Modern fill the person chooses afterward survives the next
        // launch, which finds the stored style and moves nothing.
        var solid = moved
        solid.themeMode = .banner
        solid.bannerPattern = .solid
        browser.updateSpaceBranding(solid, in: seed.id)
        let chosen = try XCTUnwrap(browser.spaceModel(seed.id)).settings.look
        browser.leaveHeraldicStyle(appearance: appearance, defaults: defaults)
        XCTAssertEqual(try XCTUnwrap(browser.spaceModel(seed.id)).settings.look, chosen)
    }
}
