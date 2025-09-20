import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var session: SessionState
    @State private var bio: String = "Tap to add a bio"
    @State private var isEditingBio = false

    // Profile picture state
    @State private var profileImage: UIImage? = nil
    @State private var showImagePicker = false

    var username: String {
        session.isLoggedIn
        ? "@" + (session.username.isEmpty ? "user" : session.username)
        : "@TestUser"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // MARK: Profile Image
                Button(action: {
                    showImagePicker = true
                }) {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.purple, lineWidth: 3))
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                            .overlay(Circle().stroke(Color.purple, lineWidth: 3))
                    }
                }
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(image: $profileImage)
                }

                // MARK: Username + Bio
                VStack(spacing: 8) {
                    Text(username)
                        .font(.title2).bold()
                        .foregroundColor(.white)

                    if isEditingBio {
                        TextField("Enter bio", text: $bio, onCommit: {
                            isEditingBio = false
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    } else {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .onTapGesture {
                                isEditingBio = true
                            }
                    }
                }

                // MARK: Followers / Following
                HStack(spacing: 40) {
                    VStack {
                        Text("1753") // placeholder
                            .font(.headline).bold()
                            .foregroundColor(.white)
                        Text("Following")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    VStack {
                        Text("68") // placeholder
                            .font(.headline).bold()
                            .foregroundColor(.white)
                        Text("Followers")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                // MARK: Edit Profile Button
                Button(action: {
                    isEditingBio.toggle()
                }) {
                    Text("Edit Profile")
                        .font(.subheadline).bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)

                Divider().background(Color.gray)

                // MARK: Video Grid
                if session.userVideos.isEmpty {
                    Spacer()
                    Text("No videos yet")
                        .foregroundColor(.gray)
                        .font(.headline)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                            ForEach(session.userVideos, id: \.id) { video in
                                Rectangle()
                                    .fill(Color.gray.opacity(0.5))
                                    .aspectRatio(9/16, contentMode: .fit)
                                    .overlay(
                                        Text(video.title)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(4),
                                        alignment: .bottomLeading
                                    )
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }
            .padding(.top, 30) // lower everything slightly
            .background(Color.black.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
}

// MARK: - UIKit Image Picker Wrapper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> some UIViewController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }
    }
}
