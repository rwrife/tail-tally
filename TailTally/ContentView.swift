import SwiftUI
import TailTallyCore

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @State private var tab: Int = {
        #if DEBUG
        if let arg = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--tab=") }) { return Int(arg.dropFirst(6)) ?? 0 }
        #endif
        return 0
    }()
    var body: some View {
        TabView(selection: $tab) {
            TodayView().tabItem { Label("Today", systemImage: "checklist") }.tag(0)
            HouseholdView().tabItem { Label("Household", systemImage: "pawprint") }.tag(1)
            HistoryView().tabItem { Label("History", systemImage: "clock") }.tag(2)
            SettingsView().tabItem { Label("Settings", systemImage: "gearshape") }.tag(3)
        }
    }
}

struct TodayView: View {
    @EnvironmentObject private var model: AppModel
    @State private var petID: Int?
    @State private var selected: Occurrence?
    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                let entries = Scheduling.active(model.snapshot.scheduleWindows, on: model.now).filter { item in
                    petID == nil || model.snapshot.routines.first { $0.id == item.window.routineId }?.petId == petID
                }
                List {
                    if model.loadFailed {
                        Section {
                            Text("Your saved data could not be opened. It has not been overwritten.")
                            Button("Retry opening data") { model.retryLoad() }
                        }
                    } else if model.snapshot.pets.isEmpty {
                        ContentUnavailableView("Welcome to Tail Tally", systemImage: "pawprint", description: Text("Add your first pet and a routine in Household to start your daily timeline."))
                    } else {
                        Picker("Pet", selection: $petID) {
                            Text("All pets").tag(nil as Int?)
                            ForEach(model.snapshot.pets) { Text($0.name).tag(Optional($0.id)) }
                        }
                        if entries.isEmpty {
                            ContentUnavailableView("Nothing scheduled today", systemImage: "calendar", description: Text("Enjoy some time together. Manage your pet’s routines in Household."))
                        }
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            let group = entries.filter { $0.status(now: model.now, completion: Scheduling.completion(for: $0, in: model.snapshot.completionEvents)) == status }
                            if !group.isEmpty {
                                Section(status.rawValue) {
                                    ForEach(group) { item in
                                        row(item, status: status)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Today")
            .sheet(item: $selected) { CompletionSheet(item: $0) }
            .onChange(of: model.snapshot.pets) { _, pets in if !pets.contains(where: { $0.id == petID }) { petID = nil } }
        }
    }
    @ViewBuilder
    private func row(_ item: Occurrence, status: TaskStatus) -> some View {
        let routine = model.snapshot.routines.first { $0.id == item.window.routineId }
        let pet = model.snapshot.pets.first { $0.id == routine?.petId }
        let completion = Scheduling.completion(for: item, in: model.snapshot.completionEvents)
        VStack(alignment: .leading, spacing: 8) {
            Label("\(pet?.name ?? "Pet") · \(routine?.name ?? "Routine")", systemImage: completion == nil ? "pawprint" : "checkmark.circle.fill")
                .font(.headline)
            Text("\(item.start.formatted(date: .omitted, time: .shortened)) – \(item.end.formatted(date: .omitted, time: .shortened))\(Calendar.current.isDate(item.start, inSameDayAs: item.end) ? "" : " (+1 day)")")
                .font(.subheadline).foregroundStyle(Color.secondary)
            if let completion {
                let member = model.snapshot.members.first { $0.id == completion.completedByMemberId }
                Text("Done by \(member?.displayName ?? "household") at \(completion.completedAtUtc.formatted(date: .omitted, time: .shortened))").font(.subheadline)
                if let note = completion.note, !note.isEmpty { Text(note).font(.subheadline) }
                if model.undoIDs.contains(completion.id) { Button("Undo completion") { model.undo(completion.id) }.buttonStyle(.bordered) }
            } else {
                if let assignee = model.snapshot.members.first(where: { $0.id == routine?.defaultAssigneeId }) {
                    Text("Assigned to \(assignee.displayName)").font(.subheadline).foregroundStyle(Color.secondary)
                }
                ViewThatFits(in: .horizontal) {
                    HStack { actions(item) }
                    VStack(alignment: .leading) { actions(item) }
                }
            }
        }.padding(.vertical, 6)
    }
    @ViewBuilder private func actions(_ item: Occurrence) -> some View {
        Button("Mark done", systemImage: "checkmark") {
            model.complete(item, member: model.snapshot.members.first { $0.isLocalDeviceOwner }?.id, note: nil)
        }.buttonStyle(.borderedProminent).accessibilityLabel("Mark \(model.snapshot.routines.first { $0.id == item.window.routineId }?.name ?? "routine") done")
        Button("Add note", systemImage: "square.and.pencil") { selected = item }.buttonStyle(.bordered)
    }
}

struct CompletionSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let item: Occurrence
    @State private var note = ""
    @State private var memberID: Int?
    var body: some View {
        NavigationStack {
            Form {
                Picker("Completed by", selection: $memberID) {
                    Text("Unassigned").tag(nil as Int?)
                    ForEach(model.snapshot.members) { Text($0.displayName).tag(Optional($0.id)) }
                }
                TextField("Optional note", text: $note, axis: .vertical).lineLimit(3...8)
            }
            .navigationTitle("Complete routine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        model.complete(item, member: memberID, note: note.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                }
            }
            .onAppear { memberID = model.snapshot.members.first { $0.isLocalDeviceOwner }?.id }
        }
    }
}

struct HistoryView: View {
    @EnvironmentObject private var model: AppModel
    @State private var range = 7
    @State private var editing: Completion?
    var body: some View {
        NavigationStack {
            List {
                Picker("Show history", selection: $range) {
                    Text("Today").tag(1); Text("This week").tag(7); Text("All history").tag(0)
                }.pickerStyle(.segmented)
                let start = Calendar.current.date(byAdding: .day, value: -(range - 1), to: Calendar.current.startOfDay(for: model.now))!
                let events = model.snapshot.completionEvents.filter { range == 0 || $0.completedAtUtc >= start }.sorted { $0.completedAtUtc > $1.completedAtUtc }
                if events.isEmpty { ContentUnavailableView("No history yet", systemImage: "clock", description: Text("Completed routines will appear here.")) }
                ForEach(events) { event in
                    let routine = model.snapshot.routines.first { $0.id == event.routineId }
                    let pet = model.snapshot.pets.first { $0.id == routine?.petId }
                    let member = model.snapshot.members.first { $0.id == event.completedByMemberId }
                    Button { editing = event } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("\(pet?.name ?? "Pet") · \(routine?.name ?? "Routine")").font(.headline)
                            Text("\(event.kind.capitalized) · \(member?.displayName ?? "Household")").font(.subheadline)
                            Text(event.completedAtUtc.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(Color.secondary)
                            if let note = event.note, !note.isEmpty { Text(note).font(.subheadline) }
                        }.foregroundStyle(Color.primary)
                    }.buttonStyle(.plain)
                }
            }.navigationTitle("History")
                .sheet(item: $editing) { HistoryEditor(event: $0) }
        }
    }
}
struct HistoryEditor: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let event: Completion
    @State private var note = ""
    @State private var confirmDelete = false
    var body: some View {
        NavigationStack {
            Form {
                Text(event.completedAtUtc.formatted())
                TextField("Note", text: $note, axis: .vertical)
                Button("Delete completion", role: .destructive) { confirmDelete = true }
            }.navigationTitle("Edit history")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if model.change({ data in
                                if let index = data.completionEvents.firstIndex(where: { $0.id == event.id }) { data.completionEvents[index].note = note }
                            }) { dismiss() }
                        }
                    }
                }
                .onAppear { note = event.note ?? "" }
                .confirmationDialog("Delete this completion?", isPresented: $confirmDelete, titleVisibility: .visible) {
                    Button("Delete completion", role: .destructive) {
                        if model.change({ $0.completionEvents.removeAll { $0.id == event.id } }) { dismiss() }
                    }
                }
        }
    }
}
