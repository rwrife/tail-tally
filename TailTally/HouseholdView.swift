import SwiftUI
import TailTallyCore

struct HouseholdView: View {
    @EnvironmentObject private var model: AppModel
    @State private var addPet = false
    @State private var addMember = false
    @State private var memberName = ""
    var body: some View {
        NavigationStack {
            List {
                Section("Pets") {
                    ForEach(model.snapshot.pets) { pet in
                        NavigationLink { PetDetailView(petID: pet.id) } label: {
                            Label { VStack(alignment: .leading) { Text(pet.name); Text(pet.species).font(.caption).foregroundStyle(.secondary) } } icon: { Image(systemName: "pawprint.fill") }
                        }
                    }
                    Button("Add pet", systemImage: "plus") { addPet = true }
                }
                Section {
                    ForEach(model.snapshot.members) { member in
                        Label(member.displayName, systemImage: member.isLocalDeviceOwner ? "person.crop.circle.fill" : "person")
                            .swipeActions { Button("Delete", role: .destructive) { removeMember(member.id) } }
                    }
                    Button("Add household member", systemImage: "person.badge.plus") { addMember = true }
                } header: { Text("Household members") } footer: {
                    Text("Handoff markers are stored on this iPhone. There is no sync between devices.")
                }
            }.navigationTitle("Household")
                .disabled(model.loadFailed)
                .sheet(isPresented: $addPet) { PetEditor() }
                .alert("Add household member", isPresented: $addMember) {
                    TextField("Name", text: $memberName)
                    Button("Cancel", role: .cancel) { memberName = "" }
                    Button("Add") {
                        let name = memberName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !name.isEmpty { model.change { $0.members.append(Member(id: ($0.members.map(\.id).max() ?? 0) + 1, displayName: name, isLocalDeviceOwner: $0.members.isEmpty)) } }
                        memberName = ""
                    }
                }
        }
    }
    private func removeMember(_ id: Int) {
        model.change { data in
            data.members.removeAll { $0.id == id }
            for i in data.routines.indices where data.routines[i].defaultAssigneeId == id { data.routines[i].defaultAssigneeId = nil }
            for i in data.completionEvents.indices where data.completionEvents[i].completedByMemberId == id { data.completionEvents[i].completedByMemberId = nil }
            if !data.members.isEmpty && !data.members.contains(where: \.isLocalDeviceOwner) { data.members[0].isLocalDeviceOwner = true }
        }
    }
}
struct PetEditor: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    var pet: Pet?
    @State private var name = ""
    @State private var species = "Dog"
    var body: some View {
        NavigationStack {
            Form {
                TextField("Pet name", text: $name)
                TextField("Species", text: $species)
            }.navigationTitle(pet == nil ? "Add pet" : "Edit pet")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if model.change({ data in
                                let updated = Pet(id: pet?.id ?? (data.pets.map(\.id).max() ?? 0) + 1, name: name.trimmingCharacters(in: .whitespacesAndNewlines), species: species.trimmingCharacters(in: .whitespacesAndNewlines), photoRef: pet?.photoRef)
                                if let index = data.pets.firstIndex(where: { $0.id == updated.id }) { data.pets[index] = updated } else { data.pets.append(updated) }
                            }) { dismiss() }
                        }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || species.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }.onAppear { if let pet { name = pet.name; species = pet.species } }
        }
    }
}
struct PetDetailView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let petID: Int
    @State private var editPet = false
    @State private var addRoutine = false
    @State private var deletingPet = false
    @State private var deletingRoutine: Routine?
    var body: some View {
        let pet = model.snapshot.pets.first { $0.id == petID }
        List {
            Section("Routines") {
                ForEach(model.snapshot.routines.filter { $0.petId == petID }) { routine in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(routine.name).font(.headline)
                        ForEach(model.snapshot.scheduleWindows.filter { $0.routineId == routine.id }) { window in
                            Text(String(format: "%02d:%02d–%02d:%02d", window.startHour, window.startMinute, window.endHour, window.endMinute)).font(.subheadline)
                            Text(window.weekdays.sorted().map { Calendar.current.shortWeekdaySymbols[$0 % 7] }.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary)
                        }
                    }.swipeActions { Button("Delete", role: .destructive) { deletingRoutine = routine } }
                }
                Button("Add routine", systemImage: "plus") { addRoutine = true }
            }
            Section {
                Button("Edit pet") { editPet = true }
                Button("Delete pet and history", role: .destructive) { deletingPet = true }
            }
        }.navigationTitle(pet?.name ?? "Pet")
            .sheet(isPresented: $editPet) { PetEditor(pet: pet) }
            .sheet(isPresented: $addRoutine) { RoutineEditor(petID: petID) }
            .confirmationDialog("Delete this pet, routines, and all its history?", isPresented: $deletingPet, titleVisibility: .visible) {
                Button("Delete pet", role: .destructive) {
                    if model.change({ data in
                        let ids = Set(data.routines.filter { $0.petId == petID }.map(\.id))
                        data.completionEvents.removeAll { ids.contains($0.routineId) }
                        data.scheduleWindows.removeAll { ids.contains($0.routineId) }
                        data.routines.removeAll { ids.contains($0.id) }; data.pets.removeAll { $0.id == petID }
                    }) { dismiss() }
                }
            }
            .confirmationDialog("Delete this routine and its history?", isPresented: Binding(get: { deletingRoutine != nil }, set: { if !$0 { deletingRoutine = nil } }), titleVisibility: .visible) {
                Button("Delete routine", role: .destructive) {
                    guard let routine = deletingRoutine else { return }
                    model.change { data in
                        data.completionEvents.removeAll { $0.routineId == routine.id }
                        data.scheduleWindows.removeAll { $0.routineId == routine.id }
                        data.routines.removeAll { $0.id == routine.id }
                    }; deletingRoutine = nil
                }
            }
    }
}
struct RoutineEditor: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let petID: Int
    @State private var name = ""
    @State private var memberID: Int?
    @State private var start = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!
    @State private var end = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
    @State private var days = Set(1...7)
    var body: some View {
        NavigationStack {
            Form {
                TextField("Routine name", text: $name)
                Picker("Assigned to", selection: $memberID) {
                    Text("Anyone").tag(nil as Int?)
                    ForEach(model.snapshot.members) { Text($0.displayName).tag(Optional($0.id)) }
                }
                Section("Schedule window") {
                    DatePicker("Starts", selection: $start, displayedComponents: .hourAndMinute)
                    DatePicker("Ends", selection: $end, displayedComponents: .hourAndMinute)
                    Text("An end time at or before the start continues into the next day.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Repeat on") {
                    ForEach(1...7, id: \.self) { day in
                        Toggle(Calendar.current.weekdaySymbols[day % 7], isOn: Binding(get: { days.contains(day) }, set: { if $0 { days.insert(day) } else { days.remove(day) } }))
                    }
                }
            }.navigationTitle("Add routine")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || days.isEmpty) }
                }
        }
    }
    private func save() {
        if model.change({ data in
            let id = (data.routines.map(\.id).max() ?? 0) + 1
            data.routines.append(Routine(id: id, petId: petID, name: name.trimmingCharacters(in: .whitespacesAndNewlines), defaultAssigneeId: memberID))
            data.scheduleWindows.append(ScheduleWindow(id: (data.scheduleWindows.map(\.id).max() ?? 0) + 1, routineId: id, startHour: Calendar.current.component(.hour, from: start), startMinute: Calendar.current.component(.minute, from: start), endHour: Calendar.current.component(.hour, from: end), endMinute: Calendar.current.component(.minute, from: end), days: days))
        }) { dismiss() }
    }
}
