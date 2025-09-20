import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: SessionState

    @State private var isLoginMode = true
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {

                // Logo
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

                // Username
                VStack(alignment: .leading, spacing: 6) {
                    Text("Username")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    TextField("Enter username", text: $username)
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

                // Email (sign up only)
                if !isLoginMode {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        TextField("Enter email", text: $email)
                            .keyboardType(.emailAddress)
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

                // Error text (if any)
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, -8)
                }

                // Primary button
                Button {
                    // Hook up real auth later; for now just pass through
                    if username.isEmpty || password.isEmpty {
                        errorMessage = "Please enter username and password."
                    } else {
                        errorMessage = nil
                        session.isLoggedIn = true
                    }
                } label: {
                    Text(isLoginMode ? "Log In" : "Sign Up")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(colors: [.blue, .purple],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                // Bottom link
                Button {
                    isLoginMode.toggle()
                } label: {
                    Text(isLoginMode ? "Don’t have an account? Sign Up" :
                                      "Already have an account? Log In")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }

                // Skip (testing)
                Button {
                    session.isLoggedIn = true
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
}
