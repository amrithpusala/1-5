import Foundation
import FirebaseFirestore

struct VideoPost: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var videoURL: String
    var thumbnailURL: String?
    var caption: String
    var hashtags: [String]
    var dareTag: String?         // e.g. "1-50"
    var userId: String
    var username: String
    var likes: Int
    var dislikes: Int
    var daredoneVotes: Int       // ✅ votes
    var darednoVotes: Int        // ❌ votes
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, videoURL, thumbnailURL, caption, hashtags, dareTag, userId, username, likes, dislikes, daredoneVotes, darednoVotes, createdAt
    }
}

extension QueryDocumentSnapshot {
    func decoded<T: Decodable>() throws -> T {
        let raw = data()
        let converted = Self.convertTimestamps(in: raw)
        let json = try JSONSerialization.data(withJSONObject: converted, options: [])
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: json)
    }
    
    private static func convertTimestamps(in value: Any) -> Any {
        switch value {
        case let ts as Timestamp:
            // Use ISO8601 so JSONDecoder can parse it
            return ISO8601DateFormatter().string(from: ts.dateValue())
        case let dict as [String: Any]:
            var out: [String: Any] = [:]
            for (k, v) in dict {
                out[k] = convertTimestamps(in: v)
            }
            return out
        case let arr as [Any]:
            return arr.map { convertTimestamps(in: $0) }
        default:
            return value
        }
    }
}
