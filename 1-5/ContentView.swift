import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: SessionState

    var body: some View {
        Group {
            if session.isLoggedIn {
                MainTabView()
                    .environmentObject(session)
            } else {
                LoginView()
                    .environmentObject(session)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}
