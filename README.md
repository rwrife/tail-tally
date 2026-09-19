# Tail Tally

A native SwiftUI app for keeping pet-care routines on track. Built for **iPhone, iOS 17 or later**, with no accounts, servers, analytics, or third-party dependencies.

## Features

- Pet profiles, household members, routine assignments, and weekly schedule windows
- Today’s timeline grouped into overdue, due now, coming up, and completed routines
- One-tap completion, optional notes and attribution, and undo for the three most recent completions in a session
- History with today/week/all filters and note corrections
- Optional local notifications, lead times, and quiet hours
- Versioned JSON backup/restore, date-range CSV export, retention, and confirmed deletion
- Native navigation, forms, Dynamic Type, VoiceOver labels, and light/dark appearance

All household data stays in an atomically written, protected JSON file in Application Support. Files are exported or imported only through the system document picker. Household attribution is local to this iPhone; devices do not sync.

## Build and run

Open `TailTally.xcodeproj`, select the **TailTally** scheme, choose an iPhone simulator, and Run. For a physical iPhone, choose your development team in Signing & Capabilities. Xcode 15 or newer is required (validated with Xcode 26.6).

```sh
# If the system defaults to Command Line Tools, select Xcode for this shell:
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
swift test
xcodebuild -project TailTally.xcodeproj -scheme TailTally \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```

The app target uses `TARGETED_DEVICE_FAMILY = 1`; iPad, Mac Catalyst, Designed for Mac, and Designed for Apple Vision support are disabled. iPadOS may still offer Apple’s iPhone compatibility mode; there is no native iPad target. The Swift package’s macOS platform exists only to run the domain tests on a development Mac.

## Migration from Flutter

The native app replaces the Flutter/Android workspace. Before replacing an existing Flutter installation, use **Privacy & data → Export backup (JSON)**. Import that file in the native app’s **Settings → Restore from backup**. Version 1 / schema 4 Flutter backups remain readable, including UTC timestamps and reminder/retention settings. The old SQLite database is not automatically migrated or deleted. Photo references in old backups are preserved as metadata; profile-photo selection and display are not implemented.

## Source layout

- `TailTally/` — SwiftUI app, household management, settings, notification adapter, and assets
- `Sources/TailTallyCore/` — Foundation-only models, scheduling, backup/CSV validation, atomic store
- `Tests/TailTallyCoreTests/` — native domain and persistence regression tests
- `app-store/` — App Store copy and 6.5-inch screenshots
- `scripts/` — repeatable screenshot capture

Notifications cover the next seven days (at most 60 pending requests) and refresh after changes, when opening the app, and on significant clock changes. Reopen the app regularly to replenish them. No background refresh is promised.

Tail Tally is a routine organizer, not a veterinary advice or emergency-monitoring service. See [architecture](docs/architecture.md) and the [release checklist](docs/release-checklist.md).
