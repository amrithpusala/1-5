import SwiftUI

struct DarePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionState
    
    let onPick: (String?) -> Void   // returns the selected dare tier (e.g., "1-50") or nil
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 18) {
                Text("Which dare are you recording?")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding(.top, 32)
                
                if session.rollResult == nil || session.assignedDares.isEmpty {
                    Text("You’ll see dares here after you roll.")
                        .foregroundColor(.white.opacity(0.8))
                        .padding()
                    Button("Skip (no specific dare)") {
                        onPick(nil)
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding(.top, 8)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(session.assignedDares) { dare in
                                Button {
                                    onPick(dare.category) // pass tier ("1-5" / "1-50" / "1-100")
                                    dismiss()
                                } label: {
                                    HStack {
                                        Text(dare.text)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(dare.category)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.white.opacity(0.15))
                                            .clipShape(Capsule())
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.bottom, 14)
            }
        }
    }
}
