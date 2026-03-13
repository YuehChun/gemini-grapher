import SwiftUI
import SwiftData

@main
struct GeminiGrapherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Session.self, Message.self])

        Settings {
            SettingsView()
        }
    }
}
