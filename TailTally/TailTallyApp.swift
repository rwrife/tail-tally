import SwiftUI

@main
struct TailTallyApp: App {
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(model)
                .tint(Color(red: 0.12, green: 0.38, blue: 0.27))
                .onChange(of: phase) { _, value in if value == .active { model.refresh() } }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in model.refresh() }
                .alert("Tail Tally", isPresented: Binding(get: { model.message != nil }, set: { if !$0 { model.message = nil } })) {
                    Button("OK", role: .cancel) { model.message = nil }
                } message: { Text(model.message ?? "") }
        }
    }
}
