import SwiftUI

// Main "My 1-5" screen: roll targets, view assigned dares, record flow, and coach.
struct LandingPage: View {
    @EnvironmentObject var session: SessionState
    @State private var showRoll = false
    
    // Dare picking and recording flow
    @State private var showDarePicker = false
    @State private var selectedTierForRecord: String? = nil
    @State private var showRecorder = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 22) {
                    // Title
                    Text("My 1-5")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .padding(.top, 8)

                    // Roll targets and actions
                    rollCard

                    // Record button appears when dares exist
                    if !session.assignedDares.isEmpty {
                        Button {
                            showDarePicker = true
                        } label: {
                            Label("Record Dare", systemImage: "record.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(colors: [.red, .pink], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)
                    }

                    // Current dares list
                    myDaresList

                    // Lightweight on-device helper
                    DareCoachView()
                        .environmentObject(session)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
            }
            // Roll sheet
            .sheet(isPresented: $showRoll) {
                RollView().environmentObject(session).preferredColorScheme(.dark)
            }
            // Dare picker sheet -> chains into recorder
            .sheet(isPresented: $showDarePicker) {
                DarePickerView { pickedTier in
                    self.selectedTierForRecord = pickedTier
                    self.showRecorder = true
                }
                .environmentObject(session)
                .preferredColorScheme(.dark)
            }
            // Recorder sheet
            .sheet(isPresented: $showRecorder) {
                VideoRecorderView(selectedDareTier: selectedTierForRecord)
                    .environmentObject(session)
                    .preferredColorScheme(.dark)
            }
        }
    }

    // Roll targets UI with reset.
    private var rollCard: some View {
        let hasRolled = session.rollResult != nil
        
        return VStack(spacing: 16) {
            HStack(spacing: 18) {
                targetBadge(title: "1-5", target: session.target1to5, match: session.rollResult?.match1to5, isPlaceholder: !hasRolled)
                targetBadge(title: "1-50", target: session.target1to50, match: session.rollResult?.match1to50, isPlaceholder: !hasRolled)
                targetBadge(title: "1-100", target: session.target1to100, match: session.rollResult?.match1to100, isPlaceholder: !hasRolled)
            }

            Button { showRoll = true } label: {
                Text(session.rollResult == nil ? "Roll" : "Roll Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)

            if session.rollResult != nil || !session.assignedDares.isEmpty {
                Button(role: .destructive) {
                    session.resetRoll()
                } label: {
                    Text("Reset Roll")
                        .font(.subheadline)
                        .foregroundColor(.red.opacity(0.9))
                        .padding(.top, 2)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(22)
        .padding(.horizontal, 22)
    }

    // Single target badge with match indicator.
    private func targetBadge(title: String, target: Int, match: Bool?, isPlaceholder: Bool) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption2.bold())
                .foregroundColor(.white.opacity(0.7))

            HStack(spacing: 6) {
                Text(isPlaceholder ? "?" : "\(target)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                if !isPlaceholder, let m = match {
                    Image(systemName: m ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(m ? .green : .red)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(isPlaceholder ? 0.05 : 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .frame(width: 96)
    }

    // List of assigned dares with completion toggle.
    private var myDaresList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Dares")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if session.assignedDares.isEmpty {
                    Text("No dares yet")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 24)

            ForEach(session.assignedDares) { dare in
                HStack(alignment: .top, spacing: 12) {
                    Button {
                        if let idx = session.assignedDares.firstIndex(of: dare) {
                            session.assignedDares[idx].completed.toggle()
                        }
                    } label: {
                        Image(systemName: dare.completed ? "checkmark.square.fill" : "square")
                            .foregroundColor(dare.completed ? .green : .white.opacity(0.8))
                            .font(.title3)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(dare.text)
                            .foregroundColor(.white)
                        Text("Tier: \(dare.category)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Dare Coach (simple rule-based helper)
struct DareCoachView: View {
    @EnvironmentObject var session: SessionState
    @State private var expanded = true
    @State private var input = ""
    @State private var messages: [CoachMessage] = []

    var body: some View {
        VStack(spacing: 10) {
            // Header with expand/collapse
            HStack {
                Label("Dare Coach", systemImage: "person.fill.questionmark")
                    .foregroundColor(.white)
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.spring()) { expanded.toggle() }
                } label: {
                    Image(systemName: expanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.title3)
                }
            }
            .padding(.horizontal, 8)

            if expanded {
                // Messages list (seeds tips when empty)
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages) { msg in
                            HStack(alignment: .top) {
                                if msg.role == .bot {
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                        .foregroundColor(.blue)
                                        .padding(.top, 2)
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(.purple)
                                        .padding(.top, 2)
                                }
                                Text(msg.text)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(msg.role == .bot ? Color.white.opacity(0.08) : Color.white.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                Spacer(minLength: 0)
                            }
                        }

                        if messages.isEmpty {
                            ForEach(seedTips(), id: \.self) { tip in
                                HStack(alignment: .top) {
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                        .foregroundColor(.blue)
                                        .padding(.top, 2)
                                    Text(tip)
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(Color.white.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(maxHeight: 180)

                // Input and send
                HStack(spacing: 8) {
                    TextField("Ask how to complete a dare…", text: $input)
                        .textFieldStyle(.roundedBorder)
                        .foregroundColor(.white)
                        .tint(.blue)
                        .onSubmit(sendMessage)
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            // One-time greeting
            if messages.isEmpty {
                messages.append(CoachMessage(role: .bot, text: "Need ideas or tips? Ask me how to do your dare safely and creatively."))
            }
        }
    }

    // Append user message and generate a simple response.
    private func sendMessage() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append(CoachMessage(role: .user, text: trimmed))
        input = ""

        // Rule-based hints using keywords and current dares.
        let lower = trimmed.lowercased()
        var response: String

        if lower.contains("push") || lower.contains("push-up") || lower.contains("pushups") {
            response = "For push-ups: keep a straight line from shoulders to ankles, engage your core, and go slow. Start on knees if needed, and record from the side at chest height for best form check."
        } else if lower.contains("public") || lower.contains("embarrassing") || lower.contains("outside") {
            response = "Public dares: choose a safe, open area, bring a friend to record, and be respectful. Avoid blocking paths and keep it short. Confidence tip: plan your line, take a deep breath, and go!"
        } else if lower.contains("record") || lower.contains("video") || lower.contains("camera") {
            response = "Recording tips: use good lighting, stabilize your phone, and frame vertically. Do a test clip to check audio and angle first."
        } else if lower.contains("nervous") || lower.contains("scared") || lower.contains("anxious") {
            response = "Feeling nervous is normal! Try a smaller warm-up dare first, bring a hype friend, and set a 10-second countdown to commit."
        } else if lower.contains("water") || lower.contains("chug") {
            response = "Hydration dare: use cool water, don’t overdo it—small sips if needed. Stop if you feel discomfort."
        } else {
            let tiers = session.assignedDares.map { $0.category }.joined(separator: ", ")
            let hint = tiers.isEmpty ? "" : " I see dares in tiers: \(tiers)."
            response = "Good question!\(hint) Break the dare into steps, plan setup (lighting, angle, safety), and add a fun twist."
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            messages.append(CoachMessage(role: .bot, text: response))
        }
    }

    // Default tips shown when no chat yet.
    private func seedTips() -> [String] {
        var tips: [String] = [
            "Tip: Pick a safe spot and plan your camera angle before you start.",
            "Idea: Add a fun twist — use a prop or a quick intro line to set the vibe."
        ]
        if let dare = session.assignedDares.first {
            tips.append("You’ve got a \(dare.category) dare. Try: \(dare.text)")
        }
        return tips
    }
}

// Simple message model for coach chat.
private struct CoachMessage: Identifiable {
    enum Role { case bot, user }
    let id = UUID()
    let role: Role
    let text: String
}
