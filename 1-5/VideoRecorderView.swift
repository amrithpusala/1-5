import SwiftUI
import AVKit
import FirebaseStorage
import FirebaseFirestore
import PhotosUI
import MobileCoreServices

struct VideoRecorderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionState
    
    // Selected dare tier passed in (e.g., "1-50"); included as hashtag
    let selectedDareTier: String?
    
    @State private var showSourceSheet = true
    @State private var showCamera = false
    @State private var showLibrary = false
    
    @State private var pickedURL: URL?
    @State private var caption = ""
    @State private var hashtagsText = ""
    @State private var isUploading = false
    @State private var uploadError: String?
    
    private var combinedHashtags: [String] {
        var tags = hashtagsText
            .split(separator: " ")
            .map { String($0) }
            .filter { !$0.isEmpty }
        
        if let tier = selectedDareTier {
            let asHash = "#" + tier.replacingOccurrences(of: " ", with: "")
            if !tags.contains(asHash) { tags.append(asHash) }
        }
        return tags
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.blue.opacity(0.15), .purple.opacity(0.3)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    if let url = pickedURL {
                        VideoPlayer(player: AVPlayer(url: url))
                            .frame(height: 360)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("Caption", text: $caption)
                                .textFieldStyle(.roundedBorder)
                            TextField("#hashtags (space separated)", text: $hashtagsText)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding(.horizontal)
                        
                        HStack(spacing: 14) {
                            Button(role: .destructive) {
                                pickedURL = nil
                            } label: {
                                Label("Re-record", systemImage: "arrow.counterclockwise.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            
                            Button {
                                upload()
                            } label: {
                                if isUploading {
                                    ProgressView().frame(maxWidth: .infinity)
                                } else {
                                    Label("Submit", systemImage: "paperplane.fill")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                        }
                        .padding(.horizontal)
                    } else {
                        Spacer()
                        Text("Record or upload a 30-second video")
                            .foregroundColor(.white.opacity(0.85))
                            .font(.headline)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Record Dare")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .confirmationDialog("Choose a source", isPresented: $showSourceSheet) {
                Button("Record with Camera") {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showCamera = true
                    } else {
                        uploadError = "Camera not available on this device."
                    }
                }
                Button("Upload from Library") { showLibrary = true }
                Button("Cancel", role: .cancel) { dismiss() }
            }
            .sheet(isPresented: $showCamera) {
                LegacyVideoPicker(source: .camera, pickedURL: $pickedURL)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showLibrary) {
                LegacyVideoPicker(source: .photoLibrary, pickedURL: $pickedURL)
                    .ignoresSafeArea()
            }
            .alert("Error", isPresented: .constant(uploadError != nil)) {
                Button("OK") { uploadError = nil }
            } message: {
                Text(uploadError ?? "")
            }
        }
    }
    
    private func upload() {
        guard !isUploading, let file = pickedURL else { return }
        
        // Allow test uploads: ensure a non-empty userId
        var uid = session.userId
        if uid.isEmpty {
            session.becomeTestUserIfNeeded()
            uid = session.userId
        }
        guard !uid.isEmpty else {
            uploadError = "Could not determine user. Please try again."
            return
        }
        
        isUploading = true
        
        let uname = session.username.isEmpty ? "Test User" : session.username
        
        VideoService.shared.uploadVideo(
            fileURL: file,
            caption: caption,
            hashtags: combinedHashtags,
            dareTag: selectedDareTier,
            userId: uid,
            username: uname
        ) { result in
            DispatchQueue.main.async {
                self.isUploading = false
                switch result {
                case .success:
                    dismiss()
                case .failure(let err):
                    self.uploadError = err.localizedDescription
                }
            }
        }
    }
}

/// UIKit-backed picker (camera or library) with 30s limit for camera recording
struct LegacyVideoPicker: UIViewControllerRepresentable {
    enum Source { case camera, photoLibrary }
    let source: Source
    @Binding var pickedURL: URL?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.mediaTypes = ["public.movie"]
        picker.delegate = context.coordinator
        switch source {
        case .camera:
            picker.sourceType = .camera
            picker.videoMaximumDuration = 30
            picker.cameraCaptureMode = .video
        case .photoLibrary:
            picker.sourceType = .photoLibrary
        }
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: LegacyVideoPicker
        init(_ parent: LegacyVideoPicker) { self.parent = parent }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            guard let url = info[.mediaURL] as? URL else { return }
            
            // Immediately copy to a stable temp URL so it won't disappear
            let ext = url.pathExtension.isEmpty ? "mov" : url.pathExtension.lowercased()
            let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let tempURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)
            do {
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                try FileManager.default.copyItem(at: url, to: tempURL)
                parent.pickedURL = tempURL
            } catch {
                // Fallback to original if copy fails (should be rare)
                parent.pickedURL = url
            }
        }
    }
}
