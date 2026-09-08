# Platform boundary

Owns narrow adapters for device capabilities such as local notifications,
permission prompts, and user-selected local files. Adapters expose interfaces
that can be replaced in tests and must not introduce mandatory cloud services,
accounts, background location, or microphone access.