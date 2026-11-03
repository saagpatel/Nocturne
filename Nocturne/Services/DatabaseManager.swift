import Foundation
import GRDB

struct DatabaseManager: Sendable {

    let dbQueue: DatabaseQueue

    /// Opens (or creates) the runtime database and runs all pending migrations.
    static func makeDefault() throws -> DatabaseManager {
        let url = try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask,
                 appropriateFor: nil, create: true)
            .appendingPathComponent(DatabaseConstants.localDatabaseName)
        return try make(at: url)
    }

    /// Opens (or creates) the database file at `url` and runs all pending migrations.
    static func make(at url: URL) throws -> DatabaseManager {
        var configuration = Configuration()
        configuration.foreignKeysEnabled = true

        // Open first: setting a resource value on a file that does not exist yet throws. And pass the
        // decoded path: `url.path()` percent-encodes "Application Support" as "Application%20Support", a
        // directory that does not exist (SQLite error 14). Both left fresh installs with no local
        // database ("History Unavailable").
        let dbQueue = try DatabaseQueue(path: url.path(percentEncoded: false), configuration: configuration)

        // Exclude from iCloud backup
        var resourceURL = url
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try resourceURL.setResourceValues(resourceValues)

        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        migrator.registerMigration("001_schema", migrate: Migration001_Schema.migrate)
        migrator.registerMigration(
            "002_reset_provisional_calibration",
            migrate: Migration002_ResetProvisionalCalibration.migrate
        )
        try migrator.migrate(dbQueue)

        return DatabaseManager(dbQueue: dbQueue)
    }

    /// Creates an in-memory database for unit tests.
    static func makeInMemory() throws -> DatabaseManager {
        var configuration = Configuration()
        configuration.foreignKeysEnabled = true
        let dbQueue = try DatabaseQueue(configuration: configuration)

        var migrator = DatabaseMigrator()
        migrator.registerMigration("001_schema", migrate: Migration001_Schema.migrate)
        migrator.registerMigration(
            "002_reset_provisional_calibration",
            migrate: Migration002_ResetProvisionalCalibration.migrate
        )
        try migrator.migrate(dbQueue)

        return DatabaseManager(dbQueue: dbQueue)
    }

    /// Opens the bundled read-only Gaia DR3 display catalog.
    static func openStarCatalog() throws -> DatabaseQueue? {
        guard let path = Bundle.main.path(
            forResource: DatabaseConstants.starCatalogName,
            ofType: "sqlite"
        ) else {
            return nil
        }
        var configuration = Configuration()
        configuration.readonly = true
        return try DatabaseQueue(path: path, configuration: configuration)
    }
}
