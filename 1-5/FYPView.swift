import SwiftUI
import AVKit

// Simple feed ("For You Page") showing sample videos with basic interactions.
struct FYPView: View {
    @State private var posts: [VideoPost] = []
    @State private var loading = false
    @State private var reachedEnd = true // no pagination with dummy data
    
    // Small logo animation on appear.
    @State private var showLogo = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if posts.isEmpty && !loading {
                // Empty state with load button.
                VStack(spacing: 14) {
                    Image("1-5logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .opacity(showLogo ? 1 : 0)
                        .scaleEffect(showLogo ? 1 : 0.85)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showLogo)
                    
                    Text("No videos yet")
                        .foregroundColor(.white.opacity(0.85))
                    Button(action: { loadDummyFeed() }) {
                        Text("Load Dare Feed")
                    }
                    .foregroundColor(.blue)
                }
            } else {
                // Vertical scrolling feed of autoplaying videos.
                ScrollView {
                    ZStack(alignment: .top) {
                        LazyVStack(spacing: 0) {
                            ForEach(posts) { post in
                                FYPCell(post: post, interactionsEnabled: false)
                                    .frame(height: UIScreen.main.bounds.height * 0.88)
                                    .modifier(SoftAppear())
                            }
                            if reachedEnd {
                                VStack(spacing: 10) {
                                    Image("1-5logo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 42, height: 42)
                                        .opacity(0.95)
                                        .scaleEffect(1.02)
                                    Text("End of feed")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.vertical, 24)
                                .transition(.opacity.combined(with: .scale))
                            } else if loading {
                                ProgressView().padding(.vertical, 24)
                            }
                        }
                        
                        // Top gradient to soften first cell edge.
                        LinearGradient(colors: [Color.black.opacity(0.6), .clear],
                                       startPoint: .top, endPoint: .bottom)
                        .frame(height: 40)
                        .allowsHitTesting(false)
                    }
                }
                .scrollIndicators(.hidden)
                .modifier(PagingIfAvailable())
            }
        }
        .onAppear {
            if posts.isEmpty { loadDummyFeed() }
            withAnimation {
                showLogo = true
            }
        }
    }
    
    // Loads a few sample clips into the feed.
    private func loadDummyFeed() {
        guard !loading else { return }
        loading = true
        
        // Public sample videos.
        let sampleClips = [
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
            "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4"
        ]
        
        // Shuffle for variety.
        let shuffled = Array(sampleClips.shuffled().prefix(3))
        
        let now = Date()
        let post1 = VideoPost(
            id: UUID().uuidString,
            videoURL: shuffled[0],
            thumbnailURL: nil,
            caption: "Tier 1-5: Chug a glass of water in under 10 seconds. I rolled a 3 — let’s go! 💦",
            hashtags: ["#1to5", "#hydration", "#dare", "#15App"],
            dareTag: "1-5",
            userId: "user-amy",
            username: "amy",
            likes: 23,
            dislikes: 1,
            daredoneVotes: 12,
            darednoVotes: 2,
            createdAt: now.addingTimeInterval(-60 * 5)
        )
        
        let post2 = VideoPost(
            id: UUID().uuidString,
            videoURL: shuffled[1],
            thumbnailURL: nil,
            caption: "Tier 1-50: Do 10 push-ups and shout your roll. I rolled a 27. Form check me! 💪",
            hashtags: ["#1to50", "#fitness", "#pushups", "#15App"],
            dareTag: "1-50",
            userId: "user-jay",
            username: "jay",
            likes: 57,
            dislikes: 3,
            daredoneVotes: 34,
            darednoVotes: 5,
            createdAt: now.addingTimeInterval(-60 * 20)
        )
        
        let post3 = VideoPost(
            id: UUID().uuidString,
            videoURL: shuffled[2],
            thumbnailURL: nil,
            caption: "Tier 1-100: Sing the alphabet backward in public. Rolled 81… send help 😂",
            hashtags: ["#1to100", "#publicdare", "#challenge", "#15App"],
            dareTag: "1-100",
            userId: "user-luca",
            username: "luca",
            likes: 102,
            dislikes: 7,
            daredoneVotes: 61,
            darednoVotes: 9,
            createdAt: now.addingTimeInterval(-60 * 60)
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.25)) {
                self.posts = [post1, post2, post3]
            }
            self.loading = false
            self.reachedEnd = true
        }
    }
}

// MARK: - Cell

// Single feed cell with autoplaying player and quick actions.
private struct FYPCell: View {
    let post: VideoPost
    var interactionsEnabled: Bool = true
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let url = URL(string: post.videoURL) {
                VideoPlayer(player: {
                    let p = AVPlayer(url: url)
                    p.play()
                    p.isMuted = false
                    return p
                }())
                .ignoresSafeArea()
                .transition(.opacity)
            } else {
                Color.black
            }
            
            // Overlay: caption and actions.
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("@\(post.username)")
                        .bold()
                    Text(post.caption)
                        .lineLimit(3)
                        .foregroundColor(.white.opacity(0.9))
                    if !post.hashtags.isEmpty {
                        Text(post.hashtags.joined(separator: " "))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .foregroundColor(.white)
                .padding(.bottom, 30)
                
                Spacer()
                
                VStack(spacing: 18) {
                    Button(action: {
                        if interactionsEnabled {
                            VideoService.shared.increment(field: "likes", for: post.id)
                        }
                    }) {
                        Image(systemName: "heart.fill").font(.title2)
                    }
                    .disabled(!interactionsEnabled)
                    
                    Button(action: {
                        if interactionsEnabled {
                            VideoService.shared.increment(field: "dislikes", for: post.id)
                        }
                    }) {
                        Image(systemName: "hand.thumbsdown.fill").font(.title2)
                    }
                    .disabled(!interactionsEnabled)
                    
                    Button(action: {
                        if interactionsEnabled {
                            VideoService.shared.increment(field: "daredoneVotes", for: post.id)
                        }
                    }) {
                        Image(systemName: "checkmark.seal.fill").font(.title2)
                    }
                    .disabled(!interactionsEnabled)
                    
                    Button(action: {
                        if interactionsEnabled {
                            VideoService.shared.increment(field: "darednoVotes", for: post.id)
                        }
                    }) {
                        Image(systemName: "xmark.seal.fill").font(.title2)
                    }
                    .disabled(!interactionsEnabled)
                    .padding(.bottom, 30)
                }
                .foregroundColor(.white)
                .padding(.trailing, 16)
            }
            .padding(.horizontal, 16)
        }
        .background(Color.black)
        .clipShape(Rectangle())
        .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Soft appear modifier

// Gentle fade/scale-in when cells appear.
private struct SoftAppear: ViewModifier {
    @State private var visible = false
    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .scaleEffect(visible ? 1 : 0.98)
            .onAppear {
                withAnimation(.easeOut(duration: 0.22)) {
                    visible = true
                }
            }
    }
}

// MARK: - iOS 17+ paging modifier gate

// Enables paging behavior on iOS 17+; no-op otherwise.
private struct PagingIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.scrollTargetBehavior(.paging)
        } else {
            content
        }
    }
}
