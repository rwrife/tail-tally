import Foundation

public enum Backup {
    public static func encode(_ snapshot: Snapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(snapshot)
    }
    public static func decode(_ data: Data) throws -> Snapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: raw) { return date }
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: raw) else { throw TallyError.invalid("Invalid backup date.") }
            return date
        }
        let snapshot = try decoder.decode(Snapshot.self, from: data)
        try validate(snapshot)
        return snapshot
    }
    public static func validate(_ s: Snapshot) throws {
        func require(_ value: Bool, _ message: String) throws { if !value { throw TallyError.invalid(message) } }
        try require(s.manifest.backupVersion == 1 && (1...4).contains(s.manifest.appSchemaVersion), "This backup needs a different version of Tail Tally.")
        func ids<T>(_ list: [T], _ key: KeyPath<T, Int>) throws -> Set<Int> {
            let values = list.map { $0[keyPath: key] }
            try require(Set(values).count == values.count && values.allSatisfy { $0 > 0 && $0 < Int.max }, "Backup contains duplicate or invalid IDs.")
            return Set(values)
        }
        let members = try ids(s.members, \.id), pets = try ids(s.pets, \.id), routines = try ids(s.routines, \.id)
        let windows = try ids(s.scheduleWindows, \.id)
        _ = windows
        for m in s.members { try require(!m.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "A member needs a name.") }
        for p in s.pets { try require(!p.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !p.species.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "A pet needs a name and species.") }
        for r in s.routines {
            try require(pets.contains(r.petId) && (r.defaultAssigneeId == nil || members.contains(r.defaultAssigneeId!)), "A routine references a missing pet or member.")
            try require(!r.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "A routine needs a name.")
        }
        for w in s.scheduleWindows {
            try require(routines.contains(w.routineId), "A schedule references a missing routine.")
            let rawDays = w.daysOfWeek.split(separator: ",", omittingEmptySubsequences: false)
            try require(!w.weekdays.isEmpty && rawDays.allSatisfy { Int($0.trimmingCharacters(in: .whitespaces)).map { (1...7).contains($0) } ?? false }, "Invalid weekdays.")
            try require((0...23).contains(w.startHour) && (0...23).contains(w.endHour) && (0...59).contains(w.startMinute) && (0...59).contains(w.endMinute), "Invalid schedule time.")
        }
        var eventIDs = Set<UUID>(), keys = Set<String>(), instants = Set<String>()
        for e in s.completionEvents {
            try require(routines.contains(e.routineId) && (e.completedByMemberId == nil || members.contains(e.completedByMemberId!)), "History references a missing routine or member.")
            try require(["done", "skipped"].contains(e.kind) && eventIDs.insert(e.id).inserted, "Invalid or duplicate history event.")
            if e.kind == "done" {
                try require(instants.insert("\(e.routineId)@\(e.completedAtUtc.timeIntervalSince1970)").inserted, "Duplicate completion instant.")
                if let key = e.instanceKey {
                    let parts = key.split(separator: "@")
                    let window = parts.first.flatMap { Int($0) }.flatMap { id in s.scheduleWindows.first { $0.id == id } }
                    let dateParts = parts.count == 2 ? parts[1].split(separator: "-").compactMap { Int($0) } : []
                    var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(secondsFromGMT: 0)!
                    let date = dateParts.count == 3 ? cal.date(from: DateComponents(year: dateParts[0], month: dateParts[1], day: dateParts[2])) : nil
                    let instance = window.flatMap { w in date.flatMap { Scheduling.occurrence(w, on: $0, calendar: cal) } }
                    try require(window?.routineId == e.routineId && instance?.id == key && keys.insert(key).inserted, "Invalid or duplicate completion occurrence.")
                }
            }
        }
        if let r = s.reminderSettings {
            try require(r.schemaVersion == 1 && [0, 5, 15, 30].contains(r.leadTimeMinutes) && (0..<1440).contains(r.quietHours.startMinutes) && (0..<1440).contains(r.quietHours.endMinutes), "Invalid reminder settings.")
        }
        if let r = s.retentionSettings { try require(r.schemaVersion == 1, "Unsupported retention settings.") }
    }
    public static func csv(_ snapshot: Snapshot, from: Date, to: Date) -> String {
        func cell(_ value: String) -> String {
            // Prevent formulas when household-entered text is opened in a spreadsheet.
            let dangerous = value.first.map { "=+-@\t\r\n".contains($0) } ?? false
            let safe = dangerous ? "'" + value : value
            return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        let formatter = ISO8601DateFormatter()
        var rows = ["completed_at_utc,pet,routine,kind,member,note"]
        for e in snapshot.completionEvents.filter({ $0.completedAtUtc >= from && $0.completedAtUtc < to }).sorted(by: { $0.completedAtUtc < $1.completedAtUtc }) {
            let routine = snapshot.routines.first { $0.id == e.routineId }
            let pet = snapshot.pets.first { $0.id == routine?.petId }
            let member = snapshot.members.first { $0.id == e.completedByMemberId }
            rows.append([formatter.string(from: e.completedAtUtc), pet?.name ?? "", routine?.name ?? "", e.kind, member?.displayName ?? "", e.note ?? ""].map(cell).joined(separator: ","))
        }
        return rows.joined(separator: "\r\n") + "\r\n"
    }
}

/// Single-file, atomic local persistence. Failed writes never publish new UI state.
public struct LocalStore {
    public let url: URL
    public init(url: URL) { self.url = url }
    public func load() throws -> Snapshot {
        guard FileManager.default.fileExists(atPath: url.path) else { return Snapshot() }
        return try Backup.decode(Data(contentsOf: url))
    }
    public func save(_ snapshot: Snapshot) throws {
        try Backup.validate(snapshot)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try Backup.encode(snapshot)
        #if os(iOS)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try data.write(to: url, options: .atomic)
        #endif
    }
}
