# Tail Tally Plan

## 1) Scope and architecture

Tail Tally is a local-first mobile lifestyle app for shared pet-care routines.

### In scope (MVP)

- Flutter mobile app (iOS/Android)
- Local SQLite data model for pets, routines, schedule windows, completion logs
- Daily timeline + fast complete/undo workflow
- Local notifications for routine windows
- JSON backup/restore and CSV export
- Basic household assignment/handoff metadata
- Accessibility-first UI baseline and regression checks

### Out of scope (MVP)

- Cloud accounts/sync
- Veterinary diagnostics/treatment guidance
- Real-time GPS/wearable telemetry
- Third-party sitter marketplace workflows
- IoT actuator integration

### Proposed architecture

- `app/` Flutter UI and application layer
- `domain/` use-cases and business rules
- `data/` Drift repositories + serialization adapters
- `platform/` notification and permission bridges
- `test/` unit, widget, and integration tests

## 2) Technology choices and rationale

- **Flutter + Dart**: one codebase for iOS/Android with strong UI/accessibility tooling
- **Drift + SQLite**: robust local relational model with migrations and query safety
- **flutter_local_notifications**: deterministic local reminders without cloud dependency
- **json_serializable/freezed (planned)**: stable model serialization for backup/restore

## 3) Milestones and dependency order

1. **Foundation**: Flutter workspace, lint/test CI, module boundaries
2. **Data core**: Drift schema + repositories + migrations
3. **Primary workflow**: routine template creation and timeline completion loop
4. **Shared-home UX**: assignment/handoff fields, timeline filtering by person/pet
5. **Privacy/data ownership**: export/import, delete-all-data controls, retention settings
6. **Accessibility hardening**: screen-reader semantics, color contrast, text scaling
7. **Packaging**: signed release candidates, changelog, onboarding docs

## 4) Testing strategy

- Unit tests for scheduling logic, recurrence windows, completion conflict rules
- Drift integration tests for migrations and backup/restore round-trips
- Widget tests for timeline flows and accessibility labels
- Golden tests for key screens at multiple text scales
- Smoke integration test for notifications and permission prompts

## 5) Packaging and distribution plan

- CI builds for Android and iOS targets
- Internal test builds first (debug/profile), then release candidates
- Documented release checklist and semantic versioning
- Export/import compatibility matrix by schema version

## 6) Risks

- Recurrence/timezone edge cases can create duplicate or missed tasks
- Notification behavior differs by OS vendor and battery policies
- Over-complicated assignment model could hurt usability
- Schema migration mistakes can compromise local data

## 7) Explicit non-goals

- No claim of veterinary correctness or medical safety
- No cloud requirement for baseline operation
- No hidden telemetry in MVP
- No dependency on paid external APIs
