import SwiftUI
import FirebaseFirestore
import AVKit

// User profile: header, bio/stats, grid of posted videos, and stat overlays.
struct ProfileView: View {
    @EnvironmentObject var session: SessionState
    @State private var myPosts: [VideoPost] = []
    @State private var selectedPost: VideoPost? = nil

    // Stat overlay state
    @State private var showingStatOverlay: Bool = false
    @State private var activeStat: ProfileStat? = nil

    // 3-column grid for thumbnails.
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header: avatar, username, bio, counters.
                        VStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 90, height: 90)
                                .foregroundColor(.white.opacity(0.85))
                                .padding(.top, 30)

                            Text(session.username.isEmpty ? "Test User" : session.username)
                                .font(.title3.bold())
                                .foregroundColor(.white)

                            Text(session.bio.isEmpty ? "No bio yet." : session.bio)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 40) {
                                VStack {
                                    Text("0").bold().foregroundColor(.white)
                                    Text("Following").font(.caption).foregroundColor(.white.opacity(0.7))
                                }
                                VStack {
                                    Text("0").bold().foregroundColor(.white)
                                    Text("Followers").font(.caption).foregroundColor(.white.opacity(0.7))
                                }
                                VStack {
                                    Text("\(myPosts.count)").bold().foregroundColor(.white)
                                    Text("Posts").font(.caption).foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .padding(.top, 8)
                        }

                        // Bio + tappable stat chips.
                        MyBioAndStatsSection(
                            bio: session.bio.isEmpty ? "Tell people about your dares, style, and vibe." : session.bio,
                            stats: computedStats,
                            onTapStat: { stat in
                                activeStat = stat
                                showingStatOverlay = true
                            }
                        )
                        .padding(.horizontal, 16)

                        Divider().background(Color.white.opacity(0.2))

                        // Video grid with inline thumbnails.
                        if myPosts.isEmpty {
                            Text("No videos yet")
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 40)
                        } else {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(myPosts) { post in
                                    Button {
                                        selectedPost = post
                                    } label: {
                                        ZStack {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.2))
                                                .aspectRatio(9/16, contentMode: .fit)

                                            if let url = URL(string: post.videoURL) {
                                                VideoThumbnailView(url: url)
                                                    .aspectRatio(9/16, contentMode: .fill)
                                                    .clipped()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Tap-through overlay showing stat details.
                if showingStatOverlay, let stat = activeStat {
                    StatDetailOverlay(stat: stat) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showingStatOverlay = false
                            activeStat = nil
                        }
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Logout") {
                        session.isLoggedIn = false
                    }
                    .foregroundColor(.red)
                }
            }
            .onAppear {
                if !session.userId.isEmpty {
                    loadMyPosts()
                } else {
                    myPosts = []
                }
            }
            // Fullscreen player for selected post.
            .sheet(item: $selectedPost) { post in
                if let url = URL(string: post.videoURL) {
                    VideoPlayer(player: AVPlayer(url: url))
                        .ignoresSafeArea()
                }
            }
        }
    }

    // Derived stats from posts and dares.
    private var computedStats: [ProfileStat] {
        let likes = myPosts.reduce(0) { $0 + $1.likes }
        let dislikes = myPosts.reduce(0) { $0 + $1.dislikes }
        let postsCount = myPosts.count
        let completed = session.assignedDares.filter { $0.completed }.count

        return [
            ProfileStat(kind: .likes, value: likes, caption: "Total likes across your videos."),
            ProfileStat(kind: .dislikes, value: dislikes, caption: "Total dislikes received."),
            ProfileStat(kind: .completed, value: completed, caption: "Dares you marked as completed."),
            ProfileStat(kind: .posts, value: postsCount, caption: "Videos you’ve posted.")
        ]
    }

    // Loads this user's posts from Firestore (newest first).
    private func loadMyPosts() {
        let db = Firestore.firestore()
        db.collection("users").document(session.userId).collection("videos")
            .order(by: "createdAt", descending: true)
            .getDocuments { snap, err in
                if let err = err {
                    print("Failed to load posts: \(err)")
                    return
                }
                guard let snap = snap else { return }
                let posts: [VideoPost] = snap.documents.compactMap { try? $0.decoded() as VideoPost }
                DispatchQueue.main.async {
                    self.myPosts = posts
                }
            }
    }
}

// Simple thumbnail generator from a video URL.
struct VideoThumbnailView: View {
    let url: URL
    @State private var image: UIImage? = nil

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.3)
                    .onAppear { generateThumbnail() }
            }
        }
    }

    // Extracts the first frame as a thumbnail.
    private func generateThumbnail() {
        DispatchQueue.global().async {
            let asset = AVAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            if let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) {
                let uiImage = UIImage(cgImage: cgImage)
                DispatchQueue.main.async { self.image = uiImage }
            }
        }
    }
}

// MARK: - Bio & Stats Section

// Shows bio text and horizontal stat chips.
private struct MyBioAndStatsSection: View {
    let bio: String
    let stats: [ProfileStat]
    let onTapStat: (ProfileStat) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Bio")
                .font(.headline)
                .foregroundColor(.white)

            Text(bio)
                .foregroundColor(.white.opacity(0.85))
                .font(.subheadline)
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            Text("Stats")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 4)

            // Stat chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(stats) { stat in
                        StatChip(stat: stat)
                            .onTapGesture {
                                onTapStat(stat)
                            }
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }
}

// Single stat chip with icon and value.
private struct StatChip: View {
    let stat: ProfileStat

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: stat.kind.symbol)
                .foregroundColor(stat.kind.color)
                .font(.headline)
            Text("\(stat.value)")
                .foregroundColor(.white)
                .font(.subheadline).bold()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Overlay

// Dimmed overlay with details about a selected stat.
private struct StatDetailOverlay: View {
    let stat: ProfileStat
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: stat.kind.symbol)
                        .foregroundColor(stat.kind.color)
                        .font(.title3)
                    Text(stat.kind.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.title3)
                    }
                }

                Text(stat.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)

                HStack {
                    Text("Current value:")
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("\(stat.value)")
                        .foregroundColor(.white)
                        .bold()
                }
                .padding(.top, 6)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 20)
            .padding(.horizontal, 24)
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.easeOut(duration: 0.2), value: stat.id)
    }
}

// MARK: - Models for stats

// Lightweight stat model for chips and overlay.
private struct ProfileStat: Identifiable, Equatable {
    enum Kind {
        case likes, dislikes, completed, posts

        var symbol: String {
            switch self {
            case .likes: return "heart.fill"
            case .dislikes: return "hand.thumbsdown.fill"
            case .completed: return "checkmark.seal.fill"
            case .posts: return "play.rectangle.fill"
            }
        }
        var title: String {
            switch self {
            case .likes: return "Likes"
            case .dislikes: return "Dislikes"
            case .completed: return "Completed Dares"
            case .posts: return "Posts"
            }
        }
        var color: Color {
            switch self {
            case .likes: return .red
            case .dislikes: return .gray
            case .completed: return .green
            case .posts: return .blue
            }
        }
    }

    let id = UUID()
    let kind: Kind
    let value: Int
    let caption: String
}
