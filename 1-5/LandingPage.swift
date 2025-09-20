import SwiftUI

struct LandingPage: View {
    @EnvironmentObject var session: SessionState
    @State private var showRoll = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 22) {
                    Text("My 1-5")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .padding(.top, 8)

                    rollCard

                    if !session.assignedDares.isEmpty {
                        Button {
                            print("Record Dare tapped")
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

                    myDaresList
                    Spacer(minLength: 24)
                }
            }
            .sheet(isPresented: $showRoll) {
                RollView().environmentObject(session).preferredColorScheme(.dark)
            }
        }
    }

    private var rollCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 18) {
                targetBadge(title: "1-5", target: session.target1to5, match: session.rollResult?.match1to5)
                targetBadge(title: "1-50", target: session.target1to50, match: session.rollResult?.match1to50)
                targetBadge(title: "1-100", target: session.target1to100, match: session.rollResult?.match1to100)
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

    private func targetBadge(title: String, target: Int, match: Bool?) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption2.bold())
                .foregroundColor(.white.opacity(0.7))

            HStack(spacing: 6) {
                Text("\(target)")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                if let m = match {
                    Image(systemName: m ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(m ? .green : .red)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .frame(width: 96)
    }

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
