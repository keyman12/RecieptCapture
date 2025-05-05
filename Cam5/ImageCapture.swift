import SwiftUI
import UIKit

class ImageCapture: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var showingImagePicker = false
    @Published var logs: [CaptureLog] = []
    @Published var isUploading = false
    @Published var uploadStatus: String?
    
    func saveImage(_ image: UIImage) {
        capturedImage = image
        
        // Save to documents directory
        if let data = image.jpegData(compressionQuality: 0.8) {
            let timestamp = Date()
            let filename = "\(timestamp.ISO8601Format()).jpg"
            let localURL = getDocumentsDirectory().appendingPathComponent(filename)
            
            do {
                try data.write(to: localURL)
                
                // Add to logs
                let log = CaptureLog(timestamp: timestamp, filename: filename)
                logs.append(log)
                
                // Save logs
                saveLogs()
                
                // Upload to Dropbox
                uploadToDropbox(data: data, filename: filename)
            } catch {
                print("Error saving image: \(error)")
            }
        }
    }
    
    private func uploadToDropbox(data: Data, filename: String) {
        isUploading = true
        uploadStatus = "Uploading..."
        
        DropboxManager.shared.uploadFile(data: data, filename: filename) { [weak self] result in
            DispatchQueue.main.async {
                self?.isUploading = false
                
                switch result {
                case .success(let path):
                    self?.uploadStatus = "Uploaded successfully to \(path)"
                case .failure(let error):
                    self?.uploadStatus = "Upload failed: \(error.localizedDescription)"
                }
                
                // Clear status after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self?.uploadStatus = nil
                }
            }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func saveLogs() {
        if let data = try? JSONEncoder().encode(logs) {
            let filename = getDocumentsDirectory().appendingPathComponent("capture_logs.json")
            try? data.write(to: filename)
        }
    }
    
    func loadLogs() {
        let filename = getDocumentsDirectory().appendingPathComponent("capture_logs.json")
        if let data = try? Data(contentsOf: filename) {
            if let decodedLogs = try? JSONDecoder().decode([CaptureLog].self, from: data) {
                logs = decodedLogs
            }
        }
    }
}

struct CaptureLog: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let filename: String
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
} 