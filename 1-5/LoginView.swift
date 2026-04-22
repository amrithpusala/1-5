import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @EnvironmentObject var session: SessionState

    @State private var isLoginMode = true
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("🔥 1-5")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple],
                                                    startPoint: .leading, endPoint: .trailing))
                    .padding(.top, 40)

                // Mode toggle
                Picker("", selection: $isLoginMode) {
                    Text("Log In").tag(true)
                    Text("Sign Up").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Username (sign up only)
                if !isLoginMode {
                    fieldBox(label: "Username", text: $username, keyboard: .default)
                }

                // Email
                fieldBox(label: "Email", text: $email, keyboard: .emailAddress)

                // Password
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    SecureField("Enter password", text: $password)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(LinearGradient(colors: [.blue, .purple],
                                                       startPoint: .leading, endPoint: .trailing), lineWidth: 1)
                        )
                        .foregroundColor(.white)
                }
                .padding(.horizontal)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    isLoginMode ? login() : signUp()
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(isLoginMode ? "Log In" : "Sign Up")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(colors: [.blue, .purple],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .disabled(isLoading)

                Button {
                    isLoginMode.toggle()
                    errorMessage = nil
                } label: {
                    Text(isLoginMode ? "Don't have an account? Sign Up" :
                                      "Already have an account? Log In")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }

                Button {
                    session.becomeTestUserIfNeeded()
                } label: {
                    Text("Skip Login (testing)")
                        .foregroundColor(.blue)
                        .underline()
                }
                .padding(.bottom, 20)

                Spacer()
            }
        }
    }

    @ViewBuilder
    private func fieldBox(label: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .foregroundColor(.gray)
                .font(.subheadline)
            TextField("Enter \(label.lowercased())", text: text)
                .keyboardType(keyboard)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(LinearGradient(colors: [.blue, .purple],
                                               startPoint: .leading, endPoint: .trailing), lineWidth: 1)
                )
                .foregroundColor(.white)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal)
    }

    private func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            DispatchQueue.main.async {
                isLoading = false
                errorMessage = error?.localizedDescription
            }
        }
    }

    private func signUp() {
        let trimmed = username.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { errorMessage = "Username is required."; return }
        guard !email.isEmpty, !password.isEmpty else { errorMessage = "All fields are required."; return }
        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    return
                }
                guard let uid = result?.user.uid else { return }
                Firestore.firestore().collection("users").document(uid).setData([
                    "username": trimmed,
                    "bio": "",
                    "createdAt": Timestamp(date: Date())
                ]) { err in
                    DispatchQueue.main.async {
                        isLoading = false
                        if let err = err { errorMessage = err.localizedDescription }
                        // auth state listener in SessionState handles isLoggedIn
                    }
                }
            }
        }
    }
}
