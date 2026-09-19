import Foundation

public struct Member: Codable, Identifiable, Equatable {
    public var id: Int
    public var displayName: String
    public var isLocalDeviceOwner: Bool = false
    public init(id: Int, displayName: String, isLocalDeviceOwner: Bool = false) {
        self.id = id; self.displayName = displayName; self.isLocalDeviceOwner = isLocalDeviceOwner
    }
}

public struct Pet: Codable, Identifiable, Equatable {
    public var id: Int
    public var name: String
    public var species: String
    public var photoRef: String?
    public init(id: Int, name: String, species: String, photoRef: String? = nil) {
        self.id = id; self.name = name; self.species = species; self.photoRef = photoRef
    }
}

public struct Routine: Codable, Identifiable, Equatable {
    public var id: Int
    public var petId: Int
    public var name: String
    public var defaultAssigneeId: Int?
    public init(id: Int, petId: Int, name: String, defaultAssigneeId: Int? = nil) {
        self.id = id; self.petId = petId; self.name = name; self.defaultAssigneeId = defaultAssigneeId
    }
}

public struct ScheduleWindow: Codable, Identifiable, Equatable {
    public var id: Int
    public var routineId: Int
    public var startHour: Int
    public var startMinute: Int
    public var endHour: Int
    public var endMinute: Int
    // Preserve the original Flutter v1 backup representation.
    public var daysOfWeek: String
    public var crossesMidnight: Bool
    public var weekdays: Set<Int> { Set(daysOfWeek.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }) }
    public init(id: Int, routineId: Int, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, days: Set<Int>) {
        self.id = id; self.routineId = routineId; self.startHour = startHour; self.startMinute = startMinute
        self.endHour = endHour; self.endMinute = endMinute
        daysOfWeek = days.sorted().map(String.init).joined(separator: ",")
        crossesMidnight = endHour * 60 + endMinute <= startHour * 60 + startMinute
    }
}

public struct Completion: Codable, Identifiable, Equatable {
    public var id: UUID
    public var routineId: Int
    public var completedAtUtc: Date
    public var kind: String
    public var completedByMemberId: Int?
    public var note: String?
    public var instanceKey: String?
    public init(routineId: Int, completedAtUtc: Date, kind: String = "done", completedByMemberId: Int? = nil, note: String? = nil, instanceKey: String? = nil) {
        id = UUID(); self.routineId = routineId; self.completedAtUtc = completedAtUtc; self.kind = kind
        self.completedByMemberId = completedByMemberId; self.note = note; self.instanceKey = instanceKey
    }
    enum CodingKeys: String, CodingKey { case id, routineId, completedAtUtc, kind, completedByMemberId, note, instanceKey }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        routineId = try c.decode(Int.self, forKey: .routineId)
        completedAtUtc = try c.decode(Date.self, forKey: .completedAtUtc)
        kind = try c.decode(String.self, forKey: .kind)
        completedByMemberId = try c.decodeIfPresent(Int.self, forKey: .completedByMemberId)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        instanceKey = try c.decodeIfPresent(String.self, forKey: .instanceKey)
    }
}

public struct QuietHours: Codable, Equatable {
    public var startMinutes = 0
    public var endMinutes = 0
    public init(startMinutes: Int = 0, endMinutes: Int = 0) { self.startMinutes = startMinutes; self.endMinutes = endMinutes }
    public func contains(_ date: Date, calendar: Calendar) -> Bool {
        let minute = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        if startMinutes == endMinutes { return false }
        return startMinutes < endMinutes ? (startMinutes..<endMinutes).contains(minute) : minute >= startMinutes || minute < endMinutes
    }
}

public struct ReminderSettings: Codable, Equatable {
    public var schemaVersion = 1
    public var notificationsEnabled = false
    public var leadTimeMinutes = 5
    public var quietHours = QuietHours()
    public init() {}
}

public enum Retention: String, Codable, CaseIterable {
    case keepAll, keep90Days, keep180Days, keep365Days
    public var days: Int? {
        switch self { case .keepAll: return nil; case .keep90Days: return 90; case .keep180Days: return 180; case .keep365Days: return 365 }
    }
    public var label: String { days.map { "Keep last \($0) days" } ?? "Keep all history" }
}
public struct RetentionSettings: Codable, Equatable {
    public var schemaVersion = 1
    public var preference: Retention = .keepAll
    public init() {}
}
public struct Manifest: Codable, Equatable {
    public var backupVersion = 1
    public var appSchemaVersion = 4
    public var createdAtUtc = Date()
    public var deviceLabel: String? = "iPhone"
    public init() {}
}
public struct Snapshot: Codable, Equatable {
    public var manifest = Manifest()
    public var members: [Member] = []
    public var pets: [Pet] = []
    public var routines: [Routine] = []
    public var scheduleWindows: [ScheduleWindow] = []
    public var completionEvents: [Completion] = []
    public var reminderSettings: ReminderSettings?
    public var retentionSettings: RetentionSettings?
    public init() {}
    public mutating func prune(now: Date) {
        guard let days = retentionSettings?.preference.days else { return }
        let cutoff = now.addingTimeInterval(-Double(days) * 86400)
        completionEvents.removeAll { $0.completedAtUtc < cutoff }
    }
}
public enum TallyError: LocalizedError {
    case invalid(String)
    public var errorDescription: String? { if case .invalid(let message) = self { return message }; return nil }
}
