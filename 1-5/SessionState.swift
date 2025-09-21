//
//  SessionState.swift
//  1-5
//
//  Created by Taran Patibanda on 9/20/25.
//

import SwiftUI
import FirebaseAuth

// Central app/session model: auth state, user profile, roll/dares.
class SessionState: ObservableObject {
    // Auth and profile
    @Published var isLoggedIn: Bool = false
    @Published var userId: String = ""        // Firestore path key
    @Published var username: String = ""      // Profile display
    @Published var bio: String = ""           // Profile bio
    @Published var userVideos: [VideoPost] = [] // Profile posts
    
    // Dares and roll state
    @Published var assignedDares: [Dare] = []
    @Published var rollResult: RollResult? = nil
    @Published var target1to5: Int = Int.random(in: 1...5)
    @Published var target1to50: Int = Int.random(in: 1...50)
    @Published var target1to100: Int = Int.random(in: 1...100)

    init() {
        // Reuse current user or sign in anonymously for testing.
        if let currentUser = Auth.auth().currentUser {
            adopt(user: currentUser)
        } else {
            Auth.auth().signInAnonymously { [weak self] result, error in
                guard let self = self else { return }
                if let user = result?.user {
                    DispatchQueue.main.async {
                        self.adopt(user: user)
                    }
                } else if let error = error {
                    // Keep app usable; optional UI error handling.
                    print("Anonymous sign-in failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Initialize session fields from Firebase user.
    private func adopt(user: User) {
        self.isLoggedIn = true
        self.userId = user.uid
        if self.username.isEmpty {
            self.username = "Test User"
        }
        self.bio = ""
    }
    
    // Clear current roll and generate new targets.
    func resetRoll() {
        rollResult = nil
        target1to5 = Int.random(in: 1...5)
        target1to50 = Int.random(in: 1...50)
        target1to100 = Int.random(in: 1...100)
        assignedDares = []
    }

    // Always pick one dare per tier from library.
    func assignDares(from result: RollResult) {
        var picks: [Dare] = []
        if let d = DaresLibrary.oneToFive.randomElement() { picks.append(d) }
        if let d = DaresLibrary.oneToFifty.randomElement() { picks.append(d) }
        if let d = DaresLibrary.oneToHundred.randomElement() { picks.append(d) }
        assignedDares = picks
    }

    // Random dares across tiers (no roll dependency).
    func assignRandomDares() {
        assignedDares = [
            DaresLibrary.oneToFive.randomElement(),
            DaresLibrary.oneToFifty.randomElement(),
            DaresLibrary.oneToHundred.randomElement()
        ].compactMap { $0 }
    }
    
    // Test helper to force a local session.
    func becomeTestUserIfNeeded() {
        if userId.isEmpty {
            userId = "test-user"
        }
        if username.isEmpty {
            username = "Test User"
        }
        isLoggedIn = true
    }
}
