import GRDB

enum Migration001_Schema {
    static func migrate(_ db: Database) throws {
        try db.create(table: "measurements") { t in
            t.column("id", .text).primaryKey()
            t.column("measured_at", .integer).notNull()
            t.column("latitude", .double).notNull()
            t.column("longitude", .double).notNull()
            t.column("altitude_m", .double).notNull()
            t.column("sky_brightness", .double).notNull()
            t.column("raw_brightness", .double).notNull()
            t.column("iphone_model", .text).notNull()
            t.column("iso_value", .integer).notNull()
            t.column("exposure_s", .double).notNull()
            t.column("calibration_ver", .text).notNull()
            t.column("cloud_cover_pct", .integer)
            t.column("is_cloudy", .integer).notNull().defaults(to: 0)
            t.column("is_calibrated", .integer).notNull().defaults(to: 1)
            t.column("is_uploaded", .integer).notNull().defaults(to: 0)
            t.column("uploaded_at", .integer)
            t.column("device_tilt_deg", .double).notNull()
            t.column("bortle_class", .integer).notNull()
        }

        try db.create(
            index: "idx_measurements_uploaded",
            on: "measurements",
            columns: ["is_uploaded"]
        )
        try db.create(
            index: "idx_measurements_measured_at",
            on: "measurements",
            columns: ["measured_at"]
        )

        try db.create(table: "upload_queue") { t in
            t.column("measurement_id", .text).primaryKey()
                .references("measurements", column: "id")
            t.column("queued_at", .integer).notNull()
            t.column("attempts", .integer).notNull().defaults(to: 0)
            t.column("last_attempt", .integer)
        }
    }
}
