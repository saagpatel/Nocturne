import XCTest
import GRDB
@testable import Nocturne

final class StarCatalogTests: XCTestCase {

    func testBundledDatabaseRowCount() throws {
        guard let path = Bundle.main.path(forResource: "gaia_dr3", ofType: "sqlite") else {
            XCTFail("gaia_dr3.sqlite not found in test bundle")
            return
        }

        var configuration = Configuration()
        configuration.readonly = true
        let dbQueue = try DatabaseQueue(path: path, configuration: configuration)

        let count = try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM stars WHERE vmag <= 7.0")
        }

        guard let count else {
            XCTFail("COUNT query returned nil")
            return
        }

        XCTAssertGreaterThanOrEqual(count, 20_000, "Expected at least 20,000 stars")
        XCTAssertLessThanOrEqual(count, 30_000, "Expected at most 30,000 stars")

        let credit = try dbQueue.read { db in
            try String.fetchOne(db, sql: "SELECT credit FROM provenance")
        }
        XCTAssertEqual(credit, "ESA/Gaia/DPAC")
    }
}
