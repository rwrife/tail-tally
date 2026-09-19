import XCTest
@testable import TailTallyCore

final class CoreTests: XCTestCase {
    var calendar: Calendar {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "America/Los_Angeles")!; return c
    }
    func date(_ year: Int = 2026, _ month: Int = 9, _ day: Int = 19, _ hour: Int = 9, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
    func fixture() -> Snapshot {
        var s = Snapshot()
        s.members = [Member(id: 1, displayName: "Alex", isLocalDeviceOwner: true)]
        s.pets = [Pet(id: 1, name: "Biscuit", species: "Dog")]
        s.routines = [Routine(id: 1, petId: 1, name: "Breakfast", defaultAssigneeId: 1)]
        s.scheduleWindows = [ScheduleWindow(id: 1, routineId: 1, startHour: 9, startMinute: 0, endHour: 10, endMinute: 0, days: Set(1...7))]
        return s
    }
    func testStatusBoundariesAndDuplicateGuard() throws {
        var s = fixture(); let item = Scheduling.occurrence(s.scheduleWindows[0], on: date(), calendar: calendar)!
        XCTAssertEqual(item.status(now: item.start.addingTimeInterval(-1), completion: nil), .scheduled)
        XCTAssertEqual(item.status(now: item.start, completion: nil), .due)
        XCTAssertEqual(item.status(now: item.end, completion: nil), .due)
        XCTAssertEqual(item.status(now: item.end.addingTimeInterval(1), completion: nil), .overdue)
        let first = Scheduling.complete(item, snapshot: &s, now: date(), memberId: 1, note: "Fed", calendar: calendar)
        let second = Scheduling.complete(item, snapshot: &s, now: date().addingTimeInterval(3), memberId: 1, note: nil, calendar: calendar)
        XCTAssertEqual(first.id, second.id); XCTAssertEqual(s.completionEvents.count, 1)
        XCTAssertEqual(item.status(now: date(), completion: first), .completed)
    }
    func testOvernightAndDSTUseCalendarDays() {
        let w = ScheduleWindow(id: 1, routineId: 1, startHour: 22, startMinute: 0, endHour: 6, endMinute: 0, days: Set(1...7))
        let spring = Scheduling.occurrence(w, on: date(2026, 3, 7), calendar: calendar)!
        XCTAssertEqual(calendar.component(.hour, from: spring.end), 6)
        XCTAssertEqual(spring.end.timeIntervalSince(spring.start), 7 * 3600)
        let autumn = Scheduling.occurrence(w, on: date(2026, 10, 31), calendar: calendar)!
        XCTAssertEqual(autumn.end.timeIntervalSince(autumn.start), 9 * 3600)
        XCTAssertEqual(Scheduling.active([w], on: date(2026, 3, 8), calendar: calendar).count, 2)
    }
    func testOccurrenceIdentitySurvivesTimezoneTravel() {
        var s = fixture(); let item = Scheduling.occurrence(s.scheduleWindows[0], on: date(), calendar: calendar)!
        Scheduling.complete(item, snapshot: &s, now: date(), memberId: nil, note: nil, calendar: calendar)
        var tokyo = calendar; tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let localDay = tokyo.date(from: DateComponents(year: 2026, month: 9, day: 19))!
        let travelled = Scheduling.occurrence(s.scheduleWindows[0], on: localDay, calendar: tokyo)!
        XCTAssertNotNil(Scheduling.completion(for: travelled, in: s.completionEvents, calendar: tokyo))
    }
    func testSeparateWindowsDoNotShareNativeCompletion() {
        var s = fixture()
        let other = ScheduleWindow(id: 2, routineId: 1, startHour: 18, startMinute: 0, endHour: 19, endMinute: 0, days: Set(1...7))
        s.scheduleWindows.append(other)
        let morning = Scheduling.occurrence(s.scheduleWindows[0], on: date(), calendar: calendar)!
        Scheduling.complete(morning, snapshot: &s, now: date(), memberId: nil, note: nil, calendar: calendar)
        XCTAssertNil(Scheduling.completion(for: Scheduling.occurrence(other, on: date(), calendar: calendar)!, in: s.completionEvents, calendar: calendar))
    }
    func testBackupRoundTripAndFailedRestorePreserveDisk() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LocalStore(url: root.appendingPathComponent("data.json"))
        var s = fixture()
        let item = Scheduling.occurrence(s.scheduleWindows[0], on: date(), calendar: calendar)!
        Scheduling.complete(item, snapshot: &s, now: date(), memberId: 1, note: "hello", calendar: calendar)
        try store.save(s)
        XCTAssertEqual(try store.load().completionEvents, s.completionEvents)
        var invalid = s; invalid.routines[0].petId = 99
        XCTAssertThrowsError(try store.save(invalid))
        XCTAssertEqual(try store.load().pets, s.pets)
        try store.save(Snapshot()); XCTAssertTrue(try store.load().pets.isEmpty)
    }
    func testLegacyFlutterBackupWithFractionalUTCDate() throws {
        let raw = """
        {"manifest":{"backupVersion":1,"appSchemaVersion":4,"createdAtUtc":"2026-09-19T16:00:00.000Z"},"members":[],"pets":[{"id":1,"name":"Mochi","species":"cat"}],"routines":[{"id":1,"petId":1,"name":"Feed"}],"scheduleWindows":[{"id":1,"routineId":1,"startHour":9,"startMinute":0,"endHour":10,"endMinute":0,"daysOfWeek":"1,2,3,4,5,6,7","crossesMidnight":false}],"completionEvents":[{"routineId":1,"completedAtUtc":"2026-09-19T09:00:00.123-07:00","kind":"done"}],"retentionSettings":{"schemaVersion":1,"preference":"keep90Days"}}
        """
        let s = try Backup.decode(Data(raw.utf8))
        XCTAssertEqual(s.pets[0].name, "Mochi")
        XCTAssertEqual(s.retentionSettings?.preference, .keep90Days)
        let item = Scheduling.occurrence(s.scheduleWindows[0], on: date(), calendar: calendar)!
        XCTAssertNotNil(Scheduling.completion(for: item, in: s.completionEvents, calendar: calendar))
    }
    func testRejectsInvalidAndFutureBackups() throws {
        var s = fixture(); s.manifest.backupVersion = 99
        XCTAssertThrowsError(try Backup.decode(Backup.encode(s)))
        s = fixture(); s.members.append(s.members[0]); XCTAssertThrowsError(try Backup.validate(s))
        s = fixture(); s.scheduleWindows[0].daysOfWeek = "1,nonsense"; XCTAssertThrowsError(try Backup.validate(s))
        s = fixture(); s.scheduleWindows[0].startHour = 25; XCTAssertThrowsError(try Backup.validate(s))
        s = fixture(); s.completionEvents = [Completion(routineId: 1, completedAtUtc: date(), instanceKey: "99@2026-9-19")]
        XCTAssertThrowsError(try Backup.validate(s))
    }
    func testReminderOptInQuietHoursAndCompletionCancellation() {
        var s = fixture(); let now = date(2026, 9, 19, 8)
        XCTAssertTrue(ReminderPlanner.plan(s, now: now, calendar: calendar).isEmpty)
        var settings = ReminderSettings(); settings.notificationsEnabled = true; s.reminderSettings = settings
        let before = ReminderPlanner.plan(s, now: now, calendar: calendar)
        XCTAssertEqual(before.first?.fireAt, date(2026, 9, 19, 8, 55))
        let item = Scheduling.occurrence(s.scheduleWindows[0], on: now, calendar: calendar)!
        Scheduling.complete(item, snapshot: &s, now: now, memberId: 1, note: nil, calendar: calendar)
        XCTAssertFalse(ReminderPlanner.plan(s, now: now, calendar: calendar).contains { $0.id == item.id })
        s.reminderSettings?.quietHours = QuietHours(startMinutes: 22 * 60, endMinutes: 9 * 60)
        XCTAssertTrue(ReminderPlanner.plan(s, now: now, calendar: calendar).isEmpty)
    }
    func testCSVAndRetentionBoundaries() {
        var s = fixture(); let now = date()
        s.completionEvents = [Completion(routineId: 1, completedAtUtc: now, note: "=SUM(1,2)\n\"note\""), Completion(routineId: 1, completedAtUtc: now.addingTimeInterval(-90 * 86400)), Completion(routineId: 1, completedAtUtc: now.addingTimeInterval(-90 * 86400 - 1))]
        var retention = RetentionSettings(); retention.preference = .keep90Days; s.retentionSettings = retention
        s.prune(now: now); XCTAssertEqual(s.completionEvents.count, 2)
        let csv = Backup.csv(s, from: now, to: now.addingTimeInterval(1))
        XCTAssertTrue(csv.contains("'=SUM(1,2)\n\"\"note\"\""))
        XCTAssertEqual(Backup.csv(s, from: now.addingTimeInterval(-1), to: now).components(separatedBy: "\r\n").count, 2)
    }
}
