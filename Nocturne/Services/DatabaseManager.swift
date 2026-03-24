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

        // Exclude from iCloud backup
        var resourceURL = url
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try resourceURL.setResourceValues(resourceValues)

        var configuration = Configuration()
        configuration.foreignKeysEnabled = true

        let dbQueue = try DatabaseQueue(path: url.path(), configuration: configuration)

        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif
        migrator.registerMigration("001_schema", migrate: Migration001_Schema.migrate)
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
        try migrator.migrate(dbQueue)

        return DatabaseManager(dbQueue: dbQueue)
    }

    /// Opens the bundled read-only Hipparcos/Tycho-2 star catalog.
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
