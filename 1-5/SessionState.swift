import SwiftUI
import FirebaseAuth

// Central app/session model: auth state, user profile, roll/dares.
class SessionState: ObservableObject {
    // Auth and profile
    @Published var isLoggedIn: Bool = false
    @Published var userId: String = ""
    @Published var username: String = ""
    @Published var bio: String = ""
    @Published var userVideos: [VideoPost] = []

    // Dares and roll state
    @Published var assignedDares: [Dare] = []
    @Published var rollResult: RollResult? = nil
    @Published var target1to5: Int = Int.random(in: 1...5)
    @Published var target1to50: Int = Int.random(in: 1...50)
    @Published var target1to100: Int = Int.random(in: 1...100)

    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if let user = user {
                    self?.adopt(user: user)
                } else {
                    self?.isLoggedIn = false
                    self?.userId = ""
                    self?.username = ""
                    self?.userVideos = []
                }
            }
        }
    }

    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    private func adopt(user: User) {
        self.isLoggedIn = true
        self.userId = user.uid
    }

    func resetRoll() {
        rollResult = nil
        target1to5 = Int.random(in: 1...5)
        target1to50 = Int.random(in: 1...50)
        target1to100 = Int.random(in: 1...100)
        assignedDares = []
    }

    func assignDares(from result: RollResult) {
        var picks: [Dare] = []
        if let d = DaresLibrary.oneToFive.randomElement()   { picks.append(d) }
        if let d = DaresLibrary.oneToFifty.randomElement()  { picks.append(d) }
        if let d = DaresLibrary.oneToHundred.randomElement(){ picks.append(d) }
        assignedDares = picks
    }

    func assignRandomDares() {
        assignedDares = [
            DaresLibrary.oneToFive.randomElement(),
            DaresLibrary.oneToFifty.randomElement(),
            DaresLibrary.oneToHundred.randomElement()
        ].compactMap { $0 }
    }

    // Test helper — keeps the skip button working.
    func becomeTestUserIfNeeded() {
        if userId.isEmpty { userId = "test-user" }
        if username.isEmpty { username = "Test User" }
        isLoggedIn = true
    }
}
