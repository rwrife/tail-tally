# App boundary

Owns Flutter widgets, navigation, presentation state, and application-level
composition. The app layer may depend on `domain`, and wires implementations
from `data` and `platform` at the composition root.

Business rules and persistence or operating-system APIs do not belong here.