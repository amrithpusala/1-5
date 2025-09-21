import Foundation
import AVFoundation
import FirebaseStorage
import FirebaseFirestore

// Handles video export to MP4, upload to Storage, and Firestore writes.
final class VideoService {
    static let shared = VideoService()
    private init() {}
    
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    /// Exports to MP4, uploads to Storage, then writes a VideoPost to Firestore.
    func uploadVideo(
        fileURL: URL,
        caption: String,
        hashtags: [String],
        dareTag: String?,
        userId: String,
        username: String,
        completion: @escaping (Result<VideoPost, Error>) -> Void
    ) {
        print("VideoService: starting upload. inputURL=\(fileURL.path)")
        
        // 1) Export to MP4
        exportToMP4(inputURL: fileURL) { exportResult in
            switch exportResult {
            case .failure(let error):
                print("VideoService: export failed: \(error.localizedDescription)")
                completion(.failure(error))
            case .success(let mp4URL):
                print("VideoService: export completed. mp4URL=\(mp4URL.path)")
                
                // 2) Upload MP4 to Storage
                let vidId = UUID().uuidString
                let objectPath = "videos/\(vidId).mp4"
                let storageRef = self.storage.reference(withPath: objectPath)
                
                let metadata = StorageMetadata()
                metadata.contentType = "video/mp4"
                
                print("VideoService: uploading to Storage path: \(objectPath)")
                storageRef.putFile(from: mp4URL, metadata: metadata) { _, error in
                    if let error = error {
                        print("VideoService: putFile error: \(error.localizedDescription)")
                        return completion(.failure(error))
                    }
                    
                    // 3) Get download URL
                    storageRef.downloadURL { url, err in
                        if let err = err {
                            print("VideoService: downloadURL error: \(err.localizedDescription)")
                            return completion(.failure(err))
                        }
                        guard let downloadURL = url else {
                            let e = NSError(domain: "VideoService", code: -10, userInfo: [NSLocalizedDescriptionKey: "Missing download URL"])
                            print("VideoService: \(e.localizedDescription)")
                            return completion(.failure(e))
                        }
                        
                        let download = downloadURL.absoluteString
                        print("VideoService: downloadURL=\(download)")
                        
                        // 4) Build post and write Firestore (feed + user copy)
                        let post = VideoPost(
                            id: vidId,
                            videoURL: download,
                            thumbnailURL: nil,
                            caption: caption,
                            hashtags: hashtags,
                            dareTag: dareTag,
                            userId: userId,
                            username: username,
                            likes: 0,
                            dislikes: 0,
                            daredoneVotes: 0,
                            darednoVotes: 0,
                            createdAt: Date()
                        )
                        
                        let payload: [String: Any] = [
                            "id": post.id,
                            "videoURL": post.videoURL,
                            "thumbnailURL": post.thumbnailURL as Any,
                            "caption": post.caption,
                            "hashtags": post.hashtags,
                            "dareTag": post.dareTag as Any,
                            "userId": post.userId,
                            "username": post.username,
                            "likes": post.likes,
                            "dislikes": post.dislikes,
                            "daredoneVotes": post.daredoneVotes,
                            "darednoVotes": post.darednoVotes,
                            "createdAt": Timestamp(date: post.createdAt)
                        ]
                        
                        let batch = self.db.batch()
                        let feedDoc = self.db.collection("videos").document(vidId)
                        let userDoc = self.db.collection("users").document(userId).collection("videos").document(vidId)
                        batch.setData(payload, forDocument: feedDoc)
                        batch.setData(payload, forDocument: userDoc)
                        
                        batch.commit { commitErr in
                            if let commitErr = commitErr {
                                print("VideoService: Firestore commit error: \(commitErr.localizedDescription)")
                                return completion(.failure(commitErr))
                            }
                            print("VideoService: upload + Firestore write OK for id=\(vidId)")
                            completion(.success(post))
                        }
                    }
                }
            }
        }
    }
    
    /// Converts an input video to a temporary .mp4 file.
    private func exportToMP4(inputURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVURLAsset(url: inputURL)
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            return completion(.failure(NSError(domain: "VideoService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create export session."])))
        }
        
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let outURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        
        // Remove existing file if any.
        try? FileManager.default.removeItem(at: outURL)
        
        exporter.outputURL = outURL
        exporter.outputFileType = .mp4
        exporter.shouldOptimizeForNetworkUse = true
        
        print("VideoService: exporting to MP4 at \(outURL.path)")
        exporter.exportAsynchronously {
            switch exporter.status {
            case .completed:
                print("VideoService: export completed OK")
                completion(.success(outURL))
            case .failed, .cancelled:
                let err = exporter.error ?? NSError(domain: "VideoService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Export failed."])
                print("VideoService: export error: \(err.localizedDescription)")
                completion(.failure(err))
            default:
                let err = exporter.error ?? NSError(domain: "VideoService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Export did not complete."])
                print("VideoService: export unknown status: \(exporter.status.rawValue) error: \(err.localizedDescription)")
                completion(.failure(err))
            }
        }
    }
    
    /// Fetches a page of feed posts (newest first). Use lastDoc for pagination.
    func fetchFeedPage(limit: Int = 5,
                       after lastDoc: DocumentSnapshot? = nil,
                       completion: @escaping (Result<([VideoPost], DocumentSnapshot?), Error>) -> Void) {
        var q: Query = db.collection("videos").order(by: "createdAt", descending: true).limit(to: limit)
        if let last = lastDoc { q = q.start(afterDocument: last) }
        
        q.getDocuments { snap, err in
            if let err = err { return completion(.failure(err)) }
            guard let snap = snap else { return completion(.success(([], nil))) }
            
            let posts: [VideoPost] = snap.documents.compactMap { try? $0.decoded() as VideoPost }
            let nextCursor = snap.documents.last
            completion(.success((posts, nextCursor)))
        }
    }
    
    /// Increments a numeric field on a post (like/dislike/votes).
    func increment(field: String, for postId: String) {
        db.collection("videos").document(postId).updateData([field: FieldValue.increment(Int64(1))])
    }
}
