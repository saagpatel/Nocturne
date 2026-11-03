import XCTest
@testable import Nocturne

/// v1 ships without the community map and uploads; their backend is not hosted.
final class CommunityFeatureFlagTests: XCTestCase {

    func testCommunityFeaturesAreOffForV1() {
        XCTAssertFalse(FeatureFlags.communityEnabled)
    }

    @MainActor
    func testAppStateCreatesNoBackendClientWhenCommunityIsOff() throws {
        try XCTSkipIf(FeatureFlags.communityEnabled)
        let state = AppState()
        XCTAssertNil(state.supabaseService)
    }
}
