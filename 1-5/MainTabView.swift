import SwiftUI

// Root tab navigation with three sections: My 1-5, FYP, Profile.
struct MainTabView: View {
    // Shared session state for child views.
    @EnvironmentObject var session: SessionState

    // Currently selected tab index.
    @State private var selected = 0

    var body: some View {
        // Tab bar with three tabs.
        TabView(selection: $selected) {
            // My 1-5
            LandingPage()
                .environmentObject(session)
                .tabItem {
                    Image(systemName: "die.face.5.fill")
                    Text("My 1-5")
                }
                .tag(0)

            // FYP
            FYPView()
                .tabItem {
                    Image(systemName: "play.rectangle.fill")
                    Text("FYP")
                }
                .tag(1)

            // Profile
            ProfileView()
                .environmentObject(session)
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        // Selected tint and full-bleed dark background.
        .accentColor(.blue)
        .background(Color.black.ignoresSafeArea())
    }
}
