import SwiftUI

// Entry point: shows main tabs if logged in, otherwise login.
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
        // Global dark look.
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}
