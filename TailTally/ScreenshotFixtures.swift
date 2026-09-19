#if DEBUG
import Foundation
import TailTallyCore

enum ScreenshotFixtures {
    static var enabled: Bool { ProcessInfo.processInfo.arguments.contains("--screenshots") }
    static var now: Date { Calendar.current.date(bySettingHour: 9, minute: 41, second: 0, of: Date())! }
    static func household() -> Snapshot {
        var s = Snapshot()
        s.members = [Member(id: 1, displayName: "Alex", isLocalDeviceOwner: true), Member(id: 2, displayName: "Sam")]
        s.pets = [Pet(id: 1, name: "Biscuit", species: "Golden retriever"), Pet(id: 2, name: "Mochi", species: "Domestic shorthair")]
        s.routines = [Routine(id: 1, petId: 1, name: "Morning walk", defaultAssigneeId: 1), Routine(id: 2, petId: 2, name: "Fresh water", defaultAssigneeId: 2), Routine(id: 3, petId: 1, name: "Breakfast", defaultAssigneeId: 1), Routine(id: 4, petId: 2, name: "Litter scoop", defaultAssigneeId: 2), Routine(id: 5, petId: 1, name: "Evening walk", defaultAssigneeId: 2)]
        s.scheduleWindows = [
            ScheduleWindow(id: 1, routineId: 1, startHour: 9, startMinute: 0, endHour: 10, endMinute: 0, days: Set(1...7)),
            ScheduleWindow(id: 2, routineId: 2, startHour: 9, startMinute: 30, endHour: 10, endMinute: 30, days: Set(1...7)),
            ScheduleWindow(id: 3, routineId: 3, startHour: 7, startMinute: 0, endHour: 8, endMinute: 0, days: Set(1...7)),
            ScheduleWindow(id: 4, routineId: 4, startHour: 12, startMinute: 0, endHour: 13, endMinute: 0, days: Set(1...7)),
            ScheduleWindow(id: 5, routineId: 5, startHour: 17, startMinute: 0, endHour: 18, endMinute: 0, days: Set(1...7))
        ]
        let breakfast = Scheduling.occurrence(s.scheduleWindows[2], on: now)!
        Scheduling.complete(breakfast, snapshot: &s, now: Calendar.current.date(bySettingHour: 7, minute: 25, second: 0, of: now)!, memberId: 1, note: "Breakfast served. Fresh water, too.")
        for offset in 1...3 {
            let day = Calendar.current.date(byAdding: .day, value: -offset, to: now)!
            for (index, note) in [(0, "A happy loop around the park."), (2, "Clean bowl club."), (3, "Scooped and topped up.")] {
                let item = Scheduling.occurrence(s.scheduleWindows[index], on: day)!
                Scheduling.complete(item, snapshot: &s, now: item.start.addingTimeInterval(1200), memberId: index == 3 ? 2 : 1, note: note)
            }
        }
        return s
    }
}
#endif
