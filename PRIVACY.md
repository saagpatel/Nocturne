# Nocturne Privacy Policy

Effective October 4, 2026

Nocturne estimates night-sky brightness. It does not require an account and does not use advertising or cross-app tracking.

## Data Nocturne handles

- Camera frames are processed on your device to calculate a sky-brightness measurement. No photos or camera frames are saved or uploaded.
- Device motion is read on your device only to check phone tilt.
- Saved measurement records contain precise location, altitude, measurement time, device model, brightness values, Bortle class, capture/profile metadata, phone tilt and optional weather context. A displayed result does not guarantee a saved record if the local database is unavailable.
- Community contribution is off by default. If you enable it in Settings and uploads are configured and available, Nocturne sends the measurement time, coordinates, altitude, sky-brightness result, device model, profile version, cloud context, estimate status and Bortle class to its Supabase-backed community dataset. The upload does not include a name, email address, advertising identifier or Nocturne account.
- Weather requests send measurement coordinates to Open-Meteo to retrieve cloud cover, even when community contribution is off. History uses Apple reverse geocoding to turn stored coordinates into location names, and the map uses Apple MapKit. These online services are separate from the optional community upload.
- When the community backend is configured, the Map tab sends the visible map bounds to its Supabase-backed heatmap function to request community data, whether or not contribution is on. Cached data may be used instead of a new request.
- Apple platform services may provide diagnostics under Apple's own privacy terms. Nocturne does not include a third-party advertising or analytics SDK.

Location is used to validate whether a measurement was taken at night, orient the star comparison, label local history, and place contributed measurements on the community map. Camera and location access are requested only while you use the app.

## Your choices

You can deny camera or location permission in iOS Settings. In Nocturne's Settings, turn off Contribute measurements to stop future community uploads. This does not delete readings already uploaded. Allow cellular uploads controls whether community uploads can use cellular data. Saved local records are removed when you delete the app.

To request deletion of a contributed measurement, use the support link below to start a request without identifying details. It opens a GitHub issue that may be public. Ask for a private channel before providing a measurement timestamp, location or other identifying details. Do not post sensitive information in the issue.

## Contact

For privacy questions or deletion requests, use [Nocturne support](https://github.com/saagpatel/Nocturne/issues/new?template=privacy-request.md). This policy will be updated when Nocturne's data practices change.
