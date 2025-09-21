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

// MARK: - (SessionState REMOVED to avoid redeclaration and ambiguity)

