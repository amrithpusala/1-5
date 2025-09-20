import SwiftUI

struct RollView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var session: SessionState

    @State private var selected1to5 = 1
    @State private var selected1to50 = 1
    @State private var selected1to100 = 1
    @State private var showCPU = false

    var body: some View {
        ZStack {
            // ✅ Full background gradient restored
            LinearGradient(gradient: Gradient(colors: [.black, .purple.opacity(0.9)]),
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // ✅ Back button restored
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal)

                Text("🎰 Roll Your Numbers")
                    .font(.title2).bold()
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple],
                                                    startPoint: .leading,
                                                    endPoint: .trailing))
                    .padding(.top)

                // Pickers row
                HStack(spacing: 20) {
                    InfinitePicker(title: "1-5", range: 1...5, value: $selected1to5)
                    InfinitePicker(title: "1-50", range: 1...50, value: $selected1to50)
                    InfinitePicker(title: "1-100", range: 1...100, value: $selected1to100)
                }
                .frame(height: 150)

                // Done button
                Button(action: rollNumbers) {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(colors: [.blue, .purple],
                                                   startPoint: .leading,
                                                   endPoint: .trailing))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }
                .padding(.horizontal)

                // CPU animation boxes
                if let result = session.rollResult {
                    HStack(spacing: 25) {
                        cpuBox(value: result.rolled1to5, matches: result.match1to5)
                        cpuBox(value: result.rolled1to50, matches: result.match1to50)
                        cpuBox(value: result.rolled1to100, matches: result.match1to100)
                    }
                    .padding(.top, 10)
                } else {
                    Spacer().frame(height: 100)
                }

                Spacer()

                // Feeling bold link
                Button(action: {
                    session.assignRandomDares()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Feeling bold? Assign anyways.")
                        .font(.footnote)
                        .underline()
                        .foregroundColor(.blue)
                }
                .padding(.bottom, 10)
            }
        }
    }

    // MARK: - Helpers
    private func rollNumbers() {
        let result = RollResult(
            rolled1to5: selected1to5,
            rolled1to50: selected1to50,
            rolled1to100: selected1to100,
            target1to5: session.target1to5,
            target1to50: session.target1to50,
            target1to100: session.target1to100
        )
        session.rollResult = result
        withAnimation {
            showCPU = true
        }
        session.assignDares(from: result)
    }

    // MARK: - CPU Box with Gradient Outline + Pop Check
    private func cpuBox(value: Int, matches: Bool) -> some View {
        VStack(spacing: 8) {
            Text("\(value)")
                .font(.title2).bold()
                .foregroundColor(.white)
                .padding(.vertical, 10)
                .frame(width: 90)
                .background(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            matches
                            ? AnyShapeStyle(LinearGradient(colors: [.blue, .purple],
                                                           startPoint: .leading,
                                                           endPoint: .trailing))
                            : AnyShapeStyle(Color.clear),
                            lineWidth: 2
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .scaleEffect(showCPU ? 1 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCPU)

            Image(systemName: matches ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(matches ? .green : .red)
                .scaleEffect(showCPU ? 1 : 0.5)
                .opacity(showCPU ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: showCPU)
        }
    }
}
