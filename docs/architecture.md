# Native architecture

`TailTallyCore` is a local Swift package with Foundation-only models, scheduling rules, validated backup serialization, CSV escaping, retention, and an atomic file store. The iPhone app imports this module; the domain module never imports SwiftUI, UIKit, or UserNotifications.

`AppModel` owns state on the main actor. Each mutation edits a value copy, validates it, persists it atomically, and only then publishes it. A failed load locks ordinary mutations rather than overwriting existing data with an empty household. Restore validates before replacement. Delete-all verifies the saved empty state. iOS writes use file protection until first authentication.

Schedule times are local wall-clock values with ISO weekdays. Calendar-day arithmetic handles midnight and daylight-saving changes. Completion timestamps are absolute dates. Native completions carry a window/day key to avoid satisfying two windows or changing identity on timezone travel. Legacy backups without occurrence keys retain the previous-close/next-open attribution rule.

Backups retain the original v1/schema-4 envelope and table names, with optional native completion IDs and occurrence keys. Unknown versions, broken references, duplicate IDs/completions, invalid times, and invalid preferences are rejected before writes. The original Flutter SQLite store requires explicit export/import; it is never silently replaced.

Notification refreshes are serialized and cancel the old pending plan before scheduling the new one. Permission is requested only when reminders are enabled. Each plan covers the next seven days, with the earliest 60 notifications kept. Quiet hours suppress rather than postpone a reminder.

Screenshots use DEBUG-only launch arguments and fictional household fixtures in a separate store. Release builds do not expose screenshot arguments or seed data.
