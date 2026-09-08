# Architecture boundaries

Tail Tally uses a local-first layered structure under `lib/`:

| Folder | Responsibility | Allowed dependencies |
| --- | --- | --- |
| `app/` | Flutter UI, navigation, state, composition | `domain/`, plus concrete adapters only at composition roots |
| `domain/` | Entities, business rules, use cases, repository contracts | Dart standard library only |
| `data/` | Drift/SQLite repositories, migrations, backup/export adapters | `domain/` |
| `platform/` | Notifications, permissions, and local file adapters | `domain/` when implementing a domain-facing contract |

Dependencies point inward toward `domain/`. The domain layer never imports
Flutter, persistence libraries, platform channels, network clients, or account
services. Core pet-care routines remain available offline without an account.

The app is a routine organizer. These boundaries must not grow veterinary
diagnosis, treatment, or emergency-monitoring behavior.