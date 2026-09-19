# Changelog

## 1.0 (3) — Native iPhone conversion

- Replaced Flutter and Android with SwiftUI and a native iPhone-only Xcode project, targeting iOS 17+.
- Added native pet, household, and weekly routine setup.
- Preserved daily timeline, completion/undo, notes, handoff markers, reminders, backup/restore, CSV, retention, and deletion.
- Added history browsing and note correction.
- Replaced Drift with validated atomic local JSON storage; existing Flutter JSON backups remain importable.
- Added native scheduling, DST, reminder, backup, and persistence tests, plus iOS-only CI.
- Installed the supplied green paw/checkmark/tail icon and prepared App Store copy and screenshots.

The previous Flutter candidate was 0.1.0-rc.1+2. Export a JSON backup before moving an existing Flutter installation to the native app.
