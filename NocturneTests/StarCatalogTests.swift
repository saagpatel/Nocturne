import XCTest
import GRDB
@testable import Nocturne

final class StarCatalogTests: XCTestCase {

    func testBundledDatabaseRowCount() throws {
        guard let path = Bundle.main.path(forResource: "hipparcos_tycho2", ofType: "sqlite") else {
            XCTFail("hipparcos_tycho2.sqlite not found in test bundle")
            return
        }

        var configuration = Configuration()
        configuration.readonly = true
        let dbQueue = try DatabaseQueue(path: path, configuration: configuration)

        let count = try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM stars WHERE vmag <= 10.0")
        }

        guard let count else {
            XCTFail("COUNT query returned nil")
            return
        }

        XCTAssertGreaterThanOrEqual(count, 100_000, "Expected at least 100,000 stars")
        XCTAssertLessThanOrEqual(count, 400_000, "Expected at most 400,000 stars")
    }
}
