import Foundation

// MARK: - RollResult
struct RollResult {
    var rolled1to5: Int
    var rolled1to50: Int
    var rolled1to100: Int

    var target1to5: Int
    var target1to50: Int
    var target1to100: Int

    var match1to5: Bool { rolled1to5 == target1to5 }
    var match1to50: Bool { rolled1to50 == target1to50 }
    var match1to100: Bool { rolled1to100 == target1to100 }
}

// MARK: - Dare
struct Dare: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let category: String   // "1-5", "1-50", "1-100"
    var completed: Bool = false
}

// MARK: - UserVideo (for TikTok-style profile)
struct UserVideo: Identifiable {
    let id = UUID()
    let title: String
}

// MARK: - SessionState
final class SessionState: ObservableObject {
    // Rolling system
    @Published var target1to5: Int = Int.random(in: 1...5)
    @Published var target1to50: Int = Int.random(in: 1...50)
    @Published var target1to100: Int = Int.random(in: 1...100)

    @Published var rollResult: RollResult? = nil
    @Published var assignedDares: [Dare] = []

    // User & Profile
    @Published var username: String = ""   // default blank until login
    @Published var isLoggedIn: Bool = false
    @Published var userVideos: [UserVideo] = []  // TikTok-style grid posts

    func resetRoll() {
        target1to5   = Int.random(in: 1...5)
        target1to50  = Int.random(in: 1...50)
        target1to100 = Int.random(in: 1...100)
        rollResult = nil
        assignedDares.removeAll()
    }

    func assignDares(from result: RollResult) {
        var picks: [Dare] = []
        if result.match1to5,   let d = DaresLibrary.oneToFive.randomElement()   { picks.append(d) }
        if result.match1to50,  let d = DaresLibrary.oneToFifty.randomElement()  { picks.append(d) }
        if result.match1to100, let d = DaresLibrary.oneToHundred.randomElement(){ picks.append(d) }
        assignedDares = picks
    }

    func assignRandomDares() {
        assignedDares = [
            DaresLibrary.oneToFive.randomElement(),
            DaresLibrary.oneToFifty.randomElement(),
            DaresLibrary.oneToHundred.randomElement()
        ].compactMap { $0 }
    }
}
