# Data boundary

Owns local persistence implementations, Drift tables and migrations, and
backup/export serialization. It implements contracts from `domain`; it does
not own user-interface or operating-system permission behavior.

Tail Tally's core data path is local-only. Any future external integration must
remain optional and must not be required to use the app.