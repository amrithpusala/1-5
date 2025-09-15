import SwiftUI
import FirebaseCore

@main
struct OneFiveApp: App {
    // Initialize Firebase when app starts
    init() {
        print("➡️ Configuring Firebase…")
        FirebaseApp.configure()
        
        if let options = FirebaseApp.app()?.options {
            print("✅ Firebase options loaded: \(options.projectID ?? "no projectID")")
        } else {
            print("❌ Firebase config missing")
        }

    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
