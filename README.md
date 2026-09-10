# Tail Tally

Local-first mobile app for multi-pet households to coordinate feeding, walks, litter care, and supply reminders with offline history and export—no accounts required.

## Motivation

Households with one or more pets often track routines in scattered notes, chat threads, or memory. That causes duplicate feedings, missed walks, unclear handoffs, and poor visibility into recurring supply needs.

## Target users

- Multi-person households sharing pet-care responsibilities
- Solo pet owners who want a simple daily routine/history log
- Pet sitters within a home context (not a commercial booking platform)

## Concrete use cases

- Mark a dog walk as done, with time and optional notes
- Record cat litter scooping/refresh events and see last-completed status
- Track feeding events per pet to avoid double-feeding
- Log low-supply events (food/litter/waste bags) and schedule reminders
- Export routine history for personal records or sitter handoff

## End-to-end workflow

1. Create household profile (local-only) and add pets.
2. Define reusable routines (feeding, walks, litter, grooming, meds-reminder as non-clinical schedule only).
3. Assign optional responsibility defaults (person A mornings, person B evenings).
4. Complete routine events from a daily timeline with quick actions.
5. Review today/week history and outstanding tasks.
6. Export JSON/CSV backup for transfer or archival.

## MVP features

- Pet profiles (name, species, optional photo, routine preferences)
- Reusable routine templates with schedule windows
- Daily timeline with completion logging and edit/undo
- Simple assignment/handoff markers for shared households
- Local notifications for upcoming/overdue routine windows
- Local export/import (JSON backup + CSV activity export)
- Accessibility baseline (dynamic type, high contrast support, screen-reader labels)

## Non-goals (MVP)

- No cloud sync/accounts/subscriptions
- No telehealth, diagnosis, treatment, or emergency detection
- No wearable/GPS live tracking
- No marketplace, payments, or sitter hiring workflows
- No smart-feeder or IoT automation in initial scope

## Platforms and framework

- Primary: iOS + Android
- Framework: Flutter (single cross-platform codebase)
- Local storage: SQLite via Drift

## Privacy, permissions, and data ownership

- Local-first storage by default; no mandatory remote services
- No account required to use core features
- Data export/import is user-controlled and explicit
- Optional permissions requested just-in-time:
  - Notifications (routine reminders)
  - Photos (pet profile images)
- No background microphone/location collection
- Users can delete all local data from in-app settings

## Health/wellness limitation

Tail Tally is a routine organizer, not a veterinary or medical device. It does not diagnose conditions, recommend treatment, or provide emergency monitoring.

## Current status

The Flutter workspace and automated format, analysis, test, Android, and iOS
compile gates are in place. The local data model (Drift schema, repositories,
migrations) is implemented, and the primary daily workflow now exists: a
grouped daily timeline (overdue / due now / coming up / done today), one-tap
completion with an optional note, bounded undo, and shared-handoff markers
showing who completed each routine. Duplicate completions are guarded both in
the domain workflow (transactional check) and in the store (partial unique
index on `done` events). Product features continue in milestone order.

### Milestones

- M1: Project skeleton, CI, and local domain model
- M2: Routine timeline + completion workflow
- M3: Notifications, export/import, privacy controls
- M4: Accessibility hardening and release packaging

## Development quickstart

Install [Flutter 3.47.2](https://docs.flutter.dev/get-started/install) (Dart
3.13.2), plus the Android or iOS tooling required for the device you target.
Then run from the repository root:

```bash
flutter --version
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test
flutter run
```

`flutter --version` must report Flutter `3.47.2` and Dart `3.13.2`. Core app
usage is offline and requires no account or cloud service. CI runs the same
quality gates and also compiles an Android debug APK and an unsigned iOS
simulator target.

## Source layout

- `lib/app/` — Flutter UI, navigation, state, and composition
- `lib/domain/` — pure-Dart entities, rules, use cases, and contracts
- `lib/data/` — local Drift/SQLite and import/export implementations
- `lib/platform/` — device notifications, permissions, and file adapters
- `test/` — unit and widget tests

See [`docs/architecture.md`](docs/architecture.md) for dependency rules.

## Repository source of truth note

If this project later adds hardware integration, final BOM data will live in KiCad schematic symbol properties and be exported to `bom/bom.csv`. For the current mobile-only MVP, no hardware BOM is maintained.
