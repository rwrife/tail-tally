import SwiftUI
import UniformTypeIdentifiers
import TailTallyCore

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .commaSeparatedText] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var document = ExportDocument(data: Data())
    @State private var exporting = false
    @State private var importing = false
    @State private var fileType: UTType = .json
    @State private var pendingImport: Snapshot?
    @State private var confirmImport = false
    @State private var confirmDelete = false
    @State private var pendingRetention: Retention?
    @State private var permissionBusy = false
    @State private var from = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @State private var to = Date()
    private var reminders: ReminderSettings { model.snapshot.reminderSettings ?? ReminderSettings() }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Routine reminders", isOn: Binding(get: { reminders.notificationsEnabled }, set: { enabled in
                        permissionBusy = true
                        Task { await model.enableReminders(enabled); permissionBusy = false }
                    })).disabled(permissionBusy || model.loadFailed)
                    Picker("Remind me", selection: Binding(get: { reminders.leadTimeMinutes }, set: { value in updateReminders { $0.leadTimeMinutes = value } })) {
                        Text("At window start").tag(0)
                        ForEach([5, 15, 30], id: \.self) { Text("\($0) minutes before").tag($0) }
                    }
                    DatePicker("Quiet hours start", selection: quietBinding(start: true), displayedComponents: .hourAndMinute)
                    DatePicker("Quiet hours end", selection: quietBinding(start: false), displayedComponents: .hourAndMinute)
                    if reminders.quietHours.startMinutes != reminders.quietHours.endMinutes {
                        Button("Turn quiet hours off") { updateReminders { $0.quietHours = QuietHours() } }
                    }
                    Button("Open iPhone notification settings") {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) { UIApplication.shared.open(url) }
                    }
                } header: { Text("Reminders") } footer: {
                    Text("Optional, on-device reminders are planned for the next 7 days, up to 60 upcoming routines. Open Tail Tally regularly to refresh them. Reminders during quiet hours are skipped; equal start and end times turn quiet hours off.")
                }
                Section("Privacy & data") {
                    Text("Your household stays on this iPhone. No account, cloud sync, ads, or analytics.")
                    Button("Export backup (JSON)", systemImage: "square.and.arrow.up") {
                        do {
                            var snapshot = model.snapshot; snapshot.manifest.createdAtUtc = Date()
                            document = ExportDocument(data: try Backup.encode(snapshot)); fileType = .json; exporting = true
                        } catch { model.message = error.localizedDescription }
                    }.disabled(model.loadFailed)
                    Button("Restore from backup", systemImage: "square.and.arrow.down") { importing = true }
                    DatePicker("History from", selection: $from, in: ...to, displayedComponents: .date)
                    DatePicker("History through", selection: $to, in: from..., displayedComponents: .date)
                    Button("Export history (CSV)") {
                        let first = Calendar.current.startOfDay(for: from)
                        let last = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: to))!
                        document = ExportDocument(data: Data(Backup.csv(model.snapshot, from: first, to: last).utf8))
                        fileType = .commaSeparatedText; exporting = true
                    }.disabled(model.loadFailed)
                    Picker("History retention", selection: Binding(get: { model.snapshot.retentionSettings?.preference ?? .keepAll }, set: { pendingRetention = $0 })) {
                        ForEach(Retention.allCases, id: \.self) { Text($0.label).tag($0) }
                    }.disabled(model.loadFailed)
                    Button("Delete all data on this iPhone", role: .destructive) { confirmDelete = true }
                }
                Section("About Tail Tally") {
                    Text("A little care, every day.").font(.headline)
                    Text("Tail Tally organizes pet-care routines. It does not provide veterinary advice, diagnosis, treatment, or emergency monitoring.").font(.footnote).foregroundStyle(.secondary)
                    Text("Version 1.0 · Made for iPhone").font(.caption).foregroundStyle(.secondary)
                }
            }.navigationTitle("Settings")
                .fileExporter(isPresented: $exporting, document: document, contentType: fileType, defaultFilename: fileType == .json ? "TailTally-backup" : "TailTally-history") { result in
                    switch result { case .success: model.message = "File exported."; case .failure(let error): model.message = error.localizedDescription }
                }
                .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                    do {
                        let url = try result.get()
                        let scoped = url.startAccessingSecurityScopedResource()
                        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                        pendingImport = try Backup.decode(Data(contentsOf: url)); confirmImport = true
                    } catch { model.message = "Import failed. Your current data is unchanged. \(error.localizedDescription)" }
                }
                .confirmationDialog("Replace all local data with this backup?", isPresented: $confirmImport, titleVisibility: .visible) {
                    Button("Replace data", role: .destructive) { if let pendingImport { model.restore(pendingImport) }; pendingImport = nil }
                    Button("Cancel", role: .cancel) { pendingImport = nil }
                } message: { Text("This replaces pets, routines, schedules, history, and settings. Export a backup first if you want to keep the current household.") }
                .confirmationDialog("Delete all Tail Tally data?", isPresented: $confirmDelete, titleVisibility: .visible) {
                    Button("Delete everything", role: .destructive) { model.deleteAll() }
                } message: { Text("This removes all local pets, routines, history, members, and settings. Only an exported backup can restore them.") }
                .confirmationDialog("Apply history retention?", isPresented: Binding(get: { pendingRetention != nil }, set: { if !$0 { pendingRetention = nil } }), titleVisibility: .visible) {
                    Button("Apply retention", role: pendingRetention == .keepAll ? nil : .destructive) {
                        if let pendingRetention {
                            model.change { data in
                                var settings = RetentionSettings(); settings.preference = pendingRetention
                                data.retentionSettings = settings; data.prune(now: Date())
                            }
                        }; pendingRetention = nil
                    }
                } message: { Text("History older than the selected period will be permanently removed. Export a backup first to keep it.") }
        }
    }
    private func updateReminders(_ action: (inout ReminderSettings) -> Void) {
        model.change { data in var value = reminders; action(&value); data.reminderSettings = value }
    }
    private func quietBinding(start: Bool) -> Binding<Date> {
        Binding(get: {
            let minutes = start ? reminders.quietHours.startMinutes : reminders.quietHours.endMinutes
            return Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date())!
        }, set: { value in
            let minutes = Calendar.current.component(.hour, from: value) * 60 + Calendar.current.component(.minute, from: value)
            updateReminders { if start { $0.quietHours.startMinutes = minutes } else { $0.quietHours.endMinutes = minutes } }
        })
    }
}
