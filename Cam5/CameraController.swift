import SwiftUI
import UIKit
import AVFoundation

struct CameraController: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    var sourceType: UIImagePickerController.SourceType
    var onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraController>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        // Check camera authorization first
        if sourceType == .camera {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                setupCamera(picker)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        DispatchQueue.main.async {
                            setupCamera(picker)
                        }
                    } else {
                        fallbackToPhotoLibrary(picker)
                    }
                }
            default:
                fallbackToPhotoLibrary(picker)
            }
        } else {
            fallbackToPhotoLibrary(picker)
        }
        
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.modalPresentationStyle = .fullScreen
        
        return picker
    }
    
    private func setupCamera(_ picker: UIImagePickerController) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
            picker.cameraFlashMode = .auto
        } else {
            fallbackToPhotoLibrary(picker)
        }
    }
    
    private func fallbackToPhotoLibrary(_ picker: UIImagePickerController) {
        picker.sourceType = .photoLibrary
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<CameraController>) {
        // No update needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraController
        
        init(_ parent: CameraController) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Try to get edited image first, fall back to original if not available
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
} 