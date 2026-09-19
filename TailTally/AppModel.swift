import SwiftUI
import UserNotifications
import TailTallyCore

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var snapshot = Snapshot()
    @Published var message: String?
    @Published private(set) var loadFailed = false
    @Published private(set) var undoIDs: [UUID] = []
    var now: Date {
        #if DEBUG
        if ScreenshotFixtures.enabled { return ScreenshotFixtures.now }
        #endif
        return Date()
    }
    private let store: LocalStore
    private var notificationTask: Task<Void, Never>?

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        #if DEBUG
        if ScreenshotFixtures.enabled {
            store = LocalStore(url: directory.appendingPathComponent("TailTallyScreenshots/household.json"))
            snapshot = ScreenshotFixtures.household()
            return
        }
        #endif
        store = LocalStore(url: directory.appendingPathComponent("TailTally/household.json"))
        do { snapshot = try store.load() }
        catch { loadFailed = true; message = "Could not open local data. Existing data has been preserved. \(error.localizedDescription)" }
    }
    @discardableResult
    func change(_ action: (inout Snapshot) throws -> Void) -> Bool {
        guard !loadFailed else { message = "Restore a valid backup or retry opening your data before making changes."; return false }
        do {
            var next = snapshot
            try action(&next)
            try store.save(next)
            snapshot = next
            refreshReminders()
            return true
        } catch { message = error.localizedDescription; return false }
    }
    func restore(_ next: Snapshot) {
        do {
            try store.save(next)
            snapshot = next; loadFailed = false; undoIDs = []
            refreshReminders(); message = "Backup restored."
        } catch { message = error.localizedDescription }
    }
    func retryLoad() {
        do { snapshot = try store.load(); loadFailed = false; refresh() }
        catch { message = error.localizedDescription }
    }
    func refresh() {
        guard !loadFailed else { return }
        var next = snapshot; next.prune(now: Date())
        if next != snapshot { _ = change { $0 = next } } else { refreshReminders() }
    }
    func complete(_ item: Occurrence, member: Int?, note: String?) {
        var id: UUID?
        let succeeded = change { data in
            guard Scheduling.completion(for: item, in: data.completionEvents) == nil else { return }
            id = Scheduling.complete(item, snapshot: &data, now: now, memberId: member, note: note).id
        }
        if succeeded, let id { undoIDs.insert(id, at: 0); undoIDs = Array(undoIDs.prefix(3)) }
    }
    func undo(_ id: UUID) {
        guard undoIDs.contains(id) else { return }
        if change({ $0.completionEvents.removeAll { $0.id == id } }) { undoIDs.removeAll { $0 == id } }
    }
    func deleteAll() {
        do {
            try store.save(Snapshot())
            let verified = try store.load()
            guard verified.pets.isEmpty && verified.members.isEmpty && verified.routines.isEmpty && verified.scheduleWindows.isEmpty && verified.completionEvents.isEmpty && verified.reminderSettings == nil && verified.retentionSettings == nil else {
                throw TallyError.invalid("Could not verify deletion.")
            }
            snapshot = verified; loadFailed = false; undoIDs = []
            refreshReminders(); message = "All local data deleted and verified empty."
        } catch { message = error.localizedDescription }
    }
    func enableReminders(_ enabled: Bool) async {
        do {
            if enabled {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                guard granted else { message = "Notifications are disabled. You can allow them in iPhone Settings; all other features still work."; return }
            }
            change { data in
                var settings = data.reminderSettings ?? ReminderSettings()
                settings.notificationsEnabled = enabled; data.reminderSettings = settings
            }
        } catch { message = error.localizedDescription }
    }
    func refreshReminders() {
        notificationTask?.cancel()
        let previous = notificationTask
        let data = snapshot
        notificationTask = Task {
            // Serialize replacements so an older refresh cannot leave stale requests behind.
            await previous?.value
            guard !Task.isCancelled else { return }
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
            center.removeAllDeliveredNotifications()
            let permission = await center.notificationSettings()
            guard !Task.isCancelled, [.authorized, .provisional, .ephemeral].contains(permission.authorizationStatus) else { return }
            for reminder in ReminderPlanner.plan(data, now: Date()) {
                guard !Task.isCancelled else { return }
                let content = UNMutableNotificationContent()
                content.title = reminder.title; content.body = "Your pet-care routine is coming up."; content.sound = .default
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireAt)
                let request = UNNotificationRequest(identifier: reminder.id, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
                do { try await center.add(request) }
                catch { if !Task.isCancelled { message = "Could not schedule reminders: \(error.localizedDescription)" }; return }
            }
        }
    }
}
