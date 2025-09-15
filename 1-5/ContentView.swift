import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoginMode = false
    @State private var errorMessage: String = ""
    @State private var isSignedIn = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isSignedIn {
                LandingPageView() // Show landing page once signed in
            } else {
                VStack(spacing: 20) {
                    
                    // Logo
                    Text("🔥 1-5")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .padding(.bottom, 30)
                    
                    // Username field (only for sign up or login with username)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Username")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        TextField("Enter username", text: $username)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).stroke(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing), lineWidth: 1))
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                    }
                    
                    // Email field (only for sign up)
                    if !isLoginMode {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                            TextField("Enter email", text: $email)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 10).stroke(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing), lineWidth: 1))
                                .foregroundColor(.white)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        SecureField("Enter password", text: $password)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).stroke(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing), lineWidth: 1))
                            .foregroundColor(.white)
                    }
                    
                    // Error message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                    
                    // Button
                    Button(action: {
                        if isLoginMode {
                            loginUser(username: username, password: password)
                        } else {
                            createUser(username: username, email: email, password: password)
                        }
                    }) {
                        Text(isLoginMode ? "Log In" : "Sign Up")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                                    .cornerRadius(12)
                            )
                    }
                    .padding(.top, 10)
                    
                    // Switch between modes
                    Button(action: { isLoginMode.toggle() }) {
                        Text(isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Log In")
                            .foregroundColor(.gray)
                            .font(.footnote)
                            .padding(.top, 10)
                    }
                    
                }
                .padding(.horizontal, 30)
            }
        }
    }
    
    // MARK: - Firebase Functions
    
    func createUser(username: String, email: String, password: String) {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill out all fields"
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = "Sign up failed: \(error.localizedDescription)"
                return
            }
            
            let db = Firestore.firestore()
            db.collection("users").document(username.lowercased()).setData([
                "email": email
            ]) { err in
                if let err = err {
                    self.errorMessage = "Firestore error: \(err.localizedDescription)"
                } else {
                    self.isSignedIn = true
                }
            }
        }
    }
    
    func loginUser(username: String, password: String) {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter username and password"
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(username.lowercased()).getDocument { document, error in
            if let document = document, document.exists {
                if let email = document.data()?["email"] as? String {
                    Auth.auth().signIn(withEmail: email, password: password) { result, error in
                        if let error = error {
                            self.errorMessage = "Login failed: \(error.localizedDescription)"
                        } else {
                            self.isSignedIn = true
                        }
                    }
                } else {
                    self.errorMessage = "Email not found for this username"
                }
            } else {
                self.errorMessage = "Username not found"
            }
        }
    }
}

// MARK: - Landing Page
struct LandingPageView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Text("🎉 Welcome to 1-5!")
                    .foregroundColor(.white)
                    .font(.title)
                    .padding()
                Text("This is your landing page after login.")
                    .foregroundColor(.gray)
            }
        }
    }
}
