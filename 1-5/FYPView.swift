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
                VStack(spacing: 14) {
                    Image(systemName: "play.rectangle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .foregroundColor(.purple.opacity(0.8))
                        .opacity(showLogo ? 1 : 0)
                        .scaleEffect(showLogo ? 1 : 0.85)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showLogo)

                    Text("No dare videos yet")
                        .foregroundColor(.white.opacity(0.85))
                    Text("Be the first to post one!")
                        .foregroundColor(.white.opacity(0.55))
                        .font(.subheadline)
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
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 42))
                                        .foregroundColor(.purple.opacity(0.8))
                                    Text("You're all caught up")
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
            if posts.isEmpty { loadFeed() }
            withAnimation { showLogo = true }
        }
    }

    private func loadFeed() {
        guard !loading else { return }
        loading = true
        VideoService.shared.fetchFeedPage(limit: 20) { result in
            DispatchQueue.main.async {
                loading = false
                switch result {
                case .success(let (fetched, _)):
                    withAnimation(.easeInOut(duration: 0.25)) {
                        posts = fetched
                    }
                    reachedEnd = fetched.count < 20
                case .failure(let err):
                    print("FYP load error: \(err.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Cell

// Single feed cell with autoplaying player and quick actions.
private struct FYPCell: View {
    let post: VideoPost
    var interactionsEnabled: Bool = true
    @State private var player: AVPlayer?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let player = player {
                VideoPlayer(player: player)
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
        .onAppear {
            guard let url = URL(string: post.videoURL) else { return }
            let p = AVPlayer(url: url)
            p.play()
            player = p
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: p.currentItem,
                queue: .main
            ) { _ in p.seek(to: .zero); p.play() }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
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
