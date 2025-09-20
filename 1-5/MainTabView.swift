import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var session: SessionState
    @State private var selected = 0

    var body: some View {
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
        .accentColor(.blue)
        .background(Color.black.ignoresSafeArea())
    }
}
