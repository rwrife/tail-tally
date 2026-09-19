import Foundation

public enum TaskStatus: String, CaseIterable { case overdue = "Overdue", due = "Due now", scheduled = "Coming up", completed = "Done today" }
public struct Occurrence: Identifiable, Equatable {
    public var window: ScheduleWindow
    public var start: Date
    public var end: Date
    public var id: String
    public func status(now: Date, completion: Completion?) -> TaskStatus {
        if completion != nil { return .completed }
        return now > end ? .overdue : now >= start ? .due : .scheduled
    }
}
public enum Scheduling {
    public static func occurrence(_ window: ScheduleWindow, on day: Date, calendar: Calendar = .current) -> Occurrence? {
        let weekday = (calendar.component(.weekday, from: day) + 5) % 7 + 1
        guard window.weekdays.contains(weekday),
              let start = calendar.date(bySettingHour: window.startHour, minute: window.startMinute, second: 0, of: day),
              let sameDayEnd = calendar.date(bySettingHour: window.endHour, minute: window.endMinute, second: 0, of: day) else { return nil }
        let wraps = window.endHour * 60 + window.endMinute <= window.startHour * 60 + window.startMinute
        let endDay = wraps ? calendar.date(byAdding: .day, value: 1, to: day)! : day
        let end = wraps ? calendar.date(bySettingHour: window.endHour, minute: window.endMinute, second: 0, of: endDay)! : sameDayEnd
        let d = calendar.dateComponents([.year, .month, .day], from: day)
        return Occurrence(window: window, start: start, end: end, id: "\(window.id)@\(d.year!)-\(d.month!)-\(d.day!)")
    }
    public static func active(_ windows: [ScheduleWindow], on day: Date, calendar: Calendar = .current) -> [Occurrence] {
        let midnight = calendar.startOfDay(for: day)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: day)!
        return windows.flatMap { window -> [Occurrence] in
            var result: [Occurrence] = []
            if let prior = occurrence(window, on: yesterday, calendar: calendar), prior.end > midnight { result.append(prior) }
            if let today = occurrence(window, on: day, calendar: calendar) { result.append(today) }
            return result
        }.sorted { $0.start < $1.start }
    }
    public static func completion(for occurrence: Occurrence, in events: [Completion], calendar: Calendar = .current) -> Completion? {
        var lower: Date?
        var upper: Date?
        for offset in 1...8 {
            if lower == nil, let day = calendar.date(byAdding: .day, value: -offset, to: occurrence.start),
               let prior = self.occurrence(occurrence.window, on: day, calendar: calendar), prior.end < occurrence.start { lower = prior.end }
            if upper == nil, let day = calendar.date(byAdding: .day, value: offset, to: occurrence.start),
               let next = self.occurrence(occurrence.window, on: day, calendar: calendar) { upper = next.start }
        }
        return events.filter { event in
            guard event.kind == "done", event.routineId == occurrence.window.routineId else { return false }
            if let key = event.instanceKey { return key == occurrence.id }
            return (lower == nil || event.completedAtUtc > lower!) && (upper == nil || event.completedAtUtc < upper!)
        }.max { $0.completedAtUtc < $1.completedAtUtc }
    }
    @discardableResult
    public static func complete(_ occurrence: Occurrence, snapshot: inout Snapshot, now: Date, memberId: Int?, note: String?, calendar: Calendar = .current) -> Completion {
        if let existing = completion(for: occurrence, in: snapshot.completionEvents, calendar: calendar) { return existing }
        let event = Completion(routineId: occurrence.window.routineId, completedAtUtc: now, completedByMemberId: memberId, note: note, instanceKey: occurrence.id)
        snapshot.completionEvents.append(event)
        return event
    }
}
public struct PlannedReminder {
    public let id: String
    public let title: String
    public let fireAt: Date
}
public enum ReminderPlanner {
    public static func plan(_ snapshot: Snapshot, now: Date, calendar: Calendar = .current) -> [PlannedReminder] {
        let settings = snapshot.reminderSettings ?? ReminderSettings()
        guard settings.notificationsEnabled else { return [] }
        var result: [PlannedReminder] = []
        for offset in 0...7 {
            let day = calendar.date(byAdding: .day, value: offset, to: now)!
            for window in snapshot.scheduleWindows {
                guard let item = Scheduling.occurrence(window, on: day, calendar: calendar),
                      Scheduling.completion(for: item, in: snapshot.completionEvents, calendar: calendar) == nil,
                      let routine = snapshot.routines.first(where: { $0.id == window.routineId }),
                      let pet = snapshot.pets.first(where: { $0.id == routine.petId }) else { continue }
                let fire = item.start.addingTimeInterval(-Double(settings.leadTimeMinutes) * 60)
                guard fire > now, !settings.quietHours.contains(fire, calendar: calendar) else { continue }
                result.append(PlannedReminder(id: item.id, title: "\(pet.name) — \(routine.name)", fireAt: fire))
            }
        }
        return Array(result.sorted { $0.fireAt < $1.fireAt }.prefix(60))
    }
}
